extends Node
## Single temporary defense resource and primitive guard motion; no injury/reward system.
@export_range(0.0, 0.5, 0.01) var perfect_window_seconds: float = 0.15
@export_range(0.0, 89.0, 1.0) var defense_half_angle_degrees: float = 60.0
var _resource: float = 100.0
@export_group("Temporary Single Defense Resource")
@export_range(1, 1000, 1, "or_greater") var max_resource: float = 100.0:
	set(value):
		max_resource = maxf(1, value)
		_resource = clampf(_resource, 0, max_resource)
@export_range(0, 1000, 1, "or_greater") var held_guard_cost: float = 10.0:
	set(value): held_guard_cost = maxf(0, value)
@export_range(0.1, 5, 0.1) var guard_break_seconds: float = 1.0
@export_range(0, 5, 0.1) var recovery_delay_seconds: float = 1.0
@export_range(0, 100, 1, "or_greater") var recovery_per_second: float = 20.0
var resource: float:
	get: return _resource
var guard_break_remaining: float = 0
var recovery_elapsed: float = 0
var recovery_state: String = "Full"
var last_resource_cost: float = 0
var resolved_requests: Dictionary = {}
var last_break_request_id: int = 0
@export_group("Temporary Instinctive Defense")
@export var instinctive_enabled: bool = true
@export_range(1, 1000, 1, "or_greater") var instinctive_cost: float = 50.0
@export_range(0.02, 0.2, 0.01) var instinctive_raise_seconds: float = 0.06
@export_range(0.02, 0.5, 0.01) var instinctive_intercept_seconds: float = 0.18
@export_range(0.02, 0.5, 0.01) var instinctive_stagger_seconds: float = 0.12
@export_range(0.02, 0.5, 0.01) var instinctive_return_seconds: float = 0.22
@export var instinctive_stagger_offset := Vector3(0.10, -0.06, 0.04)
@export var instinctive_stagger_rotation_degrees := Vector3(10, 0, -20)
var instinctive_phase: String = "Idle"
var instinctive_remaining: float = 0
var instinctive_request_id: int = 0
var last_instinctive_triggered: bool = false
var last_instinctive_cost: float = 0
var instinctive_reason: String = "No valid contact"
@export_group("Temporary Guard Break Motion")
@export_range(0.02, 1, 0.01) var break_deflect_seconds: float = 0.12
@export_range(0, 1, 0.01) var break_hold_seconds: float = 0.08
@export_range(0.02, 1, 0.01) var break_return_seconds: float = 0.30
@export var break_position_offset := Vector3(0.22, -0.10, 0.08)
@export var break_rotation_offset_degrees := Vector3(20, 0, -45)
@export_group("Temporary Defense Poses")
@export var parry_position := Vector3(0.22, 1.14, -0.62)
@export var parry_rotation_degrees := Vector3(-55, 0, 70)
@export var guard_position := Vector3(0.30, 1.08, -0.42)
@export var guard_rotation_degrees := Vector3(-65, 0, 65)
@export_range(0.05, 0.5, 0.01) var return_seconds: float = 0.20
var visual_tween: Tween
var pose_owner: String = "Idle"
var reset_epoch: int = 0
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
	_resource = max_resource
	demo.motion_started.connect(_on_attack_started)
	demo.motion_ended.connect(_on_attack_ended)

func _on_attack_ended(_id: int, reason: String) -> void:
	if reason == "completed" and pose_owner == "Attack": pose_owner = "Idle"

func _on_attack_started(_id: int, _motion: int) -> void:
	claim_hand("Attack")

func claim_hand(owner: String) -> void:
	_stop_visual()
	if owner != "Matching":
		player.get_node("ContactMatchingDebug").active = false
	if owner != "Attack":
		demo.cancel_debug_motion("pose_handoff", true)
	pose_owner = owner

func finish_hand_return(tween: Tween) -> void:
	if visual_tween == tween and pose_owner in ["Return", "Guard Break", "Instinctive Return", "Dead Return"]:
		pose_owner = "Idle"

func _stop_visual() -> void:
	if visual_tween != null and visual_tween.is_valid():
		visual_tween.kill()

func _visual_transition(defending: bool) -> void:
	claim_hand("Guard" if defending else ("Dead Return" if health.dead else "Return"))
	visual_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if defending:
		if perfect_remaining > 0:
			visual_tween.tween_property(hand, "transform", demo._pose(parry_position, parry_rotation_degrees), 0.06)
		visual_tween.tween_property(hand, "transform", demo._pose(guard_position, guard_rotation_degrees), 0.09)
	else:
		visual_tween.tween_property(hand, "transform", demo._idle_guard(), return_seconds)
		visual_tween.finished.connect(finish_hand_return.bind(visual_tween))

func _physics_process(delta: float) -> void:
	_tick_resource(delta)
	_tick_instinctive(delta)
	perfect_remaining = maxf(0, perfect_remaining - delta)
	if is_zero_approx(perfect_remaining): perfect_remaining = 0
	refresh_input()

func is_guard_broken() -> bool:
	return guard_break_remaining > 0

func attack_allowed() -> bool:
	return not health.dead and not is_guard_broken() and instinctive_phase == "Idle" and not held and demo.lock_remaining <= 0

func defense_allowed() -> bool:
	return not health.dead and not is_guard_broken() and instinctive_phase == "Idle" and _resource > 0 and not require_release

func combat_state_name() -> String:
	return "Dead" if health.dead else ("Guard Break" if is_guard_broken() else ("Instinctive Defense" if instinctive_phase != "Idle" else "Normal"))

func matching_defense_active() -> bool:
	return not health.dead and not is_guard_broken() and (held or instinctive_phase == "Intercept")

func _tick_instinctive(delta: float) -> void:
	if instinctive_phase == "Idle": return
	instinctive_remaining = maxf(0, instinctive_remaining - delta)
	if instinctive_remaining > 0: return
	if instinctive_phase == "Raise":
		instinctive_phase = "Intercept"
		instinctive_remaining = instinctive_intercept_seconds
	elif instinctive_phase == "Intercept":
		player.get_node("ContactMatchingDebug").active = false
		claim_hand("Instinctive Return")
		var staggered := hand.transform
		staggered.origin += instinctive_stagger_offset
		staggered.basis *= Basis.from_euler(instinctive_stagger_rotation_degrees * PI / 180)
		instinctive_phase = "Stagger / Return"
		instinctive_remaining = instinctive_stagger_seconds + instinctive_return_seconds
		visual_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		visual_tween.tween_property(hand, "transform", staggered, instinctive_stagger_seconds)
		visual_tween.tween_property(hand, "transform", demo._idle_guard(), instinctive_return_seconds)
		visual_tween.finished.connect(finish_hand_return.bind(visual_tween))
	else:
		instinctive_phase = "Idle"

func _try_instinctive(frontal: bool, request_id: int, damage: float) -> bool:
	var epoch := reset_epoch
	last_instinctive_triggered = false
	last_instinctive_cost = 0
	if not instinctive_enabled: instinctive_reason = "Disabled"
	elif health.dead: instinctive_reason = "Dead"
	elif is_guard_broken(): instinctive_reason = "Guard Break"
	elif not frontal: instinctive_reason = "Outside front defense cone"
	elif _resource < maxf(1, instinctive_cost): instinctive_reason = "Insufficient resource for full payment"
	else:
		instinctive_request_id = request_id
		last_instinctive_triggered = true
		last_instinctive_cost = maxf(1, instinctive_cost)
		_resource = clampf(_resource - last_instinctive_cost, 0, max_resource)
		recovery_elapsed = 0
		last_result = "Instinctive Defense"
		last_prevented_damage = maxf(0, damage)
		instinctive_reason = "Actual valid body contact; full cost paid"
		instinctive_phase = "Raise" # Also blocks outgoing end-sample damage immediately.
		# Close the window before its end notification; preserve the ordinary no-buffer lock.
		demo.cancel_debug_motion("instinctive_defense", true)
		if epoch != reset_epoch: return false
		player.get_node("ContactMatchingDebug").debug_reset()
		claim_hand("Instinctive Raise")
		if _resource == 0:
			_enter_guard_break(request_id)
		else:
			instinctive_remaining = instinctive_raise_seconds
			visual_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			visual_tween.tween_property(hand, "transform", demo._pose(guard_position, guard_rotation_degrees), instinctive_raise_seconds).set_trans(Tween.TRANS_SINE)
			# Raise continuously into the existing safe guard envelope before bounded matching.
		return true
	return false

func _enter_guard_break(request_id: int) -> void:
	var epoch := reset_epoch
	instinctive_phase = "Idle"
	instinctive_remaining = 0
	guard_break_remaining = guard_break_seconds
	last_break_request_id = request_id
	recovery_elapsed = 0
	recovery_state = "Guard Break"
	held = false
	perfect_remaining = 0
	require_release = true
	player.get_node("ContactMatchingDebug").debug_reset()
	# Distinct from the ordinary no-buffer lock; never clear that lock here.
	demo.cancel_debug_motion("guard_break", true)
	if epoch != reset_epoch: return
	claim_hand("Guard Break")
	var deflected := hand.transform
	deflected.origin += break_position_offset
	deflected.basis = deflected.basis * Basis.from_euler(break_rotation_offset_degrees * PI / 180.0)
	visual_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	visual_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	visual_tween.tween_property(hand, "transform", deflected, break_deflect_seconds)
	visual_tween.tween_interval(break_hold_seconds)
	visual_tween.tween_property(hand, "transform", demo._idle_guard(), break_return_seconds)
	visual_tween.finished.connect(finish_hand_return.bind(visual_tween))

func _tick_resource(delta: float) -> void:
	if health.dead:
		recovery_state = "Dead"
		return
	if guard_break_remaining > 0:
		guard_break_remaining = maxf(0, guard_break_remaining - delta)
		if is_zero_approx(guard_break_remaining): guard_break_remaining = 0
		if guard_break_remaining == 0 and Input.is_action_pressed("active_defense"):
			require_release = true # A held/repressed button during break is not a new post-break press.
		recovery_elapsed = 0
		recovery_state = "Guard Break" if guard_break_remaining > 0 else "Waiting for release/delay"
		return # No recovery on the break-expiry tick.
	if Input.is_action_pressed("active_defense"):
		recovery_elapsed = 0
		recovery_state = "Paused: defense input held"
		return
	if _resource >= max_resource:
		recovery_elapsed = 0
		recovery_state = "Full"
		return
	var before := recovery_elapsed
	recovery_elapsed += delta
	var recover_delta := maxf(0, recovery_elapsed - maxf(before, recovery_delay_seconds))
	_resource = clampf(_resource + recover_delta * maxf(0, recovery_per_second), 0, max_resource)
	recovery_state = "Full" if _resource >= max_resource else ("Recovering" if recover_delta > 0 and recovery_per_second > 0 else "Delay")

func refresh_input() -> void:
	var pressed := Input.is_action_pressed("active_defense")
	if instinctive_phase != "Idle":
		held = false
		perfect_remaining = 0
		if pressed: require_release = true
		return
	if guard_break_remaining > 0 or _resource <= 0:
		if held: _visual_transition(false)
		held = false
		perfect_remaining = 0
		if not pressed: require_release = false
		return
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
		var epoch := reset_epoch
		held = true
		perfect_remaining = perfect_window_seconds
		# Close before end-record notification so its final sweep cannot deal damage.
		demo.cancel_debug_motion("defense", true)
		if epoch != reset_epoch: return
		_visual_transition(true)

func state_name() -> String:
	if instinctive_phase == "Intercept": return "Instinctive Defense"
	if not held:
		return "None"
	return "Perfect Parry" if perfect_remaining > 0 else "Held Guard"

func resolve_valid_contact(attacker: Node3D, damage: float, request_id: int = 0) -> bool:
	if health.dead: return false
	var epoch := reset_epoch
	if request_id > 0 and resolved_requests.has(request_id):
		return resolved_requests[request_id] # Never reconsider the exhausting hit after break.
	refresh_input()
	if epoch != reset_epoch: return false
	var offset := attacker.global_position - player.global_position
	offset.y = 0
	var forward := -player.global_basis.z
	forward.y = 0
	var frontal := offset.length_squared() > 0.000001 and forward.normalized().dot(offset.normalized()) >= cos(deg_to_rad(defense_half_angle_degrees))
	if held and frontal:
		last_instinctive_triggered = false
		last_instinctive_cost = 0
		instinctive_reason = "Active defense takes priority"
		last_result = "Perfect Parry" if perfect_remaining > 0 else "Block"
		last_prevented_damage = maxf(0, damage)
		last_resource_cost = 0
		if last_result == "Block":
			var before := _resource
			_resource = clampf(_resource - held_guard_cost, 0, max_resource)
			last_resource_cost = before - _resource
			if _resource <= 0:
				_enter_guard_break(request_id)
		if epoch != reset_epoch: return false
		if request_id > 0: resolved_requests[request_id] = true
		return true
	var automatic := _try_instinctive(frontal, request_id, damage)
	if epoch != reset_epoch: return false
	if automatic:
		if request_id > 0: resolved_requests[request_id] = true
		return true
	last_result = "Failed"
	last_prevented_damage = 0
	if request_id > 0: resolved_requests[request_id] = false
	return false

func debug_reset_defense(clear_records: bool = true) -> void:
	if clear_records: reset_epoch += 1
	player.get_node("ContactMatchingDebug").debug_reset()
	instinctive_phase = "Idle"
	instinctive_remaining = 0
	if is_instance_valid(hand):
		if clear_records:
			_stop_visual()
			hand.transform = demo._idle_guard() # Debug reset, not a gameplay transition.
			pose_owner = "Idle"
		else:
			_visual_transition(false)
	held = false
	perfect_remaining = 0
	if clear_records:
		last_result = "None"
		last_prevented_damage = 0
		_resource = max_resource
		last_resource_cost = 0
		guard_break_remaining = 0
		recovery_elapsed = 0
		recovery_state = "Full"
		resolved_requests.clear()
		last_break_request_id = 0
		instinctive_request_id = 0
		last_instinctive_triggered = false
		last_instinctive_cost = 0
		instinctive_reason = "No valid contact"
	require_release = Input.is_action_pressed("active_defense")
