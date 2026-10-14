extends Node3D
## One static target, geometric contact events only. No damage or combat resolution.

signal contact_detected(event: Dictionary)
signal valid_attack_contact_detected(event: Dictionary)

@export var trajectory_path: NodePath = NodePath("../WeaponTrajectoryDebug")
@export var target_region_path: NodePath = NodePath("../Enemy/DebugContactRegion")
@export var subscribe_to_trajectory: bool = true
@export_flags_3d_physics var contact_mask: int = 2
@export var motion_names := PackedStringArray(["Thrust", "Short Cut", "Broad Cut"])
@export_range(0.002, 0.05, 0.001) var blade_radius: float = 0.012
@export_range(0.002, 0.05, 0.001) var max_sweep_step: float = 0.01
@export_range(32, 1024, 1) var max_substeps: int = 512

var events: Array[Dictionary] = []
var valid_events: Array[Dictionary] = []
var current_request_valid_contacted: bool = false
var current_request_id: int = 0
var current_request_contacted: bool = false
var previous_sample: Dictionary = {}
var oversized_segments: int = 0
var blade_shape := CapsuleShape3D.new()
@onready var region: Area3D = get_node(target_region_path) as Area3D
@onready var target: Node3D = region.get_parent() as Node3D

func _ready() -> void:
	if subscribe_to_trajectory:
		get_node(trajectory_path).sample_recorded.connect(_on_sample)

func _on_sample(request_id: int, motion: int, sample: Dictionary) -> void:
	if request_id != current_request_id:
		current_request_id = request_id
		current_request_contacted = false
		current_request_valid_contacted = false
		previous_sample = {}
	var from := sample if previous_sample.is_empty() else previous_sample
	previous_sample = sample
	if not current_request_contacted:
		var contact := sweep_blade(from, sample)
		if not contact.is_empty():
			current_request_contacted = true
			var event := _event(request_id, motion, sample, contact, "physical")
			events.append(event)
			if events.size() > 32:
				events.pop_front()
			contact_detected.emit(event)
			print("WEAPON_CONTACT ", event)
	if not current_request_valid_contacted:
		var contact := sweep_active_interval(from, sample)
		if not contact.is_empty():
			current_request_valid_contacted = true
			var event := _event(request_id, motion, sample, contact, "valid_attack")
			event["playback_time"] = contact["playback_time"]
			valid_events.append(event)
			if valid_events.size() > 32:
				valid_events.pop_front()
			valid_attack_contact_detected.emit(event)
			print("VALID_ATTACK_CONTACT ", event)

func _event(request_id: int, motion: int, sample: Dictionary, contact: Dictionary, kind: String) -> Dictionary:
	var event := {"request_id": request_id, "motion": motion,
		"motion_name": motion_names[motion],
		"target": target, "target_path": str(target.get_path()),
		"position": contact["point"], "physics_frame": sample["frame"], "normal": contact["normal"], "contact_kind": kind}
	return event

func sweep_active_interval(from: Dictionary, to: Dictionary) -> Dictionary:
	if not to.has("playback_time"):
		return {}
	var a: float = from["playback_time"]
	var b: float = to["playback_time"]
	var start: float = to["window_start"]
	var end: float = to["window_end"]
	if end <= start or b < a:
		return {}
	if is_equal_approx(a, b):
		if not to.get("window_active", false):
			return {}
		var instant := sweep_blade(to, to)
		if not instant.is_empty():
			instant["playback_time"] = b
		return instant
	# An end sample may close a window now, but its preceding live interval still counts.
	if not from.get("window_live", false):
		return {}
	var lo := maxf(a, start)
	var hi := minf(b, end)
	if hi <= lo:
		return {}
	# End is exclusive; never include the first pose of the return phase.
	hi = maxf(lo, hi - 0.000001)
	var contact := sweep_blade(_interpolate_pose(from, to, (lo - a) / (b - a)),
		_interpolate_pose(from, to, (hi - a) / (b - a)))
	if not contact.is_empty():
		contact["playback_time"] = lerpf(lo, hi, contact["sweep_fraction"])
	return contact

func _interpolate_pose(from: Dictionary, to: Dictionary, fraction: float) -> Dictionary:
	var a_base: Vector3 = from["base"]
	var b_base: Vector3 = to["base"]
	var a_tip: Vector3 = from["tip"]
	var b_tip: Vector3 = to["tip"]
	var a_rotation: Quaternion = from.get("weapon_rotation", Quaternion(Vector3.UP, (a_tip - a_base).normalized()))
	var b_rotation: Quaternion = to.get("weapon_rotation", Quaternion(Vector3.UP, (b_tip - b_base).normalized()))
	var rotation := a_rotation.slerp(b_rotation, fraction)
	var base := a_base.lerp(b_base, fraction)
	var length := lerpf(a_base.distance_to(a_tip), b_base.distance_to(b_tip), fraction)
	return {"base": base, "tip": base + Basis(rotation).y * length, "weapon_rotation": rotation}

func sweep_blade(from: Dictionary, to: Dictionary) -> Dictionary:
	var a_base: Vector3 = from["base"]
	var a_tip: Vector3 = from["tip"]
	var b_base: Vector3 = to["base"]
	var b_tip: Vector3 = to["tip"]
	var a_length := a_base.distance_to(a_tip)
	var b_length := b_base.distance_to(b_tip)
	if minf(a_length, b_length) < 0.0001:
		return {}
	var a_rotation: Quaternion = from.get("weapon_rotation", Quaternion(Vector3.UP, (a_tip - a_base).normalized()))
	var b_rotation: Quaternion = to.get("weapon_rotation", Quaternion(Vector3.UP, (b_tip - b_base).normalized()))
	var travel := maxf(a_base.distance_to(b_base), a_tip.distance_to(b_tip))
	travel = maxf(travel, a_base.distance_to(b_base) + a_rotation.angle_to(b_rotation) * maxf(a_length, b_length))
	var needed := maxi(1, ceili(travel / max_sweep_step))
	if needed > max_substeps:
		oversized_segments += 1
		push_warning("Weapon sweep subdivision cap reached; diagnostic precision reduced for this segment")
	var steps := mini(needed, max_substeps)
	var previous := _blade_transform(a_base, a_rotation, a_length)
	var query := PhysicsShapeQueryParameters3D.new()
	blade_shape.radius = blade_radius
	blade_shape.height = maxf(a_length, 2.0 * blade_radius)
	query.shape = blade_shape
	query.collision_mask = contact_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.margin = 0.0005
	query.transform = previous
	var space := get_world_3d().direct_space_state
	var contact := _target_rest_info(space, query)
	if not contact.is_empty():
		contact["sweep_fraction"] = 0.0
		return contact
	for i in range(1, steps + 1):
		var fraction := float(i) / steps
		var length := lerpf(a_length, b_length, fraction)
		var next := _blade_transform(a_base.lerp(b_base, fraction), a_rotation.slerp(b_rotation, fraction), length)
		blade_shape.height = maxf(length, 2.0 * blade_radius)
		query.transform = previous
		query.motion = next.origin - previous.origin
		if query.motion.length_squared() > 0.00000001:
			var bounds := space.cast_motion(query)
			if bounds.size() == 2 and bounds[0] < 1.0:
				# Step slightly into the computed impact to obtain a real target surface point.
				query.transform.origin += query.motion * minf(1.0, bounds[1] + 0.002 / query.motion.length())
				contact = _target_rest_info(space, query)
				if not contact.is_empty():
					contact["sweep_fraction"] = (float(i - 1) + bounds[1]) / steps
					return contact
		query.transform = next
		query.motion = Vector3.ZERO
		contact = _target_rest_info(space, query)
		if not contact.is_empty():
			contact["sweep_fraction"] = fraction
			return contact
		previous = next
	return {}

func _blade_transform(base: Vector3, rotation: Quaternion, length: float) -> Transform3D:
	var basis := Basis(rotation)
	return Transform3D(basis, base + basis.y * length * 0.5)

func _target_rest_info(space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D) -> Dictionary:
	var info := space.get_rest_info(query)
	return info if not info.is_empty() and info["collider_id"] == region.get_instance_id() else {}
