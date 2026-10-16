extends Node
## Temporary player HP and event-based active-defense resolution; no injury/Game Over flow.
var _hp: float = 0.0
var dead: bool = false
var last_damage: float = 0.0
var damaged_requests: Dictionary = {}
var ignore_through_id: int = 0
var reset_epoch: int = 0
var last_settlement: Dictionary = {}
@export_range(1, 10000, 1, "or_greater") var max_hp: float = 100.0:
	set(value):
		max_hp = maxf(1.0, value)
		_hp = clampf(_hp, 0.0, max_hp)
@export_range(0, 1000, 1, "or_greater") var incoming_test_damage: float = 5.0:
	set(value): incoming_test_damage = maxf(0.0, value)
var hp: float:
	get: return _hp
@onready var player: CharacterBody3D = get_parent()
@onready var attack: Node3D = get_node("../../Enemy/DebugAttack")

func _ready() -> void:
	debug_reset_hp()

func _on_valid_contact(event: Dictionary) -> void:
	if event.has("detector") and event["generation"] != event["detector"].generation: return
	if dead or event.get("target") != player or event.get("contact_kind") != "valid_attack":
		return
	var id: int = event["request_id"]
	if id <= ignore_through_id or damaged_requests.has(id):
		return
	damaged_requests[id] = true
	var epoch := reset_epoch
	var defense: Node = player.get_node("DebugDefense")
	var resource_before: float = defense.resource
	var prevented: bool = defense.resolve_valid_contact(attack.get_parent(), incoming_test_damage, id)
	if epoch != reset_epoch: return # F7 during interruption must not resurrect this settlement.
	if prevented:
		last_damage = 0
		_record_settlement(id, defense.last_result, resource_before)
		return
	var before := _hp
	_hp = clampf(_hp - incoming_test_damage, 0, max_hp)
	last_damage = before - _hp
	_record_settlement(id, "Damage", resource_before)
	if _hp == 0:
		dead = true
		player.get_node("DebugDefense").debug_reset_defense(false)
		player.velocity = Vector3.ZERO
		player.get_node("WeaponMotionDemo").cancel_debug_motion("dead")
		attack.cancel_attack()
	print("DEBUG_PLAYER_DAMAGE request=", id, " damage=", last_damage, " HP=", _hp, " Dead=", dead)

func _record_settlement(id: int, result: String, before: float) -> void:
	last_settlement = {"request_id": id, "result": result, "damage": last_damage,
		"resource_before": before, "resource_after": player.get_node("DebugDefense").resource,
		"physics_frame": Engine.get_physics_frames()}
	damaged_requests[id] = last_settlement.duplicate()

func debug_reset_hp() -> void:
	reset_epoch += 1
	last_settlement = {}
	ignore_through_id = attack.accepted_request_count
	damaged_requests.clear()
	_hp = max_hp
	dead = false
	last_damage = 0
	player.velocity = Vector3.ZERO
	player.is_running = false
