extends Node3D
## Development lines and bounded world-space samples only. Never performs collision queries.

signal sample_recorded(request_id: int, motion: int, sample: Dictionary)

@export var motion_demo_path: NodePath = NodePath("../Player/WeaponMotionDemo")
@export var weapon_path: NodePath = NodePath("../Player/VisualRoot/RightHand/Gunblade")
@export var debug_display_enabled: bool = false:
	set(value):
		debug_display_enabled = value
		if is_instance_valid(lines):
			lines.visible = value
			legend.visible = value
			if value:
				_redraw()
@export_range(1, 16, 1) var retained_requests: int = 8
@export_range(32, 512, 1) var max_samples_per_request: int = 256
@export_range(1, 12, 1) var blade_snapshot_stride: int = 4
@export_range(0.05, 2.0, 0.05) var jump_warning_distance: float = 0.5
@export_range(0.1, 3.0, 0.1) var contact_marker_seconds: float = 1.2

var records: Array[Dictionary] = []
var active_record: Dictionary = {}
var line_mesh: ImmediateMesh
var lines: MeshInstance3D
var legend: Label
var contact_markers: Array[Dictionary] = []
@onready var demo: Node3D = get_node(motion_demo_path) as Node3D
@onready var weapon: Node3D = get_node(weapon_path) as Node3D
@onready var grip: Marker3D = weapon.get_node("Grip") as Marker3D
@onready var blade_base: Marker3D = weapon.get_node("BladeBase") as Marker3D
@onready var blade_tip: Marker3D = weapon.get_node("BladeTip") as Marker3D
@onready var enemy_health: Node = get_node("../Enemy/DebugHealth")
@onready var player_health: Node = get_node("../Player/DebugPlayerHealth")
@onready var clash: Node = get_node("../BladeClashDebug")

func _ready() -> void:
	line_mesh = ImmediateMesh.new()
	lines = MeshInstance3D.new()
	lines.name = "WorldSpaceDebugLines"
	lines.mesh = line_mesh
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	lines.material_override = material
	add_child(lines)
	lines.top_level = true
	lines.global_transform = Transform3D.IDENTITY
	var overlay := CanvasLayer.new()
	add_child(overlay)
	legend = Label.new()
	legend.position = Vector2(12, 12)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(legend)
	lines.visible = debug_display_enabled
	legend.visible = debug_display_enabled
	demo.motion_started.connect(_start_record)
	demo.motion_ended.connect(_end_record)
	get_node("../WeaponContactDebug").contact_detected.connect(_on_contact)
	get_node("../WeaponContactDebug").valid_attack_contact_detected.connect(_on_valid_contact)
	clash.clash_detected.connect(_on_clash)
	clash.body_contact_detected.connect(_on_enemy_body)

func _on_clash(event: Dictionary) -> void:
	_contact_marker(event, "blade_clash")

func _on_enemy_body(event: Dictionary) -> void:
	_contact_marker(event, "enemy_body")

func _contact_marker(event: Dictionary, key: String) -> void:
	contact_markers.append({"position": event["position"], "kind": key,
		"expires": Engine.get_physics_frames() + ceili(contact_marker_seconds * Engine.physics_ticks_per_second)})
	if contact_markers.size() > 32:
		contact_markers.pop_front()

func _on_contact(event: Dictionary) -> void:
	_store_contact(event, "contact")

func _on_valid_contact(event: Dictionary) -> void:
	_store_contact(event, "valid_contact")

func _store_contact(event: Dictionary, key: String) -> void:
	for record in records:
		if record["id"] == event["request_id"]:
			record[key] = event
	_contact_marker(event, key)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_weapon_trajectory_debug"):
		debug_display_enabled = not debug_display_enabled
	# Deferred execution reads transforms after this tick's player motion and physics Tween.
	call_deferred("_sample_after_physics")

func sample_world_pose() -> Dictionary:
	return {"frame": Engine.get_physics_frames(), "grip": grip.global_position,
		"base": blade_base.global_position, "tip": blade_tip.global_position,
		"weapon_rotation": weapon.global_basis.get_rotation_quaternion(),
		"direction": (blade_tip.global_position - blade_base.global_position).normalized()}

func _start_record(request_id: int, motion: int) -> void:
	active_record = {"id": request_id, "motion": motion,
		"motion_name": ["Thrust", "Short Cut", "Broad Cut"][motion],
		"start_frame": Engine.get_physics_frames(), "status": "active", "samples": [],
		"max_step": 0.0, "jump_samples": [], "truncated": false}
	records.append(active_record)
	while records.size() > retained_requests:
		records.pop_front()
	_append_sample("start")

func _end_record(request_id: int, reason: String) -> void:
	if active_record.is_empty() or active_record["id"] != request_id:
		return
	_append_sample("end")
	active_record["status"] = reason
	active_record["end_frame"] = Engine.get_physics_frames()
	active_record = {}

func _sample_after_physics() -> void:
	while not contact_markers.is_empty() and contact_markers.front()["expires"] <= Engine.get_physics_frames():
		contact_markers.pop_front()
	if not active_record.is_empty():
		_append_sample("frame")
	if debug_display_enabled:
		_redraw()

func _append_sample(kind: String) -> void:
	var sample := sample_world_pose()
	sample.merge(demo.playback_state())
	sample["kind"] = kind
	var samples: Array = active_record["samples"]
	if not samples.is_empty():
		var step: float = sample["tip"].distance_to(samples.back()["tip"])
		active_record["max_step"] = maxf(active_record["max_step"], step)
		if step > jump_warning_distance:
			active_record["jump_samples"].append({"frame": sample["frame"], "distance": step})
	samples.append(sample)
	sample_recorded.emit(active_record["id"], active_record["motion"], sample)
	if samples.size() > max_samples_per_request:
		samples.remove_at(1) # Keep the explicit start and the newest samples/end.
		active_record["truncated"] = true

func _redraw() -> void:
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var colors := [Color(0.1, 0.9, 1), Color(1, 0.65, 0.15), Color(0.85, 0.4, 1)]
	for record in records:
		var color: Color = colors[record["motion"]]
		var samples: Array = record["samples"]
		for i in range(1, samples.size()):
			_segment(samples[i - 1]["tip"], samples[i]["tip"], color)
		for i in range(0, samples.size(), blade_snapshot_stride):
			_segment(samples[i]["base"], samples[i]["tip"], color.darkened(0.45))
		if not samples.is_empty():
			_cross(samples.front()["tip"], 0.035, Color.GREEN)
			if record["status"] != "active":
				_cross(samples.back()["tip"], 0.035, Color.RED)
	var current := sample_world_pose()
	var playback: Dictionary = demo.playback_state()
	_segment(current["base"], current["tip"], Color.LIME if playback["window_active"] else Color.WHITE)
	_segment(current["tip"], current["tip"] + current["direction"] * 0.15, Color.YELLOW)
	_cross(current["grip"], 0.045, Color.YELLOW)
	_cross(current["base"], 0.03, Color.WHITE)
	_cross(current["tip"], 0.03, Color.WHITE)
	for marker in contact_markers:
		var valid: bool = marker["kind"] == "valid_contact"
		var color := Color.LIME if valid else Color(1, 0.15, 0.4)
		if marker["kind"] == "blade_clash": color = Color.DEEP_SKY_BLUE
		if marker["kind"] == "enemy_body": color = Color.ORANGE_RED
		_cross(marker["position"], 0.14 if valid else 0.10, color)
	var enemy_pose: Dictionary = clash.pose(clash.enemy_weapon)
	_segment(enemy_pose["base"], enemy_pose["tip"], Color.AQUAMARINE)
	var matching: Node = demo.get_parent().get_node("ContactMatchingDebug")
	if matching.active:
		_cross(matching.target_position, 0.07, Color.YELLOW)
	line_mesh.surface_end()
	legend.text = "WEAPON TRAJECTORY DEBUG / F4\nCyan: Thrust | Orange: Short Cut | Violet: Broad Cut\nGreen: request start | Red: end | Yellow: grip / actual blade direction"
	if not records.is_empty():
		var latest: Dictionary = records.back()
		legend.text += "\n#%d %s / %s | samples %d | max step %.3f m | jump warnings %d" % [
			latest["id"], latest["motion_name"], latest["status"], latest["samples"].size(),
			latest["max_step"], latest["jump_samples"].size()]
		legend.text += "\nPhysical Contact: " + ("DETECTED (pink)" if latest.has("contact") else "not detected")
		legend.text += " | Valid Attack Contact: " + ("DETECTED (lime)" if latest.has("valid_contact") else "not detected")
		legend.text += "\nPlayback %.3f s | window [%.3f, %.3f) s: %s" % [playback["playback_time"],
			playback["window_start"], playback["window_end"], "ACTIVE (lime blade)" if playback["window_active"] else "CLOSED"]
	legend.text += "\nWindows (seconds): Thrust %s | Short Cut %s | Broad Cut %s" % [
		demo.thrust_active_window, demo.short_cut_active_window, demo.broad_cut_active_window]
	legend.text += "\nDEBUG ONLY Enemy HP: %.1f / %.1f | Last damage: %.1f | Dead: %s\nF7: Debug Only BOTH HP / motion reset (new requests required)" % [
		enemy_health.hp, enemy_health.max_hp, enemy_health.last_damage, str(enemy_health.dead)]
	legend.text += "\nDEBUG ONLY Player HP: %.1f / %.1f | Last injury: %.1f | Dead: %s" % [
		player_health.hp, player_health.max_hp, player_health.last_damage, str(player_health.dead)]
	var defense: Node = demo.get_parent().get_node("DebugDefense")
	legend.text += "\nDefense: %s | Parry remaining: %.3f s | Last defense: %s\nPrevented: %.1f HP | Last injury: %.1f HP (zero on successful defense)" % [
		defense.state_name(), defense.perfect_remaining, defense.last_result, defense.last_prevented_damage, player_health.last_damage]
	legend.text += "\nBlue: blade clash | Orange-red: enemy blade/body | Aquamarine: actual enemy blade"
	if not clash.latest.is_empty():
		legend.text += "\nEnemy #%d | Blade clash: %s | Body physical: %s / valid: %s\nDamage prevented: %s | Defense at body: %s" % [
			clash.latest["request_id"], str(clash.latest["blade_contact"]), str(clash.latest["body_contact"]),
			str(clash.latest["valid_body_contact"]), clash.latest["damage_prevented"], clash.latest["defense_on_body_contact"]]
	legend.text += "\nContact Matching: %s / %s | correction %.3f m / %.1f deg\nTarget: %s | %s" % [
		str(matching.active), matching.result, matching.position_correction, matching.rotation_correction_degrees,
		str(matching.target_position), matching.reason]
	var enemy_attack: Node = clash.attack
	legend.text += "\nEnemy burst: %s | sword %d / %d | %s | recovery/gap %.2f s" % [
		str(enemy_attack.sequence_active), enemy_attack.sequence_index, enemy_attack.sequence_length,
		["Thrust", "Left Cut", "Right Cut"][enemy_attack.motion], enemy_attack.cooldown]

func _segment(a: Vector3, b: Vector3, color: Color) -> void:
	line_mesh.surface_set_color(color)
	line_mesh.surface_add_vertex(a)
	line_mesh.surface_add_vertex(b)

func _cross(point: Vector3, radius: float, color: Color) -> void:
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		_segment(point - axis * radius, point + axis * radius, color)
