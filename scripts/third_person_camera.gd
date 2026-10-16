extends Node3D

@export var target_path: NodePath = NodePath("../Player")
@export_group("Right Shoulder Composition")
@export_range(0.2, 10.0, 0.05) var rear_distance: float = 2.5
@export_range(0.0, 3.0, 0.05) var right_offset: float = 1.0
@export_range(0.2, 3.0, 0.05) var observation_height: float = 1.55
@export_group("Look Controls")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.12 # Degrees per pixel.
@export_range(10.0, 360.0, 5.0) var stick_sensitivity: float = 120.0 # Degrees per second.
@export_range(-85.0, 0.0, 1.0) var min_pitch_degrees: float = -60.0
@export_range(0.0, 85.0, 1.0) var max_pitch_degrees: float = 45.0
@export_group("Smoothing")
@export_range(0.0, 30.0, 0.5) var follow_smoothing: float = 16.0
@export_range(0.0, 30.0, 0.5) var rotation_smoothing: float = 12.0
@export_group("Temporary Single Target Soft Lock")
@export_range(0.1, 30.0, 0.5) var lock_camera_follow_speed: float = 8.0
@export_range(0.1, 30.0, 0.5) var lock_character_turn_speed: float = 8.0
@export_range(0.2, 2.0, 0.05) var lock_target_height_offset: float = 0.85
@export_range(0.25, 1.5, 0.05) var lock_camera_shoulder_bias: float = 1.0 # Multiplier of existing right offset.
@export_range(5, 30, 1) var lock_manual_look_degrees: float = 20.0 # Vertical adjustment only.
@export_range(5, 80, 1) var lock_yaw_limit_degrees: float = 40.0
@export_range(0.5, 1.0, 0.01) var lock_overrun_seconds: float = 0.5
@export_range(5, 80, 1) var reacquire_camera_degrees: float = 40.0
@export_range(5, 60, 1) var reacquire_movement_degrees: float = 20.0
@export var lock_angle_response_curve: Curve
enum Mode { FREE_CAMERA, SOFT_LOCK, ORIENT_TO_MOVEMENT }
var mode: Mode = Mode.FREE_CAMERA
var overrun_elapsed: float = 0
var overrun_side: float = 0
var mouse_overrun_intent: bool = false
var reacquire_armed: bool = false
var reacquire_camera_angle: float = 180
var reacquire_movement_angle: float = 180
var camera_condition: bool = false
var movement_condition: bool = false
var last_unlock_reason: String = "None"
var last_lock_event: String = "None"
var initial_auto_acquisition_enabled: bool = true # Regression-fixture isolation; normal scene leaves enabled.
var locked_target: Node3D
var lock_yaw_offset: float = 0
var lock_pitch_offset: float = 0
var composed_right_offset: float = 1.0

var target_yaw: float = 0.0
var target_pitch: float = 0.0
@onready var target: CharacterBody3D = get_node(target_path) as CharacterBody3D
@onready var pitch_pivot: Node3D = $PitchPivot
@onready var spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D
@onready var enemy: Node3D = get_node_or_null("../Enemy")

func _ready() -> void:
	global_position = target.global_position + Vector3.UP * observation_height
	target_yaw = target.rotation.y
	rotation.y = target_yaw
	spring_arm.add_excluded_object(target.get_rid())
	composed_right_offset = right_offset
	if is_instance_valid(enemy): enemy.get_node("DebugHealth").died.connect(_on_enemy_died)
	_apply_composition()

func is_locked() -> bool:
	if locked_target == null: return false
	if not is_instance_valid(locked_target):
		_release_lock("Target invalid", false)
		return false
	if not locked_target.is_inside_tree() or locked_target.get_node("DebugHealth").dead or target.get_node("DebugPlayerHealth").dead:
		_release_lock("Target/player unavailable", false)
		return false
	return true

func lock_point() -> Vector3:
	return locked_target.to_global(Vector3.UP * lock_target_height_offset) if is_locked() else Vector3.ZERO

func clear_soft_lock() -> void:
	mode = Mode.FREE_CAMERA
	overrun_elapsed = 0
	overrun_side = 0
	mouse_overrun_intent = false
	reacquire_armed = false
	camera_condition = false
	movement_condition = false
	reacquire_camera_angle = 180
	reacquire_movement_angle = 180
	last_unlock_reason = "None"
	last_lock_event = "None"
	locked_target = null
	lock_yaw_offset = 0
	lock_pitch_offset = 0
	# Continue from the actual view, avoiding a release-time jump to an old orbit angle.
	target_yaw = rotation.y
	target_pitch = pitch_pivot.rotation.x

func _release_lock(reason: String, orient: bool = true) -> void:
	clear_soft_lock()
	mode = Mode.ORIENT_TO_MOVEMENT if orient else Mode.FREE_CAMERA
	last_unlock_reason = reason
	last_lock_event = "Manual Unlock" if reason == "Manual toggle" else ("Boundary Unlock" if reason == "Sustained boundary input" else reason)

func _on_enemy_died() -> void:
	_release_lock("Target dead", false)

func mode_name() -> String:
	return ["Free Camera", "Soft Lock", "Orient to Movement"][mode]

func horizontal_angle(a: Vector3, b: Vector3) -> float:
	a.y = 0
	b.y = 0
	if a.length_squared() < 0.000001 or b.length_squared() < 0.000001: return 180
	return rad_to_deg(atan2(a.cross(b).y, a.dot(b)))

func horizontal_deviation() -> float:
	if not is_locked(): return 0
	return horizontal_angle(lock_point() - global_position, -global_basis.z)

func _angle_response(value: float) -> float:
	if lock_angle_response_curve == null: return value
	var previous := -1.0
	for i in range(65):
		var sample := lock_angle_response_curve.sample(float(i) / 64)
		if not is_finite(sample) or sample < previous - 0.00001 or sample < 0 or sample > 1: return value
		previous = sample
	if not is_equal_approx(lock_angle_response_curve.sample(0), 0) or not is_equal_approx(previous, 1): return value
	return clampf(lock_angle_response_curve.sample(value), 0, 1)

func _update_reacquisition() -> void:
	camera_condition = false
	movement_condition = false
	reacquire_camera_angle = 180
	reacquire_movement_angle = 180
	if mode == Mode.SOFT_LOCK or not _target_available(): return
	var to_enemy := enemy.global_position - target.global_position
	var camera_to_enemy := enemy.to_global(Vector3.UP * lock_target_height_offset) - camera.global_position
	reacquire_camera_angle = absf(horizontal_angle(-camera.global_basis.z, camera_to_enemy))
	camera_condition = reacquire_camera_angle <= reacquire_camera_degrees + 0.00001
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input.length_squared() > 0.000001:
		reacquire_movement_angle = absf(horizontal_angle(target.get_real_velocity(), to_enemy))
		movement_condition = reacquire_movement_angle <= reacquire_movement_degrees + 0.00001
	var eligible := camera_condition and movement_condition
	if mode == Mode.FREE_CAMERA:
		if initial_auto_acquisition_enabled and eligible: _acquire_lock("Auto Acquisition")
	elif not eligible: reacquire_armed = true
	elif reacquire_armed: _acquire_lock("Auto Reacquisition")

func _target_available() -> bool:
	return not target.get_node("DebugPlayerHealth").dead and is_instance_valid(enemy) and enemy.is_inside_tree() and not enemy.get_node("DebugHealth").dead

func toggle_soft_lock() -> bool:
	if is_locked():
		_release_lock("Manual toggle")
		return false
	return _acquire_lock("Manual Acquisition")

func _acquire_lock(source: String) -> bool:
	if not _target_available(): return false
	locked_target = enemy
	last_lock_event = source
	mode = Mode.SOFT_LOCK
	overrun_elapsed = 0
	mouse_overrun_intent = false
	reacquire_armed = false
	var delta := lock_point() - global_position
	var yaw := atan2(-delta.x, -delta.z)
	var pitch := atan2(delta.y, Vector2(delta.x, delta.z).length())
	var limit := deg_to_rad(lock_yaw_limit_degrees)
	lock_yaw_offset = clampf(wrapf(rotation.y - yaw, -PI, PI), -limit, limit)
	var pitch_limit := deg_to_rad(lock_manual_look_degrees)
	lock_pitch_offset = clampf(pitch_pivot.rotation.x - pitch, -pitch_limit, pitch_limit)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_soft_lock") and not event.is_echo():
		toggle_soft_lock()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("capture_mouse") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)

func _apply_mouse_look(relative_motion: Vector2) -> void:
	if is_locked():
		mouse_overrun_intent = _adjust_lock_look(-deg_to_rad(relative_motion.x * mouse_sensitivity), -deg_to_rad(relative_motion.y * mouse_sensitivity))
		return
	target_yaw = wrapf(target_yaw - deg_to_rad(relative_motion.x * mouse_sensitivity), -PI, PI)
	target_pitch -= deg_to_rad(relative_motion.y * mouse_sensitivity)
	_clamp_pitch()

func _adjust_lock_look(yaw: float, pitch: float) -> bool:
	var limit := deg_to_rad(lock_yaw_limit_degrees)
	var attempted := lock_yaw_offset + yaw
	lock_yaw_offset = clampf(attempted, -limit, limit)
	var pitch_limit := deg_to_rad(lock_manual_look_degrees)
	lock_pitch_offset = clampf(lock_pitch_offset + pitch, -pitch_limit, pitch_limit)
	return absf(yaw) > 0.000001 and absf(attempted) > limit + 0.000001

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var locked := is_locked()
	if locked:
		var stick_overrun := _adjust_lock_look(-deg_to_rad(look.x * stick_sensitivity) * delta, -deg_to_rad(look.y * stick_sensitivity) * delta)
		var at_boundary := absf(lock_yaw_offset) >= deg_to_rad(lock_yaw_limit_degrees) - 0.000001
		if at_boundary and (mouse_overrun_intent or stick_overrun):
			var side := signf(lock_yaw_offset)
			if side != overrun_side: overrun_elapsed = 0
			overrun_side = side
			overrun_elapsed += delta
		else:
			overrun_elapsed = 0
			overrun_side = 0
		if overrun_elapsed >= lock_overrun_seconds - 0.000001:
			_release_lock("Sustained boundary input")
			locked = false
	else:
		target_yaw = wrapf(target_yaw - deg_to_rad(look.x * stick_sensitivity) * delta, -PI, PI)
		target_pitch -= deg_to_rad(look.y * stick_sensitivity) * delta
	mouse_overrun_intent = false
	_clamp_pitch()
	var follow_weight := 1.0 if follow_smoothing <= 0.0 else 1.0 - exp(-follow_smoothing * delta)
	global_position = global_position.lerp(target.global_position + Vector3.UP * observation_height, follow_weight)
	if locked:
		var to_enemy := lock_point() - global_position
		var limit := deg_to_rad(lock_yaw_limit_degrees)
		var curved_offset := signf(lock_yaw_offset) * limit * _angle_response(clampf(absf(lock_yaw_offset) / limit, 0, 1))
		target_yaw = atan2(-to_enemy.x, -to_enemy.z) + curved_offset
		target_pitch = atan2(to_enemy.y, Vector2(to_enemy.x, to_enemy.z).length()) + lock_pitch_offset
		_clamp_pitch()
	var smoothing := lock_camera_follow_speed if locked else rotation_smoothing
	var rotate_weight := 1.0 if smoothing <= 0.0 else 1.0 - exp(-smoothing * delta)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotate_weight)
	pitch_pivot.rotation.x = lerpf(pitch_pivot.rotation.x, target_pitch, rotate_weight)
	var desired_offset := right_offset * lock_camera_shoulder_bias if locked else right_offset
	composed_right_offset = lerpf(composed_right_offset, desired_offset, 1.0 - exp(-lock_camera_follow_speed * delta)) if locked or not is_equal_approx(composed_right_offset, right_offset) else right_offset
	_apply_composition()
	if not locked: _update_reacquisition()

func _clamp_pitch() -> void:
	target_pitch = clampf(target_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

func _apply_composition() -> void:
	# Sweep from the observation point diagonally to the shoulder camera.
	# Counter-rotate the camera so it looks along orbit-forward, keeping the actor left.
	var shoulder_angle := atan2(composed_right_offset, rear_distance)
	spring_arm.rotation.y = shoulder_angle
	spring_arm.spring_length = Vector2(composed_right_offset, rear_distance).length()
	camera.rotation.y = -shoulder_angle
