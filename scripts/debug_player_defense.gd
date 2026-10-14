extends Node
## Active defense validation only: primitive hand/weapon motion, no resources/rewards.
@export_range(0.0, 0.5, 0.01) var perfect_window_seconds: float = 0.15
@export_range(0.0, 89.0, 1.0) var defense_half_angle_degrees: float = 60.0
@export_group("Temporary Defense Poses")
@export var parry_position := Vector3(0.22, 1.14, -0.62)
@export var parry_rotation_degrees := Vector3(-55, 0, 70)
@export var guard_position := Vector3(0.30, 1.08, -0.42)
@export var guard_rotation_degrees := Vector3(-65, 0, 65)
@export_range(0.05, 0.5, 0.01) var return_seconds: float = 0.20
var visual_tween: Tween
var held: bool = false
var perfect_remaining: float = 0.0
var last_result: String = "None"
var last_prevented_damage: float = 0.0
var require_release: bool = false
@onready var player: Node3D = get_parent()
@onready var health: Node = get_node("../DebugPlayerHealth")
@onready var demo: Node3D = get_node("../WeaponMotionDemo")
@onready var hand: Node3D = get_node("../VisualRoot/RightHand")

func _ready() -> void:
	demo.motion_started.connect(_on_attack_started)

func _on_attack_started(_id: int, _motion: int) -> void:
	_stop_visual()

func _stop_visual() -> void:
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()

func _visual_transition(defending: bool) -> void:
	_stop_visual()
	visual_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if defending:
		if perfect_remaining > 0:
			visual_tween.tween_property(hand, "transform", demo._pose(parry_position, parry_rotation_degrees), 0.06)
		visual_tween.tween_property(hand, "transform", demo._pose(guard_position, guard_rotation_degrees), 0.09)
	else:
		visual_tween.tween_property(hand, "transform", demo._idle_guard(), return_seconds)

func _physics_process(delta: float) -> void:
	perfect_remaining = maxf(0, perfect_remaining - delta)
	refresh_input()

func refresh_input() -> void:
	var pressed := Input.is_action_pressed("active_defense")
	if not pressed:
		if held:
			_visual_transition(false)
		require_release = false
		held = false
		perfect_remaining = 0
		return
	if health.dead or require_release:
		held = false
		perfect_remaining = 0
		return
	if not held:
		held = true
		perfect_remaining = perfect_window_seconds
		# Close before end-record notification so its final sweep cannot deal damage.
		demo.cancel_debug_motion("defense", true)
		_visual_transition(true)

func state_name() -> String:
	if not held:
		return "None"
	return "Perfect Parry" if perfect_remaining > 0 else "Held Guard"

func resolve_valid_contact(attacker: Node3D, damage: float) -> bool:
	refresh_input()
	var offset := attacker.global_position - player.global_position
	offset.y = 0
	var forward := -player.global_basis.z
	forward.y = 0
	var frontal := offset.length_squared() > 0.000001 and forward.normalized().dot(offset.normalized()) >= cos(deg_to_rad(defense_half_angle_degrees))
	if held and frontal:
		last_result = "Perfect Parry" if perfect_remaining > 0 else "Block"
		last_prevented_damage = maxf(0, damage)
		return true
	last_result = "Failed"
	last_prevented_damage = 0
	return false

func debug_reset_defense(clear_records: bool = true) -> void:
	if is_instance_valid(hand):
		_visual_transition(false)
	held = false
	perfect_remaining = 0
	if clear_records:
		last_result = "None"
		last_prevented_damage = 0
	require_release = Input.is_action_pressed("active_defense")
