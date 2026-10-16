extends CharacterBody3D

@export var camera_path: NodePath = NodePath("../ThirdPersonRig/PitchPivot/SpringArm3D/Camera3D")
@export_range(0.1, 10.0, 0.1) var walk_speed: float = 2.0
@export_range(0.1, 10.0, 0.1) var run_speed: float = 3.5
@export_range(0.0, 30.0, 0.5) var turn_smoothing: float = 12.0

var is_running: bool = false
@onready var movement_camera: Camera3D = get_node(camera_path) as Camera3D

func _physics_process(delta: float) -> void:
	if get_node("DebugPlayerHealth").dead:
		velocity = Vector3.ZERO
		return
	if Input.is_action_just_pressed("toggle_run"):
		is_running = not is_running

	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_right := movement_camera.global_basis.x
	var camera_back := movement_camera.global_basis.z
	camera_right.y = 0.0
	camera_back.y = 0.0
	var direction := camera_right.normalized() * input_direction.x + camera_back.normalized() * input_direction.y
	var speed := run_speed if is_running else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	# Face realized motion, including collision sliding, instead of just requested input.
	var actual_motion := get_real_velocity()
	actual_motion.y = 0.0
	var rig: Node3D = movement_camera.get_parent().get_parent().get_parent()
	if rig.is_locked():
		var to_target: Vector3 = rig.lock_point() - global_position
		to_target.y = 0
		if to_target.length_squared() > 0.0001:
			var heading := atan2(-to_target.x, -to_target.z)
			rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-rig.lock_character_turn_speed * delta))
		return
	if actual_motion.length_squared() > 0.0001:
		var heading := atan2(-actual_motion.x, -actual_motion.z)
		var weight := 1.0 if turn_smoothing <= 0.0 else 1.0 - exp(-turn_smoothing * delta)
		rotation.y = lerp_angle(rotation.y, heading, weight)
