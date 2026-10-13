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

var target_yaw: float = 0.0
var target_pitch: float = 0.0
@onready var target: CharacterBody3D = get_node(target_path) as CharacterBody3D
@onready var pitch_pivot: Node3D = $PitchPivot
@onready var spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D

func _ready() -> void:
	global_position = target.global_position + Vector3.UP * observation_height
	target_yaw = target.rotation.y
	rotation.y = target_yaw
	spring_arm.add_excluded_object(target.get_rid())
	_apply_composition()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("capture_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)

func _apply_mouse_look(relative_motion: Vector2) -> void:
	target_yaw = wrapf(target_yaw - deg_to_rad(relative_motion.x * mouse_sensitivity), -PI, PI)
	target_pitch -= deg_to_rad(relative_motion.y * mouse_sensitivity)
	_clamp_pitch()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	target_yaw = wrapf(target_yaw - deg_to_rad(look.x * stick_sensitivity) * delta, -PI, PI)
	target_pitch -= deg_to_rad(look.y * stick_sensitivity) * delta
	_clamp_pitch()
	var follow_weight := 1.0 if follow_smoothing <= 0.0 else 1.0 - exp(-follow_smoothing * delta)
	global_position = global_position.lerp(target.global_position + Vector3.UP * observation_height, follow_weight)
	var rotate_weight := 1.0 if rotation_smoothing <= 0.0 else 1.0 - exp(-rotation_smoothing * delta)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotate_weight)
	pitch_pivot.rotation.x = lerpf(pitch_pivot.rotation.x, target_pitch, rotate_weight)
	_apply_composition()

func _clamp_pitch() -> void:
	target_pitch = clampf(target_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

func _apply_composition() -> void:
	# Sweep from the observation point diagonally to the shoulder camera.
	# Counter-rotate the camera so it looks along orbit-forward, keeping the actor left.
	var shoulder_angle := atan2(right_offset, rear_distance)
	spring_arm.rotation.y = shoulder_angle
	spring_arm.spring_length = Vector2(right_offset, rear_distance).length()
	camera.rotation.y = -shoulder_angle
