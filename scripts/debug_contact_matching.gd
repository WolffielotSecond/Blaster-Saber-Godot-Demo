extends Node
## Bounded greybox hand correction only. Never emits clashes or changes damage.
@export var enabled: bool = true
@export_range(0, 0.5, 0.01) var max_position_correction: float = 0.30
@export_range(0, 60, 1) var max_rotation_degrees: float = 35.0
@export_range(0.1, 10, 0.1) var hand_speed: float = 3.0
@export_range(1, 720, 1) var rotation_speed_degrees: float = 360.0
@export_range(0.01, 0.2, 0.01) var contact_hold_seconds: float = 0.08
@export_range(0.05, 0.5, 0.01) var recovery_seconds: float = 0.12
var active: bool = false
var result: String = "Failed"
var reason: String = "No matching request"
var target_position := Vector3.ZERO
var position_correction: float = 0
var rotation_correction_degrees: float = 0
var observed_direction := Vector3.ZERO
var request_id: int = 0
var baseline: Transform3D
var previous_enemy_tip := Vector3.ZERO
var hold_remaining: float = 0
var completed_request: int = 0
var last_update_frame: int = -1
var base_offset := Vector3.ZERO
var tip_offset := Vector3.ZERO
@onready var player: Node3D = get_parent()
@onready var defense: Node = get_node("../DebugDefense")
@onready var hand: Node3D = get_node("../VisualRoot/RightHand")
@onready var weapon: Node3D = hand.get_node("Gunblade")
@onready var attack: Node3D = get_node("../../Enemy/DebugAttack")
@onready var enemy_weapon: Node3D = get_node("../../Enemy/VisualRoot/RightHand/Gunblade")

func _ready() -> void:
	base_offset = hand.global_transform.affine_inverse() * weapon.get_node("BladeBase").global_position
	tip_offset = hand.global_transform.affine_inverse() * weapon.get_node("BladeTip").global_position
	get_node("../../BladeClashDebug").clash_detected.connect(_on_clash)

func _physics_process(_delta: float) -> void:
	call_deferred("_finish_if_inactive")

func _finish_if_inactive() -> void:
	if active and (attack.active_request_id == 0 or not defense.matching_defense_active() or player.get_node("DebugPlayerHealth").dead):
		_finish()

func _finish() -> void:
	active = false
	if defense.held and not player.get_node("DebugPlayerHealth").dead:
		defense.claim_hand("Guard")
		defense.visual_tween = defense.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		defense.visual_tween.tween_property(hand, "transform", defense.demo._pose(defense.guard_position, defense.guard_rotation_degrees), recovery_seconds).set_trans(Tween.TRANS_SINE)

func _on_clash(event: Dictionary) -> void:
	if active and event.get("attack_side", "Enemy") == "Enemy" and event["request_id"] == request_id:
		hold_remaining = contact_hold_seconds
		completed_request = request_id

func update_matching(id: int, delta: float) -> void:
	var frame := Engine.get_physics_frames()
	defense.refresh_input()
	if not defense.held and defense.instinctive_request_id != id:
		if active: _finish()
		return # Automatic matching belongs only to its confirmed incoming request.
	if not enabled or not defense.matching_defense_active() or player.get_node("DebugPlayerHealth").dead:
		if active: _finish()
		return
	var offset: Vector3 = attack.get_parent().global_position - player.global_position
	offset.y = 0
	if offset.length_squared() < 0.000001 or (-player.global_basis.z).normalized().dot(offset.normalized()) < cos(deg_to_rad(defense.defense_half_angle_degrees)):
		if active: _finish()
		result = "Failed"
		reason = "Outside front defense cone"
		return
	var window: Vector2 = attack.get_active_window()
	var instinctive_intercept: bool = defense.instinctive_phase == "Intercept" and defense.instinctive_request_id == id
	if not instinctive_intercept and (attack.previous_time < window.x or attack.previous_time >= window.y):
		if active: _finish()
		return
	if last_update_frame == frame: return
	last_update_frame = frame
	if completed_request == id:
		hold_remaining = maxf(0, hold_remaining - delta)
		if hold_remaining == 0 and active: _finish()
		return
	if not active or request_id != id:
		request_id = id
		baseline = hand.transform
		defense.claim_hand("Matching")
		active = true
		previous_enemy_tip = enemy_weapon.get_node("BladeTip").global_position
	var enemy_base: Vector3 = enemy_weapon.get_node("BladeBase").global_position
	var enemy_tip: Vector3 = enemy_weapon.get_node("BladeTip").global_position
	observed_direction = (enemy_tip - previous_enemy_tip).normalized()
	previous_enemy_tip = enemy_tip
	var solution := solve_pose(enemy_base, enemy_tip)
	if solution.is_empty():
		result = "Failed"
		reason = "No front-body-safe pose within correction limits"
		return
	target_position = solution["target"]
	var desired: Transform3D = solution["pose"]
	var q := hand.basis.get_rotation_quaternion()
	var desired_q := desired.basis.get_rotation_quaternion()
	var angle := q.angle_to(desired_q)
	var weight := minf(1, deg_to_rad(rotation_speed_degrees) * delta / maxf(angle, 0.000001))
	var next := Transform3D(Basis(q.slerp(desired_q, weight)), hand.position.move_toward(desired.origin, hand_speed * delta))
	if not _safe(next):
		result = "Failed"
		reason = "Intermediate pose violates front-body clearance"
		return
	hand.transform = next
	position_correction = hand.position.distance_to(baseline.origin)
	rotation_correction_degrees = rad_to_deg(baseline.basis.get_rotation_quaternion().angle_to(hand.basis.get_rotation_quaternion()))
	var contact_local: Vector3 = solution["blade_point"]
	var actual := hand.global_transform * contact_local
	result = "Matched" if actual.distance_to(target_position) <= 0.01 else "Limited"
	reason = "Pose converged; clash detection remains independent" if result == "Matched" else "Speed-limited approach"

func solve_pose(enemy_base: Vector3, enemy_tip: Vector3) -> Dictionary:
	return solve_contact_pose(hand, weapon, baseline, base_offset, tip_offset, observed_direction,
		max_position_correction, max_rotation_degrees, enemy_base, enemy_tip)

static func solve_contact_pose(hand: Node3D, weapon: Node3D, baseline: Transform3D,
	base_offset: Vector3, tip_offset: Vector3, observed_direction: Vector3,
	max_position_correction: float, max_rotation_degrees: float,
	enemy_base: Vector3, enemy_tip: Vector3) -> Dictionary:
	var base_local: Vector3 = hand.global_transform.affine_inverse() * weapon.get_node("BladeBase").global_position
	var tip_local: Vector3 = hand.global_transform.affine_inverse() * weapon.get_node("BladeTip").global_position
	var best: Dictionary = {}
	var score := INF
	for e in range(1, 10):
		var target := enemy_base.lerp(enemy_tip, float(e) / 10)
		var local_target: Vector3 = hand.get_parent().to_local(target)
		if local_target.z > -0.28 or local_target.y < 0.8 or local_target.y > 1.75:
			continue
		for p in range(2, 9):
			var blade_point := base_local.lerp(tip_local, float(p) / 10)
			for turn in [false, true]:
				var basis := baseline.basis
				if turn:
					var direction := (local_target - baseline.origin).normalized()
					var rotation := Quaternion(basis.y.normalized(), direction)
					var amount := minf(1, deg_to_rad(max_rotation_degrees) / maxf(rotation.get_angle(), 0.000001))
					basis = Basis(Quaternion.IDENTITY.slerp(rotation, amount)) * basis
				var pose := Transform3D(basis, local_target - basis * blade_point)
				var distance := pose.origin.distance_to(baseline.origin)
				if distance > max_position_correction or not safe_contact_pose(pose, base_offset, tip_offset): continue
				var motion_local: Vector3 = hand.get_parent().global_basis.inverse() * observed_direction
				var cost := distance + baseline.basis.get_rotation_quaternion().angle_to(basis.get_rotation_quaternion()) * 0.05 + absf(basis.y.dot(motion_local)) * 0.02
				if cost < score:
					score = cost
					best = {"pose": pose, "target": target, "blade_point": blade_point}
	return best

func _safe(pose: Transform3D) -> bool:
	return safe_contact_pose(pose, base_offset, tip_offset)

static func safe_contact_pose(pose: Transform3D, base_offset: Vector3, tip_offset: Vector3) -> bool:
	# Entire blade and grip must stay forward of the existing cylindrical body.
	return pose.origin.z <= -0.28 and pose.origin.y >= 0.8 and pose.origin.y <= 1.75 and (pose * base_offset).z <= -0.28 and (pose * tip_offset).z <= -0.28

func debug_reset() -> void:
	last_update_frame = -1
	active = false
	request_id = 0
	completed_request = 0
	hold_remaining = 0
	target_position = Vector3.ZERO
	position_correction = 0
	rotation_correction_degrees = 0
	result = "Failed"
	reason = "No matching request"
