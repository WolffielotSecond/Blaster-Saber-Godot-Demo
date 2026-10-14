extends Node3D
## Visual-only pose selection demo. Static geometry reference; no tracking, hits or root motion.

enum Motion { THRUST, SHORT_CUT, BROAD_CUT }

signal motion_started(request_id: int, motion: int)
signal motion_ended(request_id: int, reason: String)

@export var right_hand_path: NodePath = NodePath("../VisualRoot/RightHand")
@export_range(0.05, 1.0, 0.01) var return_duration: float = 0.3
@export var reference_target_path: NodePath = NodePath("../../Enemy")
@export_group("Temporary Selection Thresholds")
@export_range(0.1, 5.0, 0.1) var thrust_distance: float = 1.6
@export_range(0.0, 90.0, 1.0) var thrust_angle_degrees: float = 20.0
@export_range(0.1, 5.0, 0.1) var broad_cut_distance: float = 2.8
@export_range(0.0, 90.0, 1.0) var broad_cut_angle_degrees: float = 55.0
@export_group("No-Buffer Request Windows")
@export_range(0.2, 0.3, 0.01) var thrust_lock_duration: float = 0.26
@export_range(0.2, 0.3, 0.01) var short_cut_lock_duration: float = 0.24
@export_range(0.2, 0.3, 0.01) var broad_cut_lock_duration: float = 0.30
@export_group("Temporary Active Windows (Playback Seconds)")
@export var thrust_active_window := Vector2(0.12, 0.26)
@export var short_cut_active_window := Vector2(0.10, 0.24)
@export var broad_cut_active_window := Vector2(0.18, 0.52)

var selected_motion: Motion = Motion.THRUST
var motion_tween: Tween
var lock_remaining: float = 0.0
var last_motion: Motion = Motion.THRUST
var accepted_request_count: int = 0 # Debug observation only, not a combo counter.
var active_request_id: int = 0
var window_live: bool = false
@onready var right_hand: Node3D = get_node(right_hand_path) as Node3D
@onready var actor: Node3D = get_parent() as Node3D
@onready var reference_target: Node3D = get_node_or_null(reference_target_path) as Node3D

func _ready() -> void:
	# Blend from the existing greybox pose rather than snapping on scene entry.
	_begin_transition()
	_blend_to(_idle_guard(), return_duration)

func _physics_process(delta: float) -> void:
	lock_remaining = maxf(0.0, lock_remaining - delta)
	if Input.is_action_just_pressed("demo_select_thrust"):
		selected_motion = Motion.THRUST
	elif Input.is_action_just_pressed("demo_select_short_cut"):
		selected_motion = Motion.SHORT_CUT
	elif Input.is_action_just_pressed("demo_select_broad_cut"):
		selected_motion = Motion.BROAD_CUT
	if Input.is_action_just_pressed("demo_motion_request"):
		request_motion(selected_motion)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ordinary_motion_request") or event.is_echo():
		return
	# The first click belongs only to mouse capture, even if event order changes.
	if event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	request_ordinary_motion()
	get_viewport().set_input_as_handled()

func request_ordinary_motion() -> bool:
	if lock_remaining > 0.0:
		return false # Discard completely: no pending request or input buffer.
	return request_motion(choose_motion())

func choose_motion() -> Motion:
	if not is_instance_valid(reference_target):
		return Motion.SHORT_CUT
	var offset := reference_target.global_position - actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance < 0.001:
		return Motion.SHORT_CUT
	var forward := -actor.global_basis.z
	forward.y = 0.0
	var angle := rad_to_deg(acos(clampf(forward.normalized().dot(offset / distance), -1.0, 1.0)))
	var active := accepted_request_count > 0 and motion_tween != null and motion_tween.is_running()
	if distance <= thrust_distance and angle <= thrust_angle_degrees:
		return Motion.SHORT_CUT if active and last_motion == Motion.THRUST else Motion.THRUST
	if distance > thrust_distance and distance <= broad_cut_distance and angle <= broad_cut_angle_degrees:
		return Motion.SHORT_CUT if active and last_motion == Motion.BROAD_CUT else Motion.BROAD_CUT
	return Motion.SHORT_CUT # Includes out-of-range, off-axis or missing-target requests.

func request_motion(motion: Motion) -> bool:
	var defense: Node = actor.get_node("DebugDefense")
	defense.refresh_input()
	if defense.held:
		return false
	if actor.get_node("DebugPlayerHealth").dead or lock_remaining > 0.0:
		return false
	_end_motion_record("interrupted")
	last_motion = motion
	accepted_request_count += 1
	active_request_id = accepted_request_count
	match motion:
		Motion.THRUST: lock_remaining = thrust_lock_duration
		Motion.SHORT_CUT: lock_remaining = short_cut_lock_duration
		Motion.BROAD_CUT: lock_remaining = broad_cut_lock_duration
	# Killing the old tween retains the current hand pose. The new tween starts there.
	_begin_transition()
	match motion:
		Motion.THRUST:
			_blend_to(_pose(Vector3(0.36, 1.12, -0.08), Vector3(-45, 0, -8)), 0.12)
			_blend_to(_pose(Vector3(0.24, 1.22, -0.70), Vector3(-90, 0, 0)), 0.14)
		Motion.SHORT_CUT:
			_blend_to(_pose(Vector3(0.50, 1.18, -0.25), Vector3(-40, 0, -45)), 0.10)
			_blend_to(_pose(Vector3(0.14, 1.10, -0.40), Vector3(-50, 0, 30)), 0.14)
		Motion.BROAD_CUT:
			_blend_to(_pose(Vector3(0.55, 1.30, -0.10), Vector3(-15, 0, -75)), 0.18)
			_blend_to(_pose(Vector3(0.38, 1.35, -0.65), Vector3(-75, 0, -15)), 0.16)
			_blend_to(_pose(Vector3(-0.25, 1.00, -0.40), Vector3(-50, 0, 65)), 0.18)
	_blend_to(_idle_guard(), return_duration)
	motion_tween.finished.connect(_finish_motion_record.bind(active_request_id))
	window_live = true
	motion_started.emit(active_request_id, int(motion))
	return true

func _finish_motion_record(request_id: int) -> void:
	if request_id == active_request_id:
		_end_motion_record("completed")

func cancel_debug_motion(reason: String, preserve_lock: bool = false) -> void:
	_end_motion_record(reason)
	if motion_tween != null and motion_tween.is_valid():
		motion_tween.kill()
	if not preserve_lock:
		lock_remaining = 0

func _end_motion_record(reason: String) -> void:
	window_live = false
	if active_request_id != 0:
		motion_ended.emit(active_request_id, reason)
		active_request_id = 0

func playback_state() -> Dictionary:
	var strike_end: float = [0.26, 0.24, 0.52][last_motion]
	var preparation_end: float = [0.12, 0.10, 0.18][last_motion]
	var duration := strike_end + return_duration
	var configured: Vector2 = [thrust_active_window, short_cut_active_window, broad_cut_active_window][last_motion]
	var start := clampf(configured.x, preparation_end, strike_end)
	var end := clampf(configured.y, start, strike_end)
	var time := 0.0
	if active_request_id != 0 and motion_tween != null:
		time = minf(motion_tween.get_total_elapsed_time(), duration)
	return {"playback_time": time, "duration": duration, "window_start": start,
		"window_end": end, "window_live": window_live,
		"window_active": window_live and time >= start and time < end}

func _begin_transition() -> void:
	if motion_tween != null and motion_tween.is_valid():
		motion_tween.kill()
	motion_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	motion_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _blend_to(pose: Transform3D, duration: float) -> void:
	motion_tween.tween_property(right_hand, "transform", pose, duration)

func _idle_guard() -> Transform3D:
	return _pose(Vector3(0.38, 1.10, -0.18), Vector3(-25, 0, -8))

func _pose(position: Vector3, degrees: Vector3) -> Transform3D:
	return Transform3D(Basis.from_euler(degrees * PI / 180.0), position)
