extends Node3D
signal attack_started(request_id: int)
## Deterministic stationary greybox burst; not formal enemy AI.
const CONTACT_SCRIPT = preload("res://scripts/weapon_contact_debug.gd")
enum Motion { THRUST, LEFT_CUT, RIGHT_CUT }
@export var enabled: bool = true
@export_group("Temporary Burst Rhythm")
@export_range(3, 5, 1) var sequence_length: int = 4
@export_range(0.10, 0.20, 0.01) var attack_gap_seconds: float = 0.15
@export_range(0.6, 1.0, 0.05) var sequence_recovery_seconds: float = 0.80
@export_group("Stationary Attack")
@export_range(0.1, 5, 0.1) var attack_distance: float = 1.6
@export_range(1, 360, 1) var turn_speed_degrees: float = 90.0
@export var active_window := Vector2(0.25, 0.50)
@export var left_cut_active_window := Vector2(0.12, 0.32)
@export var right_cut_active_window := Vector2(0.12, 0.32)
var motion: int = Motion.THRUST
var sequence_active: bool = false
var sequence_index: int = 0
var sequence_id: int = 0
var motion_duration: float = 0.80
var accepted_request_count: int = 0
var active_request_id: int = 0
var cooldown: float = 0.80
var tween: Tween
var previous_time: float = 0.0
var detector: Node3D
@onready var enemy: Node3D = get_parent()
@onready var player: Node3D = get_node("../../Player")
@onready var health: Node = get_node("../DebugHealth")
@onready var hand: Node3D = get_node("../VisualRoot/RightHand")
@onready var weapon: Node3D = hand.get_node("Gunblade")
var idle: Transform3D

func _ready() -> void:
	idle = _pose(Vector3(0.38, 1.1, -0.18), Vector3(-25, 0, -8))
	hand.transform = idle
	detector = Node3D.new()
	detector.set_script(CONTACT_SCRIPT)
	detector.name = "EnemyBladeContact"
	detector.subscribe_to_trajectory = false
	detector.contact_mask = 4
	detector.motion_names = PackedStringArray(["Thrust", "Left Cut", "Right Cut"])
	detector.target_region_path = NodePath("../../../Player/DebugContactRegion")
	add_child(detector)
	detector.valid_attack_contact_detected.connect(player.get_node("DebugPlayerHealth")._on_valid_contact)
	health.died.connect(cancel_attack)
	cooldown = sequence_recovery_seconds

func _physics_process(delta: float) -> void:
	if not enabled or health.dead or player.get_node("DebugPlayerHealth").dead:
		cancel_attack()
		return
	if active_request_id == 0:
		cooldown = maxf(0, cooldown - delta)
		var offset := player.global_position - enemy.global_position
		if sequence_active and offset.length() > attack_distance:
			_finish_sequence()
		if offset.length() <= attack_distance:
			offset.y = 0
			if offset.length_squared() > 0.0001:
				enemy.rotation.y = rotate_toward(enemy.rotation.y, atan2(-offset.x, -offset.z), deg_to_rad(turn_speed_degrees) * delta)
			if cooldown <= 0:
				if not sequence_active:
					start_sequence()
				else:
					_start_next()
	if active_request_id != 0:
		call_deferred("_sample_attack", active_request_id)

func start_sequence() -> bool:
	if sequence_active or active_request_id != 0 or not enabled or health.dead or player.get_node("DebugPlayerHealth").dead or enemy.global_position.distance_to(player.global_position) > attack_distance:
		return false
	sequence_active = true
	sequence_index = 0
	sequence_id += 1
	_start_next()
	return true

func _start_next() -> void:
	var next_motion := sequence_index % 3
	sequence_index += 1
	start_attack(next_motion)

func start_attack(requested_motion: int = Motion.THRUST) -> bool:
	if not enabled or health.dead or player.get_node("DebugPlayerHealth").dead or active_request_id != 0:
		return false
	accepted_request_count += 1
	active_request_id = accepted_request_count
	motion = requested_motion
	if tween != null and tween.is_valid(): tween.kill()
	# Rotation stops during the swing; no mid-swing homing or root translation.
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match motion:
		Motion.THRUST:
			tween.tween_property(hand, "transform", _pose(Vector3(0.36, 1.12, -0.08), Vector3(-45, 0, -8)), 0.25)
			tween.tween_property(hand, "transform", _pose(Vector3(0.24, 1.22, -0.70), Vector3(-90, 0, 0)), 0.25)
			if sequence_active:
				tween.tween_property(hand, "transform", _pose(Vector3(0.26, 1.20, -0.50), Vector3(-80, 0, -20)), 0.10)
			else:
				tween.tween_property(hand, "transform", idle, 0.30)
			motion_duration = 0.60 if sequence_active else 0.80
		Motion.LEFT_CUT:
			tween.tween_property(hand, "transform", _pose(Vector3(0.50, 1.25, -0.25), Vector3(-50, 0, -65)), 0.12)
			tween.tween_property(hand, "transform", _pose(Vector3(-0.22, 1.08, -0.55), Vector3(-70, 0, 65)), 0.20)
			tween.tween_property(hand, "transform", _pose(Vector3(-0.25, 1.08, -0.45), Vector3(-70, 0, 65)), 0.10)
			motion_duration = 0.42
		Motion.RIGHT_CUT:
			tween.tween_property(hand, "transform", _pose(Vector3(-0.35, 1.20, -0.35), Vector3(-55, 0, 65)), 0.12)
			tween.tween_property(hand, "transform", _pose(Vector3(0.48, 1.03, -0.58), Vector3(-75, 0, -65)), 0.20)
			tween.tween_property(hand, "transform", _pose(Vector3(0.50, 1.03, -0.48), Vector3(-75, 0, -65)), 0.10)
			motion_duration = 0.42
	previous_time = 0
	attack_started.emit(active_request_id)
	detector._on_sample(active_request_id, motion, _sample(0))
	return true

func get_active_window() -> Vector2:
	var configured: Vector2 = [active_window, left_cut_active_window, right_cut_active_window][motion]
	var preparation: float = [0.25, 0.12, 0.12][motion]
	var strike_end: float = [0.50, 0.32, 0.32][motion]
	var start := clampf(configured.x, preparation, strike_end)
	return Vector2(start, clampf(configured.y, start, strike_end))

func _sample(time: float) -> Dictionary:
	var window := get_active_window()
	return {"frame": Engine.get_physics_frames(), "base": weapon.get_node("BladeBase").global_position,
		"tip": weapon.get_node("BladeTip").global_position, "weapon_rotation": weapon.global_basis.get_rotation_quaternion(),
		"playback_time": time, "window_start": window.x, "window_end": window.y,
		"window_live": true, "window_active": time >= window.x and time < window.y}

func _sample_attack(id: int) -> void:
	if id != active_request_id or active_request_id == 0 or health.dead or player.get_node("DebugPlayerHealth").dead:
		return
	previous_time = minf(tween.get_total_elapsed_time(), motion_duration)
	player.get_node("ContactMatchingDebug").update_matching(id, get_physics_process_delta_time())
	get_node("../../BladeClashDebug").sample_attack(id)
	detector._on_sample(id, motion, _sample(previous_time))
	if id == active_request_id and not tween.is_running():
		var clash: Node = get_node("../../BladeClashDebug")
		if not clash.latest.is_empty() and clash.latest["request_id"] == id:
			clash.latest["end_frame"] = Engine.get_physics_frames()
		active_request_id = 0
		if sequence_active and sequence_index < sequence_length and enemy.global_position.distance_to(player.global_position) <= attack_distance:
			cooldown = attack_gap_seconds
		else:
			_finish_sequence()

func _finish_sequence() -> void:
	sequence_active = false
	sequence_index = 0
	cooldown = sequence_recovery_seconds
	if tween != null and tween.is_valid(): tween.kill()
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(hand, "transform", idle, 0.25).set_trans(Tween.TRANS_SINE)

func cancel_attack() -> void:
	active_request_id = 0
	sequence_active = false
	sequence_index = 0
	if tween != null and tween.is_valid():
		tween.kill()
	cooldown = sequence_recovery_seconds
	if is_instance_valid(hand):
		hand.transform = idle

func _pose(position: Vector3, degrees: Vector3) -> Transform3D:
	return Transform3D(Basis.from_euler(degrees * PI / 180), position)
