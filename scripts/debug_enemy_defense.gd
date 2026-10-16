extends Node
const MATCHING = preload("res://scripts/debug_contact_matching.gd")
## Minimal reactive defense only. Body settlement remains independent of blade clash.
@export_group("Greybox Auto Defense")
@export var auto_defense_enabled: bool = true
@export_range(0, 2, 0.01) var reaction_delay: float = 0.20
@export_range(0.01, 2, 0.01) var guard_hold_duration: float = 0.35
@export_range(0.1, 5, 0.1) var threat_distance: float = 2.0
@export_group("Greybox Mistake and Pressure")
@export_range(0, 1, 0.01) var base_mistake_chance: float = 0.10
@export_range(0, 1, 0.01) var mistake_increase_per_pressure: float = 0.05
@export_range(0, 1, 0.01) var max_mistake_chance: float = 0.60
@export_range(0.05, 5, 0.05) var breathing_duration: float = 1.0
@export var use_test_seed: bool = false
@export var test_seed: int = 12345
var mistake_rng := RandomNumberGenerator.new()
var seeded_for_test: bool = false
var configured_seed: int = 0
var pressure_stacks: int = 0
var pressure_requests: Dictionary = {}
var pressure_ignore_through_id: int = 0
var last_pressure_reason: String = "Initial"
var breathing_eligible: bool = false
var breathing_elapsed: float = 0
var breathing_started_frame: int = -1
var last_mistake_request_id: int = 0
var last_mistake_roll: float = -1
var last_mistake_chance: float = 0
var last_mistake_pressure: int = 0
var last_mistake: bool = false
var mistake_decision_count: int = 0
@export_group("Manual Guard Override")
var _enabled: bool = false
@export var manual_guard_override: bool = false:
	get: return _enabled
	set(value): enemy_debug_guard_enabled = value
var enemy_debug_guard_enabled: bool = false: # Compatibility with existing guard tests/API.
	get: return _enabled
	set(value):
		if not is_node_ready():
			_enabled = value
		else:
			set_guard_enabled(value)
@export_range(0, 180, 1) var enemy_guard_arc: float = 60.0
@export_range(0.01, 1, 0.01) var guard_enter_duration: float = 0.16
@export_range(0.01, 1, 0.01) var guard_exit_duration: float = 0.20
@export var guard_hand_position := Vector3(0.50, 1.22, -0.35)
@export var guard_hand_rotation_degrees := Vector3(0, 0, 90)
@export_group("Greybox Contact Matching")
@export var contact_matching_enabled: bool = true
@export_range(0.1, 10, 0.1) var matching_hand_speed: float = 4.0
@export_range(1, 720, 1) var matching_rotation_speed_degrees: float = 360.0
@export_range(0, 0.5, 0.01) var matching_max_position: float = 0.35
@export_range(0, 60, 1) var matching_max_rotation_degrees: float = 40.0
@export_range(0, 0.2, 0.01) var matching_contact_hold_seconds: float = 0.08
var matching_active: bool = false
var matching_result: String = "Idle"
var matching_reason: String = "No request"
var matching_target := Vector3.ZERO
var matching_position_correction: float = 0
var matching_rotation_correction: float = 0
var matching_request_id: int = 0
var matching_completed_request: int = 0
var matching_hold: float = 0
var matching_last_frame: int = -1
var previous_player_tip := Vector3.ZERO
var guarding: bool = false
var owns_hand: bool = false
var tween: Tween
var last_result: String = "None"
var last_front: bool = false
var last_request_id: int = 0
var last_toggle_result: String = "None"
var ai_state: String = "Idle"
var ai_reason: String = "None"
var recognized_request_id: int = 0
var recognized_motion: int = -1
var reaction_elapsed: float = 0
var guard_hold_remaining: float = 0
var recognized_frame: int = -1
var last_seen_request_id: int = 0
var auto_guard_count: int = 0
@onready var enemy: Node3D = get_parent()
@onready var attack: Node3D = get_node("../DebugAttack")
@onready var health: Node = get_node("../DebugHealth")
@onready var hand: Node3D = get_node("../VisualRoot/RightHand")
@onready var weapon: Node3D = hand.get_node("Gunblade")
@onready var player: Node3D = get_node("../../Player")
@onready var demo: Node3D = player.get_node("WeaponMotionDemo")
@onready var player_weapon: Node3D = player.get_node("VisualRoot/RightHand/Gunblade")

func _ready() -> void:
	process_physics_priority = -5 # Resolve guard availability before the stationary attacker.
	health.died.connect(_on_death)
	_seed_mistakes()
	demo.motion_started.connect(_on_player_attack_started)
	if enemy_debug_guard_enabled: _set_guard_pose(true)

func set_guard_enabled(value: bool) -> bool:
	if health.dead or (value and attack.active_request_id != 0):
		last_toggle_result = "Rejected: Dead" if health.dead else "Rejected: Attack active"
		return false
	if value == enemy_debug_guard_enabled: return true
	_enabled = value
	_clear_ai()
	return _set_guard_pose(value)

func _set_guard_pose(value: bool) -> bool:
	if value == guarding: return true
	guarding = value
	_clear_matching()
	owns_hand = true
	attack.cancel_attack(true) # Stop queued burst/return, preserving the current hand pose.
	if tween != null and tween.is_valid(): tween.kill()
	var target: Transform3D = attack.idle
	if value: target = attack._pose(guard_hand_position, guard_hand_rotation_degrees)
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(hand, "transform", target, guard_enter_duration if value else guard_exit_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if not value: tween.tween_callback(_release_hand)
	last_toggle_result = "Enabled" if value else "Disabled"
	ai_state = "Guarding" if value else "Recovering"
	return true

func _release_hand() -> void:
	if not guarding:
		owns_hand = false
		ai_state = "Idle"

func defense_mode() -> String:
	return "Manual Override" if _enabled else "Auto"

func recognized_motion_name() -> String:
	return ["Thrust", "Short Cut", "Broad Cut"][recognized_motion] if recognized_motion >= 0 else "None"

func _threat_reason(id: int) -> String:
	if health.dead or player.get_node("DebugPlayerHealth").dead: return "Dead"
	if demo.active_request_id != id or not demo.window_live: return "Attack Ended"
	if demo.playback_state()["playback_time"] >= demo.playback_state()["window_end"]: return "Attack Ended"
	if enemy.global_position.distance_to(player.global_position) > threat_distance: return "Out of Range"
	if not in_front(player): return "Outside Guard Arc"
	return ""

func _on_player_attack_started(id: int, motion: int) -> void:
	if id <= last_seen_request_id or demo.active_request_id != id or not demo.window_live: return
	last_seen_request_id = id # Every real request is considered once, including rejected threats.
	if ai_state == "Reacting": _clear_ai() # A new executed request supersedes an old pending reaction.
	if _enabled: return
	if not auto_defense_enabled:
		ai_reason = "Auto Disabled"
		return
	var rejection := _threat_reason(id)
	if rejection.is_empty() and attack.active_request_id != 0: rejection = "Already Attacking"
	if rejection.is_empty() and owns_hand: rejection = "Already Guarding" if guarding else "Recovering"
	if rejection.is_empty() and attack.tween != null and attack.tween.is_running(): rejection = "Recovering"
	if not rejection.is_empty():
		ai_reason = rejection
		return
	if _roll_mistake(id):
		ai_reason = "Mistake: missed defense opportunity"
		return
	recognized_request_id = id
	recognized_motion = motion
	reaction_elapsed = 0
	recognized_frame = Engine.get_physics_frames()
	ai_state = "Reacting"
	ai_reason = "Waiting Reaction Delay"

func _tick_auto_defense(delta: float) -> void:
	if health.dead: return
	if _enabled:
		ai_state = "Guarding"
		return
	if not auto_defense_enabled or player.get_node("DebugPlayerHealth").dead:
		ai_reason = "Auto Disabled" if not auto_defense_enabled else "Dead"
		if guarding: _set_guard_pose(false)
		if ai_state == "Reacting":
			ai_state = "Idle"
			recognized_request_id = 0
			reaction_elapsed = 0
		return
	if ai_state == "Guarding":
		guard_hold_remaining = maxf(0, guard_hold_remaining - delta)
		if guard_hold_remaining <= 0: _set_guard_pose(false)
		return
	if ai_state != "Reacting": return
	var rejection := _threat_reason(recognized_request_id)
	if rejection.is_empty() and attack.active_request_id != 0: rejection = "Already Attacking"
	if rejection.is_empty() and (owns_hand or (attack.tween != null and attack.tween.is_running())): rejection = "Recovering"
	if not rejection.is_empty():
		ai_reason = rejection
		ai_state = "Idle"
		recognized_request_id = 0
		reaction_elapsed = 0
		return
	if Engine.get_physics_frames() <= recognized_frame: return
	reaction_elapsed = minf(reaction_delay, reaction_elapsed + delta)
	if reaction_elapsed + 0.000001 < reaction_delay: return
	_set_guard_pose(true)
	guard_hold_remaining = guard_hold_duration
	auto_guard_count += 1
	ai_reason = "Reaction Complete"

func _clear_ai() -> void:
	ai_state = "Idle"
	ai_reason = "None"
	recognized_request_id = 0
	recognized_motion = -1
	reaction_elapsed = 0
	guard_hold_remaining = 0
	recognized_frame = -1

func current_mistake_chance() -> float:
	return minf(clampf(base_mistake_chance, 0, 1) + pressure_stacks * clampf(mistake_increase_per_pressure, 0, 1), clampf(max_mistake_chance, 0, 1))

func _seed_mistakes() -> void:
	seeded_for_test = use_test_seed
	configured_seed = test_seed
	if use_test_seed: mistake_rng.seed = test_seed
	else: mistake_rng.randomize()

func _roll_mistake(id: int) -> bool:
	if seeded_for_test != use_test_seed or configured_seed != test_seed: _seed_mistakes()
	last_mistake_request_id = id
	last_mistake_pressure = pressure_stacks
	last_mistake_chance = current_mistake_chance()
	last_mistake_roll = mistake_rng.randf()
	last_mistake = last_mistake_chance >= 1 or last_mistake_roll < last_mistake_chance
	mistake_decision_count += 1
	return last_mistake

func record_valid_pressure(event: Dictionary, blocked: bool) -> void:
	# Only the live, actual detector stream may generate pressure. Debug HP calls do not.
	var id: int = event.get("request_id", 0)
	if health.dead or event.get("contact_kind") != "valid_attack" or event.get("target") != enemy: return
	var detector := get_node("../../WeaponContactDebug")
	if event.get("detector") != detector or event.get("generation", -1) != detector.generation: return
	if id != demo.active_request_id or not demo.window_live or demo.ending_record or id <= pressure_ignore_through_id or pressure_requests.has(id): return
	pressure_requests[id] = true
	pressure_stacks += 1
	# Every pressure event cancels the old breathing attempt. A new block may requalify.
	breathing_eligible = blocked
	breathing_elapsed = 0
	breathing_started_frame = Engine.get_physics_frames() if blocked else -1
	last_pressure_reason = "Successful Guard pressure #%d; breathing restarted" % id if blocked else "Damage pressure #%d; breathing canceled" % id

func _tick_breathing(delta: float) -> void:
	if health.dead or not breathing_eligible or Engine.get_physics_frames() <= breathing_started_frame: return
	breathing_elapsed = minf(breathing_duration, breathing_elapsed + delta)
	if breathing_elapsed + 0.000001 < breathing_duration: return
	pressure_stacks = 0
	breathing_eligible = false # Recovery qualification is consumed, not permanent.
	breathing_started_frame = -1
	last_pressure_reason = "Successful Guard followed by complete breathing interval"

func _reset_pressure(reason: String) -> void:
	pressure_stacks = 0
	pressure_requests.clear()
	pressure_ignore_through_id = demo.accepted_request_count
	breathing_eligible = false
	breathing_elapsed = 0
	breathing_started_frame = -1
	last_pressure_reason = reason
	last_mistake_request_id = 0
	last_mistake_roll = -1
	last_mistake_chance = 0
	last_mistake_pressure = 0
	last_mistake = false
	mistake_decision_count = 0
	_seed_mistakes()

func _on_death() -> void:
	debug_reset()
	last_pressure_reason = "Enemy Dead"

func state_name() -> String:
	return "Held Guard" if guarding and not health.dead else "Not Guarding"

func in_front(attacker: Node3D) -> bool:
	var direction := attacker.global_position - enemy.global_position
	direction.y = 0
	var forward := -enemy.global_basis.z
	forward.y = 0
	return direction.length_squared() > 0.0001 and forward.normalized().dot(direction.normalized()) >= cos(deg_to_rad(enemy_guard_arc))

func _physics_process(delta: float) -> void:
	_tick_breathing(delta)
	_tick_auto_defense(delta)
	call_deferred("update_matching") # Read actual weapon markers after physics Tweens.

func update_matching() -> void:
	var frame := Engine.get_physics_frames()
	if matching_last_frame == frame: return
	matching_last_frame = frame
	if not guarding or health.dead or not owns_hand: return
	if tween != null and tween.is_running(): return # Entry/exit and matching never write together.
	var delta := get_physics_process_delta_time()
	var baseline: Transform3D = attack._pose(guard_hand_position, guard_hand_rotation_degrees)
	var playback: Dictionary = demo.playback_state()
	var id: int = demo.active_request_id
	var eligible: bool = contact_matching_enabled and not player.get_node("DebugPlayerHealth").dead and in_front(player) and id != 0 and playback["window_live"] and playback["playback_time"] < playback["window_end"]
	if not eligible or matching_completed_request == id:
		if matching_hold > 0 and eligible:
			matching_hold = maxf(0, matching_hold - delta)
			return
		matching_active = false
		if not eligible: matching_reason = "No live frontal attack"
		_move_hand(baseline, delta)
		return
	if matching_request_id != id:
		matching_request_id = id
		matching_hold = 0
		previous_player_tip = player_weapon.get_node("BladeTip").global_position
	matching_active = true
	var blade_base: Vector3 = player_weapon.get_node("BladeBase").global_position
	var blade_tip: Vector3 = player_weapon.get_node("BladeTip").global_position
	var motion := (blade_tip - previous_player_tip).normalized()
	previous_player_tip = blade_tip
	var offsets := _blade_offsets()
	var solution: Dictionary = MATCHING.solve_contact_pose(hand, weapon, baseline,
		offsets[0], offsets[1], motion, matching_max_position, matching_max_rotation_degrees, blade_base, blade_tip)
	if solution.is_empty():
		matching_result = "Failed"
		matching_reason = "No body-safe solution within limits"
		return
	matching_target = solution["target"]
	if not _move_hand(solution["pose"], delta):
		matching_result = "Failed"
		matching_reason = "Intermediate pose violates body clearance"
		return
	matching_position_correction = hand.position.distance_to(baseline.origin)
	matching_rotation_correction = rad_to_deg(baseline.basis.get_rotation_quaternion().angle_to(hand.basis.get_rotation_quaternion()))
	var actual: Vector3 = hand.global_transform * solution["blade_point"]
	matching_result = "Matched" if actual.distance_to(matching_target) <= 0.01 else "Limited"
	matching_reason = "Pose convergence only; clash is independent" if matching_result == "Matched" else "Speed-limited approach"

func _blade_offsets() -> Array[Vector3]:
	return [weapon.transform * weapon.get_node("BladeBase").position, weapon.transform * weapon.get_node("BladeTip").position]

func _move_hand(desired: Transform3D, delta: float) -> bool:
	var q := hand.basis.get_rotation_quaternion()
	var target_q := desired.basis.get_rotation_quaternion()
	var amount := minf(1, deg_to_rad(matching_rotation_speed_degrees) * delta / maxf(q.angle_to(target_q), 0.000001))
	var next := Transform3D(Basis(q.slerp(target_q, amount)), hand.position.move_toward(desired.origin, matching_hand_speed * delta))
	var offsets := _blade_offsets()
	if not MATCHING.safe_contact_pose(next, offsets[0], offsets[1]): return false
	hand.transform = next
	return true

func _on_clash(event: Dictionary) -> void:
	if matching_active and event.get("attack_side") == "Player" and event["request_id"] == matching_request_id:
		matching_completed_request = matching_request_id
		matching_hold = matching_contact_hold_seconds

func _clear_matching() -> void:
	matching_active = false
	matching_request_id = 0
	matching_completed_request = 0
	matching_hold = 0
	matching_last_frame = -1
	matching_result = "Idle"
	matching_reason = "No request"
	matching_target = Vector3.ZERO
	matching_position_correction = 0
	matching_rotation_correction = 0
	previous_player_tip = Vector3.ZERO

func resolve_guard(event: Dictionary, attacker: Node3D) -> bool:
	last_front = in_front(attacker)
	last_request_id = event["request_id"]
	var blocked: bool = guarding and not health.dead and last_front
	last_result = "Successful Guard" if blocked else "Damage"
	return blocked

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("debug_toggle_enemy_guard", true):
		set_guard_enabled(not enemy_debug_guard_enabled)
		get_viewport().set_input_as_handled()

func debug_reset() -> void:
	_reset_pressure("F7 Debug Reset")
	_clear_ai()
	last_seen_request_id = demo.accepted_request_count
	auto_guard_count = 0
	_clear_matching()
	if tween != null and tween.is_valid(): tween.kill()
	_enabled = false
	guarding = false
	owns_hand = false
	last_result = "None"
	last_front = false
	last_request_id = 0
	last_toggle_result = "None"
	hand.transform = attack.idle
