extends Node
signal died
## Temporary static-enemy HP validation only; not final injury/death design.

var _hp: float = 0.0
var _dead: bool = false
var _damaged_requests: Dictionary = {}
var _ignore_through_request_id: int = 0
var last_damage: float = 0.0
var last_settlement: Dictionary = {}

@export_range(1.0, 10000.0, 1.0, "or_greater") var max_hp: float = 100.0:
	set(value):
		max_hp = maxf(1.0, value)
		_hp = clampf(_hp, 0.0, max_hp)
@export_range(0.0, 1000.0, 1.0, "or_greater") var test_damage: float = 10.0:
	set(value):
		test_damage = maxf(0.0, value)

var hp: float:
	get: return _hp
var dead: bool:
	get: return _dead

@onready var enemy: Node3D = get_parent() as Node3D
@onready var demo: Node3D = get_node("../../Player/WeaponMotionDemo") as Node3D
@onready var body: MeshInstance3D = enemy.get_node("VisualRoot/Body") as MeshInstance3D
var original_material: Material
var dead_material: StandardMaterial3D

func _ready() -> void:
	original_material = body.material_override
	dead_material = StandardMaterial3D.new()
	dead_material.albedo_color = Color(0.22, 0.22, 0.22, 1.0)
	dead_material.roughness = 1.0
	debug_reset_hp()
	get_node("../../WeaponContactDebug").valid_attack_contact_detected.connect(_on_valid_contact)

func _on_valid_contact(event: Dictionary) -> void:
	if event.has("detector") and event["generation"] != event["detector"].generation: return
	var defense: Node = get_node("../../Player/DebugDefense")
	if defense.instinctive_phase != "Idle" or defense.is_guard_broken():
		return # A canceled player motion's final swept sample cannot damage in reaction.
	if _dead or get_node("../../Player/DebugPlayerHealth").dead or get_node("../../Player/DebugDefense").held or event.get("contact_kind") != "valid_attack" or event.get("target") != enemy:
		return
	var request_id: int = event["request_id"]
	if request_id <= _ignore_through_request_id or _damaged_requests.has(request_id) or test_damage <= 0.0:
		return
	_damaged_requests[request_id] = true
	var guard: Node = get_node("../DebugDefense")
	var blocked: bool = guard.resolve_guard(event, get_node("../../Player"))
	guard.record_valid_pressure(event, blocked)
	last_settlement = {"request_id": request_id, "result": "Successful Guard" if blocked else "Damage", "damage": 0.0, "front": guard.last_front}
	if blocked:
		last_damage = 0.0
		return
	var before := _hp
	_hp = clampf(_hp - test_damage, 0.0, max_hp)
	last_damage = before - _hp # Actual HP removed, including a capped final blow.
	last_settlement["damage"] = last_damage
	if _hp <= 0.0:
		_dead = true
		body.material_override = dead_material
		died.emit()
	print("DEBUG_ENEMY_DAMAGE request=", request_id, " damage=", last_damage,
		" HP=", _hp, "/", max_hp, " Dead=", _dead)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F7:
		demo.cancel_debug_motion("debug_reset")
		get_node("../DebugAttack").cancel_attack()
		get_node("../DebugDefense").debug_reset()
		get_node("../../ThirdPersonRig").clear_soft_lock()
		debug_reset_hp()
		get_node("../../Player/DebugPlayerHealth").debug_reset_hp()
		get_node("../../Player/DebugDefense").debug_reset_defense()
		get_node("../../BladeClashDebug").debug_reset()
		get_node("../../Player/ContactMatchingDebug").debug_reset()
		get_node("../../WeaponContactDebug").debug_reset_contacts()
		get_node("../DebugAttack").detector.debug_reset_contacts()
		get_node("../../WeaponTrajectoryDebug").contact_markers.clear()
		get_viewport().set_input_as_handled()

func debug_reset_hp() -> void:
	# DEBUG ONLY: do not replay an already accepted/in-progress request after reset.
	_ignore_through_request_id = demo.accepted_request_count
	_damaged_requests.clear()
	_hp = max_hp
	_dead = false
	last_damage = 0.0
	last_settlement.clear()
	body.material_override = original_material
