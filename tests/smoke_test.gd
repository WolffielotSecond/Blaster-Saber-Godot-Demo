extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var arena: Node3D
var player: CharacterBody3D
var enemy: CharacterBody3D
var rig: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func ticks(count: int) -> void:
	for _tick in count:
		await physics_frame
		await process_frame

func reset_player() -> void:
	player.position = Vector3(0, 0.01, 1.5)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.is_running = false
	rig.target_yaw = 0.0
	rig.target_pitch = 0.0
	rig.rotation = Vector3.ZERO
	rig.get_node("PitchPivot").rotation = Vector3.ZERO

func timed_pose(pose: Dictionary, time: float, window: Vector2, live: bool = true) -> Dictionary:
	var sample := pose.duplicate(true)
	sample.merge({"frame": Engine.get_physics_frames(), "playback_time": time,
		"window_start": window.x, "window_end": window.y, "window_live": live,
		"window_active": live and time >= window.x and time < window.y})
	return sample

func blade_pose(base: Vector3, tip: Vector3) -> Dictionary:
	return {"base": base, "tip": tip, "rotation": Quaternion(Vector3.UP, (tip - base).normalized())}

func verify() -> void:
	root.size = Vector2i(1152, 648)
	var packed := load("res://scenes/test_arena.tscn") as PackedScene
	check(packed != null, "Arena loads")
	if packed == null:
		quit(1)
		return
	arena = packed.instantiate()
	root.add_child(arena)
	current_scene = arena
	# Isolate the historical 254 checks from the newly authorized periodic attacker.
	var enemy_attack: Node3D = arena.get_node("Enemy/DebugAttack")
	enemy_attack.enabled = false
	check(arena.get_node("Enemy/DebugDefense").auto_defense_enabled, "Scene enables reactive enemy defense by default")
	arena.get_node("Enemy/DebugDefense").auto_defense_enabled = false # Isolate the prior 815 checks; Step 17 enables below.
	check(arena.get_node("Enemy/DebugDefense").base_mistake_chance == 0.10 and arena.get_node("Enemy/DebugDefense").mistake_increase_per_pressure == 0.05 and arena.get_node("Enemy/DebugDefense").max_mistake_chance == 0.60 and arena.get_node("Enemy/DebugDefense").breathing_duration == 1.0, "Enemy pressure/mistake defaults are 10% +5pp capped at60%, breathing1s")
	arena.get_node("Enemy/DebugDefense").base_mistake_chance = 0 # Isolate prior 864 deterministic fixtures.
	arena.get_node("Enemy/DebugDefense").mistake_increase_per_pressure = 0
	var matching: Node = arena.get_node("Player/ContactMatchingDebug")
	matching.enabled = false # Preserve the previous 345-check baseline; enable below.
	player = arena.get_node("Player")
	player.get_node("DebugDefense").instinctive_enabled = false # Preserve all 487 historical fixtures.
	check(is_equal_approx(player.get_node("DebugDefense").held_guard_cost, 10) and is_equal_approx(player.get_node("DebugDefense").resource, 100), "Current defense resource defaults to 100 and block cost 10")
	player.get_node("DebugDefense").held_guard_cost = 0 # Preserve historical resource-free fixtures.
	check(is_equal_approx(player.get_node("DebugPlayerHealth").incoming_test_damage, 5), "Current enemy damage default is 5 HP")
	player.get_node("DebugPlayerHealth").incoming_test_damage = 25 # Historical damage fixture.
	enemy_attack.sequence_length = 1 # Historical single-attack rhythm fixture.
	enemy = arena.get_node("Enemy")
	rig = arena.get_node("ThirdPersonRig")
	check(rig.initial_auto_acquisition_enabled, "Scene enables initial automatic acquisition by default")
	rig.initial_auto_acquisition_enabled = false # Preserve prior 689 fixtures; new Step 15 cases enable below.
	camera = rig.get_node("PitchPivot/SpringArm3D/Camera3D")
	var enemy_start := enemy.global_transform
	await ticks(30)
	var health: Node = enemy.get_node("DebugHealth")
	check(is_equal_approx(health.max_hp, 100.0) and is_equal_approx(health.hp, 100.0) and not health.dead, "Enemy starts alive at temporary 100 HP maximum")
	check(is_equal_approx(health.test_damage, 10.0), "All motions share temporary 10 HP damage")
	health.test_damage = 25 # Preserve historical fixtures; Step 14 checks restore current 10.
	check(not player.has_node("DebugHealth"), "Enemy DebugHealth node remains enemy-only")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/test_arena.tscn", "Main scene assigned")
	check(player.get_script() != null and enemy.get_script() == null, "Only player controlled")
	check(player.is_on_floor() and absf(player.position.y) < 0.02, "Gravity settles player on ground")
	check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE and root.get_camera_3d() == camera, "Active perspective camera")
	check(is_equal_approx(rig.rear_distance, 2.5) and is_equal_approx(rig.right_offset, 1.0) and is_equal_approx(rig.observation_height, 1.55), "Default shoulder parameters")
	var offset: Vector3 = camera.global_position - (player.global_position + Vector3.UP * rig.observation_height)
	check(offset.x > 0.9 and offset.x < 1.1 and offset.z > 2.3 and offset.z < 2.6 and absf(offset.y) < 0.02, "Initial camera about 1 m right and 2.5 m behind")
	check(camera.unproject_position(player.global_position + Vector3.UP * 1.55).x < root.size.x / 2.0, "Neck projects left of screen center")
	check(camera.is_position_in_frustum(enemy.global_position + Vector3.UP * 0.85), "Initial enemy body center visible to camera")
	for action in ["move_left", "move_right", "move_forward", "move_back", "toggle_run", "look_left", "look_right", "look_up", "look_down", "capture_mouse", "release_mouse"]:
		check(InputMap.has_action(action), "Mapped action: " + action)
	var shift := InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	check(InputMap.event_is_action(shift, "toggle_run"), "Shift toggles run")
	var l3 := InputEventJoypadButton.new()
	l3.device = 0
	l3.button_index = JOY_BUTTON_LEFT_STICK
	check(InputMap.event_is_action(l3, "toggle_run"), "L3 toggles run")
	for binding in [[KEY_W, "move_forward"], [KEY_A, "move_left"], [KEY_S, "move_back"], [KEY_D, "move_right"]]:
		var event := InputEventKey.new()
		event.physical_keycode = binding[0]
		check(InputMap.event_is_action(event, binding[1]), "WASD mapping: " + str(binding[1]))
	for binding in [[JOY_AXIS_LEFT_X, -1.0, "move_left"], [JOY_AXIS_LEFT_Y, -1.0, "move_forward"], [JOY_AXIS_RIGHT_X, 1.0, "look_right"], [JOY_AXIS_RIGHT_Y, -1.0, "look_up"]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = binding[0]
		event.axis_value = binding[1]
		check(InputMap.event_is_action(event, binding[2]), "Stick mapping: " + str(binding[2]))
	for forbidden in ["melee", "shoot", "dodge", "jump", "force_block", "blade_toggle"]:
		check(not InputMap.has_action(forbidden), "No combat/jump mapping: " + forbidden)
	var start := player.position
	Input.action_press("move_forward")
	await ticks(60)
	Input.action_release("move_forward")
	check(absf((start.z - player.position.z) - 2.0) < 0.06, "Walking about 2 m/s")
	check(player.is_on_floor() and absf(player.position.y) < 0.02, "Walking remains grounded")
	reset_player()
	await ticks(30)
	Input.action_press("toggle_run")
	await ticks(1)
	Input.action_release("toggle_run")
	check(player.is_running, "Run toggles on")
	start = player.position
	Input.action_press("move_right")
	await ticks(60)
	Input.action_release("move_right")
	check(absf((player.position.x - start.x) - 3.5) < 0.08, "Running about 3.5 m/s")
	check((-player.global_basis.z).dot(Vector3.RIGHT) > 0.99, "Turns toward actual rightward motion")
	await ticks(60)
	check(rig.global_position.distance_to(player.global_position + Vector3.UP * 1.55) < 0.01, "Follow catches up while idle")
	Input.action_press("toggle_run")
	await ticks(1)
	Input.action_release("toggle_run")
	check(not player.is_running, "Run toggles back to walk")
	reset_player()
	rig.target_yaw = PI / 2.0
	await ticks(60)
	start = player.position
	Input.action_press("move_forward")
	await ticks(30)
	Input.action_release("move_forward")
	check(player.position.x < start.x - 0.45 and absf(player.position.z - start.z) < 0.05, "Forward movement follows rotated camera")
	reset_player()
	await ticks(60)
	Input.action_press("move_forward")
	await ticks(240)
	Input.action_release("move_forward")
	check(player.position.z > enemy.position.z + 0.48 and player.position.z < enemy.position.z + 0.6, "Player stops at static enemy collision")
	check(enemy.global_transform.is_equal_approx(enemy_start), "Enemy stays static")
	reset_player()
	await ticks(60)
	var yaw_before: float = rig.target_yaw
	Input.action_press("look_right")
	await ticks(15)
	Input.action_release("look_right")
	check(rig.target_yaw < yaw_before - 0.4, "Right-stick look changes yaw")
	Input.action_press("look_up")
	await ticks(120)
	Input.action_release("look_up")
	check(is_equal_approx(rig.target_pitch, deg_to_rad(rig.max_pitch_degrees)), "Up look clamps pitch")
	Input.action_press("look_down")
	await ticks(120)
	Input.action_release("look_down")
	check(is_equal_approx(rig.target_pitch, deg_to_rad(rig.min_pitch_degrees)), "Down look clamps pitch")
	# Dummy headless display cannot capture a native pointer: verify mapping/math only.
	yaw_before = rig.target_yaw
	rig._apply_mouse_look(Vector2(100, -20))
	check(absf(wrapf(rig.target_yaw - yaw_before, -PI, PI) + deg_to_rad(12.0)) < 0.001, "Mouse sensitivity/yaw")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	check(InputMap.event_is_action(escape, "release_mouse"), "Esc release mapping")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	check(InputMap.event_is_action(click, "capture_mouse"), "Click capture mapping")
	reset_player()
	rig.right_offset = 0.0
	await ticks(60)
	var arm: SpringArm3D = rig.get_node("PitchPivot/SpringArm3D")
	check(arm.get_hit_length() > 2.3, "Spring arm excludes own collider even with centered offset")
	rig.right_offset = 1.0
	await ticks(30)
	player.rotation.y = PI
	await ticks(5)
	offset = rig.global_basis.inverse() * (camera.global_position - rig.global_position)
	check(offset.x > 0.9, "Body turn does not flip shoulder")
	# An isolated test wall intersects the diagonal sweep, without altering the arena file.
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.2)
	collider.shape = box
	wall.add_child(collider)
	arena.add_child(wall)
	wall.global_position = rig.global_position + Vector3(0, 0, 1.3)
	await ticks(10)
	check(arm.get_hit_length() < 2.0, "Spring arm retracts for obstruction")
	wall.queue_free()
	await ticks(10)
	check(arm.get_hit_length() > 2.5, "Spring arm restores distance after obstruction removed")
	reset_player()
	await ticks(60)
	var demo: Node3D = player.get_node("WeaponMotionDemo")
	var hand: Node3D = player.get_node("VisualRoot/RightHand")
	var weapon: Node3D = hand.get_node("Gunblade")
	var root_before := player.transform
	var collision_before: Transform3D = player.get_node("CollisionShape3D").transform
	var left_before: Transform3D = player.get_node("VisualRoot/LeftHand").transform
	var idle := hand.transform
	check(is_equal_approx(player.walk_speed, 2.0) and is_equal_approx(player.run_speed, 3.5), "Accepted movement baseline preserved")
	check(not enemy.has_node("WeaponMotionDemo"), "Enemy has no weapon motion driver")
	for action in ["demo_select_thrust", "demo_select_short_cut", "demo_select_broad_cut", "demo_motion_request"]:
		check(InputMap.has_action(action), "Temporary motion action: " + action)
	var square := InputEventJoypadButton.new()
	square.button_index = JOY_BUTTON_X
	check(InputMap.event_is_action(square, "ordinary_motion_request") and not InputMap.event_is_action(square, "demo_motion_request"), "Square/X maps exclusively to ordinary request")
	var action_peaks: Array[float] = []
	for motion_id in [0, 1, 2]:
		demo.request_motion(motion_id)
		var previous := hand.transform
		var peak := 0.0
		var max_step := 0.0
		var max_angle := 0.0
		var stays_attached := true
		var thrust_reached := false
		for _frame in 60:
			await ticks(1)
			peak = maxf(peak, hand.position.distance_to(idle.origin))
			max_step = maxf(max_step, hand.position.distance_to(previous.origin))
			max_angle = maxf(max_angle, hand.basis.get_rotation_quaternion().angle_to(previous.basis.get_rotation_quaternion()))
			stays_attached = stays_attached and weapon.global_position.distance_to(hand.global_position) < 0.0001
			thrust_reached = thrust_reached or hand.position.z < -0.65
			previous = hand.transform
		action_peaks.append(peak)
		check(peak > 0.2, "Motion changes grip position: " + str(motion_id))
		check(max_step < 0.18 and max_angle < 0.65, "No abrupt pose step in sampled motion: " + str(motion_id))
		check(stays_attached and weapon.transform.is_equal_approx(Transform3D.IDENTITY), "Grip stays attached: " + str(motion_id))
		check(hand.transform.is_equal_approx(idle), "Returns smoothly to idle: " + str(motion_id))
		check(player.transform.is_equal_approx(root_before) and player.get_node("CollisionShape3D").transform.is_equal_approx(collision_before), "No root/collision motion: " + str(motion_id))
		if motion_id == 0:
			check(thrust_reached, "Thrust reaches forward extension")
	check(action_peaks[2] > action_peaks[1], "Broad cut has greater grip excursion than short cut")
	check(player.get_node("VisualRoot/LeftHand").transform.is_equal_approx(left_before), "Left hand unchanged")
	demo.request_motion(2)
	await ticks(19)
	var interrupted_pose := hand.transform
	check(demo.request_motion(0), "Request accepted after action lock window")
	check(hand.transform.is_equal_approx(interrupted_pose), "New request starts at current pose without snapping")
	await ticks(60)
	check(hand.transform.is_equal_approx(idle), "Interrupted transition still returns to idle")
	Input.action_press("demo_select_short_cut")
	await ticks(1)
	Input.action_release("demo_select_short_cut")
	check(demo.selected_motion == 1, "Debug selector picks short cut")
	Input.action_press("demo_motion_request")
	Input.action_press("move_left")
	var moving_start := player.position
	await ticks(30)
	Input.action_release("demo_motion_request")
	Input.action_release("move_left")
	await ticks(40)
	check(player.position.x < moving_start.x - 0.8, "Motion demo does not block movement")
	check(hand.transform.is_equal_approx(idle), "Holding request does not repeat demo")
	check(enemy.global_transform.is_equal_approx(enemy_start), "Enemy remains static throughout demo")

	reset_player()
	await ticks(60)
	root_before = player.transform
	var normal_click := InputEventMouseButton.new()
	normal_click.button_index = MOUSE_BUTTON_LEFT
	normal_click.pressed = true
	check(InputMap.event_is_action(normal_click, "ordinary_motion_request") and not InputMap.event_is_action(normal_click, "demo_motion_request"), "Left click does not map to forced debug request")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var accepted_before: int = demo.accepted_request_count
	demo._unhandled_input(normal_click)
	check(demo.accepted_request_count == accepted_before, "Uncaptured click cannot attack")
	enemy.position = player.position + Vector3.FORWARD
	check(demo.choose_motion() == 0, "Close frontal reference selects thrust without manual selection")
	var pose_before := hand.transform
	check(demo.request_ordinary_motion(), "Ordinary request accepted")
	check(demo.last_motion == 0 and hand.transform.is_equal_approx(pose_before), "Ordinary request shares continuous executor")
	accepted_before = demo.accepted_request_count
	var rejected := true
	for _press in 20:
		rejected = rejected and not demo.request_ordinary_motion() and not demo.request_motion(2)
	check(rejected and demo.accepted_request_count == accepted_before, "Rapid ordinary/debug requests ignored during lock")
	await ticks(8)
	check(not demo.request_ordinary_motion(), "Partial lock duration still rejects")
	await ticks(60)
	check(demo.accepted_request_count == accepted_before and hand.transform.is_equal_approx(idle), "Ignored presses are never buffered or replayed")
	check(player.transform.is_equal_approx(root_before), "Selection/request never moves or turns actor")
	enemy.position = player.position + Vector3.FORWARD * 2.2
	check(demo.choose_motion() == 2, "Medium frontal reference selects broad cut")
	demo.request_ordinary_motion()
	await ticks(19)
	pose_before = hand.transform
	check(demo.choose_motion() == 1, "Active broad cut selects short cut for same medium context")
	check(demo.request_ordinary_motion() and hand.transform.is_equal_approx(pose_before), "Post-lock ordinary request transitions from current pose")
	await ticks(60)
	enemy.position = player.position + Vector3.RIGHT
	check(demo.choose_motion() == 1, "Off-axis reference selects short cut")
	enemy.position = player.position + Vector3.FORWARD * 4.0
	check(demo.choose_motion() == 1, "Far reference selects empty-space short cut")
	demo.reference_target = null
	check(demo.choose_motion() == 1, "No reference selects short-cut fallback")
	demo.reference_target = enemy
	enemy.global_transform = enemy_start
	await ticks(2)
	square.pressed = true
	accepted_before = demo.accepted_request_count
	demo._unhandled_input(square)
	await ticks(60)
	check(demo.accepted_request_count == accepted_before + 1, "One ordinary event creates one request; holding does not repeat")
	check(player.transform.is_equal_approx(root_before) and enemy.global_transform.is_equal_approx(enemy_start), "Geometry selection adds no actor tracking or enemy behavior")

	var trajectory: Node3D = arena.get_node("WeaponTrajectoryDebug")
	check(not trajectory.debug_display_enabled and not trajectory.lines.visible and not trajectory.legend.visible, "Trajectory display defaults off")
	var f4 := InputEventKey.new()
	f4.physical_keycode = KEY_F4
	check(InputMap.event_is_action(f4, "toggle_weapon_trajectory_debug"), "F4 debug toggle mapping")
	var world_pose: Dictionary = trajectory.sample_world_pose()
	check(world_pose["grip"].is_equal_approx(weapon.get_node("Grip").global_position), "Grip sampled from actual Marker3D")
	check(world_pose["tip"].is_equal_approx(weapon.get_node("BladeTip").global_position) and world_pose["base"].is_equal_approx(weapon.get_node("BladeBase").global_position), "Blade endpoints sampled from actual markers")
	check(world_pose["direction"].is_equal_approx(weapon.global_basis.y.normalized()), "Blade direction follows weapon rather than actor forward")
	check(is_equal_approx(world_pose["base"].distance_to(world_pose["tip"]), 1.0), "World-space blade span preserves length")
	var independent_ids: Array[int] = []
	for motion_id in [0, 1, 2]:
		demo.request_motion(motion_id)
		await ticks(60)
		var record: Dictionary = trajectory.records.back()
		independent_ids.append(record["id"])
		var samples: Array = record["samples"]
		check(record["motion"] == motion_id and record["status"] == "completed", "Motion has independent completed trajectory: " + str(motion_id))
		check(samples.size() > 10 and samples.front()["kind"] == "start" and samples.back()["kind"] == "end", "Explicit start/end samples: " + str(motion_id))
		check(record["jump_samples"].is_empty() and record["max_step"] < trajectory.jump_warning_distance, "No abnormal sampled jump: " + str(motion_id))
		check(samples.back()["tip"].is_equal_approx(weapon.get_node("BladeTip").global_position), "Final sample matches real returned pose: " + str(motion_id))
	check(independent_ids[0] < independent_ids[1] and independent_ids[1] < independent_ids[2], "Trajectory IDs uniquely identify requests")
	demo.request_motion(2)
	await ticks(19)
	var interrupted_id: int = demo.active_request_id
	var record_count: int = trajectory.records.size()
	demo.request_motion(0)
	var interrupted: Dictionary = trajectory.records[-2]
	var replacement: Dictionary = trajectory.records.back()
	check(interrupted["id"] == interrupted_id and interrupted["status"] == "interrupted", "Interrupted record closes with explicit reason")
	check(interrupted["samples"].back()["tip"].is_equal_approx(replacement["samples"].front()["tip"]), "Interrupt/end and replacement/start share the same actual tip position")
	check(not demo.request_motion(1) and trajectory.records.size() == mini(record_count + 1, trajectory.retained_requests), "Rejected request creates no trajectory")
	await ticks(60)
	Input.action_press("toggle_weapon_trajectory_debug")
	await ticks(1)
	Input.action_release("toggle_weapon_trajectory_debug")
	check(trajectory.debug_display_enabled and trajectory.lines.visible and trajectory.legend.visible, "Debug mesh and legend toggle on")
	check(trajectory.line_mesh.get_surface_count() == 1, "ImmediateMesh line geometry generated")
	check(trajectory.lines.top_level and trajectory.lines.global_transform.is_equal_approx(Transform3D.IDENTITY), "World samples render without inheriting actor motion")
	Input.action_press("toggle_weapon_trajectory_debug")
	await ticks(1)
	Input.action_release("toggle_weapon_trajectory_debug")
	check(not trajectory.lines.visible and not trajectory.legend.visible, "Debug drawing and overlay toggle off")
	reset_player()
	await ticks(60)
	# Same requested animation, with actor movement/turning contributing to world positions.
	demo.request_motion(0)
	await ticks(60)
	var standing: Array = trajectory.records.back()["samples"].duplicate(true)
	var move_origin := player.global_position
	Input.action_press("move_left")
	demo.request_motion(0)
	for _frame in 90:
		await ticks(1)
		if demo.active_request_id == 0:
			break
	Input.action_release("move_left")
	var moving: Dictionary = trajectory.records.back()
	var actual_marker: Vector3 = weapon.get_node("BladeTip").global_position
	check(moving["status"] == "completed" and moving["samples"].back()["tip"].is_equal_approx(actual_marker), "Moving trajectory ends at actual world-space tip")
	var displacement := player.global_position - move_origin
	check(displacement.x < -1.0 and moving["samples"].back()["grip"].x < standing.back()["grip"].x - 1.0, "World trajectory includes player translation and rotation")
	check(not trajectory.lines.visible and moving["samples"].size() > 10, "Recording continues while debug display off")
	check(trajectory.records.size() <= trajectory.retained_requests, "Recent trajectory history bounded")
	check(is_equal_approx(player.walk_speed, 2.0) and is_equal_approx(player.run_speed, 3.5), "Trajectory debug preserves accepted movement speeds")

	var detector: Node3D = arena.get_node("WeaponContactDebug")
	var contact_region: Area3D = enemy.get_node("DebugContactRegion")
	check(contact_region.collision_layer == 2 and contact_region.collision_mask == 0, "Contact area isolated from movement physics")
	check(contact_region.get_node("CollisionShape3D").shape is CylinderShape3D, "Enemy contact region is a cylinder")
	reset_player()
	await ticks(60)
	var touches: Array[int] = []
	for motion_id in [0, 1, 2]:
		enemy.position = player.position + Vector3(0.38, 0, -0.9)
		await ticks(2)
		var before_events: int = detector.events.size()
		demo.request_motion(motion_id)
		var request_id: int = demo.active_request_id
		await ticks(60)
		var request_events: Array = detector.events.filter(func(event: Dictionary) -> bool: return event["request_id"] == request_id)
		check(request_events.size() == 1 and detector.events.size() == before_events + 1, "Exactly one real contact for motion " + str(motion_id))
		if not request_events.is_empty():
			var event: Dictionary = request_events[0]
			check(event["motion"] == motion_id and event["target"] == enemy and event["physics_frame"] > 0 and event["position"] is Vector3, "Contact includes request/motion/target/world point/frame")
			check(trajectory.records.back().has("contact"), "Trajectory record associates contact with request")
			touches.append(request_id)
	check(touches.size() == 3, "New requests can contact the same target again")
	enemy.position = Vector3(4, 0, -4)
	await ticks(2)
	var before_events: int = detector.events.size()
	demo.request_motion(0)
	await ticks(60)
	check(detector.events.size() == before_events and not trajectory.records.back().has("contact"), "A real miss creates no event")
	# Endpoint poses miss, but the space between them crosses the real enemy area.
	enemy.position = Vector3(0, 0, -1)
	await ticks(2)
	var sweep_start := {"base": Vector3(-1, 0.4, -1), "tip": Vector3(-1, 1.4, -1)}
	var sweep_end := {"base": Vector3(1, 0.4, -1), "tip": Vector3(1, 1.4, -1)}
	check(detector.sweep_blade(sweep_start, sweep_start).is_empty() and detector.sweep_blade(sweep_end, sweep_end).is_empty(), "Fast sweep endpoints individually miss")
	check(not detector.sweep_blade(sweep_start, sweep_end).is_empty(), "Between-frame sweep catches target crossing")
	var near_miss_start := {"base": Vector3(-1, 0.4, -0.6), "tip": Vector3(-1, 1.4, -0.6)}
	var near_miss_end := {"base": Vector3(1, 0.4, -0.6), "tip": Vector3(1, 1.4, -0.6)}
	check(detector.sweep_blade(near_miss_start, near_miss_end).is_empty(), "Geometric near miss does not create contact")
	enemy.position = Vector3(0, 0, -0.85)
	await ticks(2)
	var rotating_start := {"base": Vector3(0, 0.4, 0), "tip": Vector3(-0.8660254, 0.4, -0.5)}
	var rotating_end := {"base": Vector3(0, 0.4, 0), "tip": Vector3(0.8660254, 0.4, -0.5)}
	check(detector.sweep_blade(rotating_start, rotating_start).is_empty() and detector.sweep_blade(rotating_end, rotating_end).is_empty(), "Fast rotational sweep endpoint blades miss")
	check(not detector.sweep_blade(rotating_start, rotating_end).is_empty(), "Adaptive rotational sweep catches intermediate contact")
	enemy.position = Vector3(0, 0, -1)
	await ticks(2)
	var above := {"base": Vector3(0, 2, -1), "tip": Vector3(0, 3, -1)}
	check(detector.sweep_blade(above, above).is_empty(), "Cylinder height respected")
	var self_pose := {"base": player.position + Vector3.UP * 0.4, "tip": player.position + Vector3.UP * 1.4}
	check(detector.sweep_blade(self_pose, self_pose).is_empty(), "Own collider excluded by area-only query")
	enemy.position = Vector3(3, 0, 2)
	enemy.rotation.y = 0.7
	await ticks(2)
	var relocated := {"base": Vector3(3, 0.4, 2), "tip": Vector3(3, 1.4, 2)}
	check(not detector.sweep_blade(relocated, relocated).is_empty() and detector.sweep_blade(sweep_start, sweep_end).is_empty(), "Contact region follows actual enemy transform")
	reset_player()
	await ticks(60)
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	await ticks(2)
	trajectory.debug_display_enabled = true
	Input.action_press("move_forward")
	demo.request_motion(0)
	var moving_contact_id: int = demo.active_request_id
	await ticks(15)
	Input.action_release("move_forward")
	var moving_events: Array = detector.events.filter(func(event: Dictionary) -> bool: return event["request_id"] == moving_contact_id)
	check(moving_events.size() == 1, "Moving thrust produces first-contact event")
	check(not trajectory.contact_markers.is_empty() and trajectory.legend.text.contains("DETECTED"), "F4 display includes contact marker and status")
	trajectory.debug_display_enabled = false
	check(not trajectory.lines.visible and not trajectory.legend.visible, "Hidden debug has no visible contact marker or legend")
	await ticks(90)
	check(trajectory.contact_markers.is_empty(), "Contact markers expire without visual effects")
	check(detector.oversized_segments == 0, "Normal motions do not exceed sweep subdivision cap")

	# Active-frame regression: actual unchanged animations and their Tween timeline.
	reset_player()
	await ticks(60)
	for motion_id in [0, 1, 2]:
		enemy.position = player.position + Vector3(0.38, 0, -0.9)
		await ticks(2)
		demo.request_motion(motion_id)
		var request_id: int = demo.active_request_id
		var state: Dictionary = demo.playback_state()
		var expected: Vector2 = [Vector2(0.12, 0.26), Vector2(0.10, 0.24), Vector2(0.18, 0.52)][motion_id]
		check(is_equal_approx(state["window_start"], expected.x) and is_equal_approx(state["window_end"], expected.y), "Independent Inspector window: " + str(motion_id))
		check(not state["window_active"], "Preparation begins outside active window")
		await ticks(13 if motion_id == 2 else 10)
		state = demo.playback_state()
		check(is_equal_approx(state["playback_time"], demo.motion_tween.get_total_elapsed_time()), "Window time follows actual Tween")
		check(state["window_active"], "Strike is active: " + str(motion_id))
		await ticks(60)
		var valid_hits: Array = detector.valid_events.filter(func(event: Dictionary) -> bool: return event["request_id"] == request_id)
		check(valid_hits.size() == 1, "One valid real contact for motion " + str(motion_id))
		if not valid_hits.is_empty():
			var event: Dictionary = valid_hits[0]
			check(event["contact_kind"] == "valid_attack" and event["target"] == enemy and event["position"] is Vector3 and event["physics_frame"] > 0 and event["motion"] == motion_id, "Valid event carries spatial/request identity")
			check(event["playback_time"] >= expected.x and event["playback_time"] < expected.y, "Valid event occurs within its own window")
		check(demo.active_request_id == 0 and not demo.playback_state()["window_active"], "Completion closes active window")
		check(trajectory.records.back().has("valid_contact"), "Valid event associated with its own trajectory")
		var samples: Array = trajectory.records.back()["samples"]
		check(samples.back()["playback_time"] >= expected.y and not samples.back()["window_live"], "End sample preserves elapsed time and closed state")
		check(samples.any(func(sample: Dictionary) -> bool: return sample["playback_time"] > expected.y and not sample["window_active"]), "Return samples stay inactive")

	demo.request_motion(2)
	await ticks(19)
	check(demo.playback_state()["window_active"], "Broad cut is active immediately before permitted interruption")
	demo.request_motion(0)
	check(not trajectory.records[-2]["samples"].back()["window_live"] and trajectory.records[-2]["status"] == "interrupted", "Interrupted old request closes immediately")
	check(not demo.playback_state()["window_active"] and is_zero_approx(demo.playback_state()["playback_time"]), "Replacement starts a fresh inactive timeline")
	await ticks(60)

	# Synthetic frame spans query the real cylinder, including window crossings.
	enemy.position = Vector3(0, 0, -1)
	await ticks(2)
	var middle := {"base": Vector3(0, 0.4, -1), "tip": Vector3(0, 1.4, -1)}
	var window := Vector2(0.2, 0.4)
	var physical_before: int = detector.events.size()
	var valid_before: int = detector.valid_events.size()
	detector._on_sample(100001, 0, timed_pose(middle, 0.0, window))
	check(detector.events.size() == physical_before + 1 and detector.valid_events.size() == valid_before, "Preparation overlap records physical only")
	detector._on_sample(100001, 0, timed_pose(middle, 0.25, window))
	check(detector.valid_events.size() == valid_before + 1, "Outside contact does not consume later valid opportunity")
	detector._on_sample(100001, 0, timed_pose(middle, 0.30, window))
	check(detector.valid_events.size() == valid_before + 1 and detector.events.size() == physical_before + 1, "Physical and valid contacts independently deduplicate")
	detector._on_sample(100002, 1, timed_pose(middle, 0.25, window))
	check(detector.valid_events.size() == valid_before + 2, "Next request may validly contact same target")
	valid_before = detector.valid_events.size()
	detector._on_sample(100003, 2, timed_pose(middle, 0.5, window))
	check(detector.valid_events.size() == valid_before, "Return-phase overlap is physical only")
	check(detector.sweep_active_interval(timed_pose(sweep_start, 0, Vector2(0.8, 1.0)), timed_pose(sweep_end, 1, Vector2(0.8, 1.0))).is_empty(), "Pre-window crossing excluded from mixed frame")
	check(detector.sweep_active_interval(timed_pose(sweep_start, 0, Vector2(0.0, 0.2)), timed_pose(sweep_end, 1, Vector2(0.0, 0.2))).is_empty(), "Post-window crossing excluded from mixed frame")
	check(not detector.sweep_active_interval(timed_pose(sweep_start, 0, Vector2(0.4, 0.6)), timed_pose(sweep_end, 1, Vector2(0.4, 0.6))).is_empty(), "Window-clipped fast sweep detects real intermediate contact")
	check(detector.sweep_active_interval(timed_pose(middle, window.y, window), timed_pose(middle, window.y, window)).is_empty(), "Window end is exclusive")
	check(detector.sweep_active_interval(timed_pose(middle, 0.25, window, false), timed_pose(middle, 0.30, window, false)).is_empty(), "Closed request cannot continue generating valid contacts")
	check(not detector.sweep_active_interval(timed_pose(middle, 0.25, window), timed_pose(middle, 0.30, window, false)).is_empty(), "End sample retains legitimate final preceding interval")
	check(detector.sweep_active_interval(timed_pose(near_miss_start, 0, Vector2(0.4, 0.6)), timed_pose(near_miss_end, 1, Vector2(0.4, 0.6))).is_empty(), "Active window cannot turn spatial miss into hit")
	demo.thrust_active_window = Vector2(0.15, 0.21)
	demo.request_motion(0)
	check(is_equal_approx(demo.playback_state()["window_start"], 0.15) and is_equal_approx(demo.playback_state()["window_end"], 0.21), "Inspector can narrow actual attack interval")
	demo.thrust_active_window = Vector2(-1, 5)
	check(is_equal_approx(demo.playback_state()["window_start"], 0.12) and is_equal_approx(demo.playback_state()["window_end"], 0.26), "Inspector bounds cannot activate preparation or return")
	demo.thrust_active_window = Vector2(0.23, 0.15)
	check(is_equal_approx(demo.playback_state()["window_start"], demo.playback_state()["window_end"]) and not demo.playback_state()["window_active"], "Reversed configured interval safely disables validity")
	demo.thrust_active_window = Vector2(0.12, 0.26)
	await ticks(60)

	trajectory.debug_display_enabled = true
	demo.request_motion(0)
	await ticks(10)
	check(trajectory.legend.text.contains("ACTIVE (lime blade)") and trajectory.legend.text.contains("Physical Contact") and trajectory.legend.text.contains("Valid Attack Contact"), "F4 exposes active state and separate contact categories")
	await ticks(60)
	check(trajectory.legend.text.contains("CLOSED") and trajectory.legend.text.contains("Windows (seconds)"), "F4 exposes closure and all three configured windows")
	trajectory.debug_display_enabled = false
	check(not trajectory.lines.visible and not trajectory.legend.visible, "F4 off hides new active-window diagnostics")
	await ticks(90)
	check(trajectory.contact_markers.is_empty(), "Both contact marker categories expire")

	# Minimal damage integration: physics-generated events, never a distance/time shortcut.
	health.debug_reset_hp()
	enemy.position = Vector3(0, 0, -1)
	await ticks(2)
	trajectory.debug_display_enabled = false
	detector._on_sample(900001, 0, timed_pose(middle, 0.0, window))
	check(is_equal_approx(health.hp, 100.0), "Outside-window physical overlap causes no damage")
	detector._on_sample(900001, 0, timed_pose(middle, 0.25, window))
	check(is_equal_approx(health.hp, 75.0) and is_equal_approx(health.last_damage, 25.0), "Real valid contact signal applies damage with F4 hidden")
	var damage_event: Dictionary = detector.valid_events.back().duplicate()
	health._on_valid_contact(damage_event)
	detector._on_sample(900001, 0, timed_pose(middle, 0.30, window))
	check(is_equal_approx(health.hp, 75.0), "Repeated valid signal and continuing overlap cannot double-damage request")
	detector._on_sample(900002, 1, timed_pose(middle, 0.25, window))
	check(is_equal_approx(health.hp, 50.0), "Next valid request damages same enemy again")
	var wrong_target := damage_event.duplicate()
	wrong_target["request_id"] = 900003
	wrong_target["target"] = player
	health._on_valid_contact(wrong_target)
	check(is_equal_approx(health.hp, 50.0), "Damage recipient checks configured target identity")
	var physical_event := damage_event.duplicate()
	physical_event["request_id"] = 900004
	physical_event["contact_kind"] = "physical"
	health._on_valid_contact(physical_event)
	check(is_equal_approx(health.hp, 50.0), "Physical event rejected even if sent to valid handler")

	# Actual unmodified motions complete a four-hit HP/death loop.
	health.debug_reset_hp()
	reset_player()
	await ticks(60)
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	await ticks(2)
	var enemy_pose := enemy.global_transform
	var enemy_collision: Transform3D = enemy.get_node("CollisionShape3D").transform
	var player_body: MeshInstance3D = player.get_node("VisualRoot/Body")
	var player_material := player_body.get_active_material(0)
	for hit in 4:
		demo.request_motion([0, 1, 2, 0][hit])
		await ticks(60)
		check(is_equal_approx(health.hp, 100.0 - 25.0 * (hit + 1)), "Actual attack damages exactly once: " + str(hit))
		check(health.hp >= 0.0 and health.hp <= health.max_hp, "HP stays in bounds after attack")
	check(health.dead and is_zero_approx(health.hp), "Fourth valid hit enters Dead at zero HP")
	check(is_instance_valid(enemy) and enemy.is_inside_tree() and enemy.get_node("VisualRoot/Body").visible, "Dead enemy model/node retained")
	check(enemy.global_transform.is_equal_approx(enemy_pose) and enemy.get_node("CollisionShape3D").transform.is_equal_approx(enemy_collision), "Death causes no root motion or collision changes")
	check(enemy.get_node("VisualRoot/Body").material_override == health.dead_material and player_body.get_active_material(0) == player_material, "Death tint affects only enemy body instance")
	demo.request_motion(0)
	await ticks(60)
	check(health.dead and is_zero_approx(health.hp) and is_equal_approx(health.last_damage, 25.0), "Dead enemy rejects later real hits without changing last damage")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Enemy HP: 0.0 / 100.0") and trajectory.legend.text.contains("Last damage: 25.0") and trajectory.legend.text.contains("Dead: true"), "F4 shows HP/maximum, last actual damage and death")
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible, "HP debug text hidden when F4 off")
	await ticks(30)
	check(health.dead and is_zero_approx(health.hp), "No automatic revival while waiting")

	# Explicit debug reset and tunable parameter edge cases.
	var reset_key := InputEventKey.new()
	reset_key.physical_keycode = KEY_F7
	reset_key.pressed = true
	health._unhandled_key_input(reset_key)
	check(is_equal_approx(health.hp, 100.0) and not health.dead and is_zero_approx(health.last_damage), "F7 Debug Only reset restores HP/alive/last damage")
	check(enemy.get_node("VisualRoot/Body").material_override == health.original_material, "Debug reset restores original enemy appearance")
	health._on_valid_contact(damage_event) # Captured before F7; live detector history is now cleared.
	check(is_equal_approx(health.hp, 100.0), "Reset cannot replay an old/current accepted request")
	health.max_hp = 40.0
	check(is_equal_approx(health.hp, 40.0), "Reducing Inspector maximum clamps current HP")
	health.test_damage = 60.0
	demo.request_motion(1)
	await ticks(60)
	check(is_zero_approx(health.hp) and health.dead and is_equal_approx(health.last_damage, 40.0), "Overkill clamps HP to zero and reports actual removed HP")
	health.max_hp = 120.0
	check(health.dead and is_zero_approx(health.hp), "Increasing maximum does not revive Dead")
	health.debug_reset_hp()
	check(is_equal_approx(health.hp, 120.0), "Reset initializes configured Inspector maximum")
	health.test_damage = -25.0
	check(is_zero_approx(health.test_damage), "Negative test damage clamped to zero")
	demo.request_motion(2)
	await ticks(60)
	check(is_equal_approx(health.hp, 120.0) and not health.dead and is_zero_approx(health.last_damage), "Zero damage neither heals nor kills")
	health.max_hp = -5.0
	check(is_equal_approx(health.max_hp, 1.0) and is_equal_approx(health.hp, 1.0), "Maximum has positive minimum and HP remains legal")
	health.max_hp = 100.0
	health.test_damage = 25.0
	health.debug_reset_hp()
	demo.request_motion(0)
	await ticks(10)
	var in_progress_id: int = demo.active_request_id
	health.debug_reset_hp()
	await ticks(60)
	check(is_equal_approx(health.hp, 100.0), "Mid-motion reset excludes remainder of the same accepted request")
	demo.request_motion(0)
	await ticks(60)
	check(demo.accepted_request_count > in_progress_id and is_equal_approx(health.hp, 75.0), "Fresh post-reset request can damage normally")
	# Stage 4 Step 4: periodic stationary attack and reciprocal HP.
	var player_health: Node = player.get_node("DebugPlayerHealth")
	check(is_equal_approx(player_health.hp, 100) and not player_health.dead and is_equal_approx(player_health.incoming_test_damage, 25), "Temporary player HP defaults")
	health.debug_reset_hp()
	player_health.debug_reset_hp()
	reset_player()
	enemy.global_transform = enemy_start
	await ticks(2)
	enemy_attack.enabled = true
	enemy_attack.sequence_recovery_seconds = 0.5
	enemy_attack.cancel_attack()
	var count_before: int = enemy_attack.accepted_request_count
	await ticks(60)
	check(enemy_attack.accepted_request_count == count_before, "Outside range starts no attacks")
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	var fixed_origin := enemy.position
	await ticks(90)
	check(enemy_attack.accepted_request_count > count_before, "In-range player triggers periodic attack")
	check(enemy.position.is_equal_approx(fixed_origin), "Attacker never translates or chases")
	check(player_health.hp < 100, "Real enemy weapon sweep damages player")
	enemy_attack.cancel_attack()
	player_health.debug_reset_hp()
	# Moving out during windup permits completion, but no following request.
	enemy_attack.start_attack()
	await ticks(4)
	player.position = Vector3(4, 0, 4)
	player.velocity = Vector3.ZERO
	count_before = enemy_attack.accepted_request_count
	await ticks(100)
	check(enemy_attack.accepted_request_count == count_before and is_equal_approx(player_health.hp, 100), "Leaving range prevents new attacks and a spatial miss does no damage")
	reset_player()
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	enemy_attack.sequence_recovery_seconds = 10
	enemy_attack.cancel_attack()
	await ticks(2)
	trajectory.debug_display_enabled = false
	for hit in 4:
		enemy_attack.start_attack()
		await ticks(60)
		check(is_equal_approx(player_health.hp, 100 - (hit + 1) * 25), "One actual enemy thrust removes exactly 25 HP: " + str(hit))
		check(player_health.hp >= 0 and player_health.hp <= player_health.max_hp, "Player HP remains legal")
	check(player_health.dead and enemy_attack.active_request_id == 0, "Player zero HP stops active enemy swing")
	var dead_position := player.position
	Input.action_press("move_left")
	await ticks(30)
	Input.action_release("move_left")
	check(player.position.is_equal_approx(dead_position) and player.velocity.is_zero_approx(), "Dead player cannot move")
	check(not demo.request_motion(0) and not demo.request_ordinary_motion(), "Dead player cannot request ordinary or debug attacks")
	check(not enemy_attack.start_attack(), "Attacker does not attack a dead player")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Player HP: 0.0 / 100.0") and trajectory.legend.text.contains("Last injury: 25.0") and trajectory.legend.text.contains("Enemy HP:"), "F4 shows both HP and player injury")
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible, "F4 off hides reciprocal HP text")
	health._unhandled_key_input(reset_key)
	check(not health.dead and not player_health.dead and is_equal_approx(health.hp, health.max_hp) and is_equal_approx(player_health.hp, player_health.max_hp), "F7 restores both lives")
	check(demo.active_request_id == 0 and enemy_attack.active_request_id == 0 and is_zero_approx(demo.lock_remaining), "F7 clears both active motions and input lock")
	check(is_zero_approx(player_health.last_damage) and is_zero_approx(health.last_damage), "F7 clears both last damage values")
	Input.action_press("move_left")
	await ticks(5)
	Input.action_release("move_left")
	check(player.position.x < dead_position.x, "Reset restores player movement")
	reset_player()
	await ticks(2)
	# Native geometry samples prove windup/return are harmless and own region excluded.
	var enemy_detector: Node3D = enemy_attack.detector
	var inside := {"base": player.global_position + Vector3.UP * 0.4, "tip": player.global_position + Vector3.UP * 1.4}
	var enemy_window := Vector2(0.25, 0.50)
	enemy_detector._on_sample(800001, 0, timed_pose(inside, 0.0, enemy_window))
	check(is_equal_approx(player_health.hp, 100), "Enemy windup physical contact does no damage")
	enemy_detector._on_sample(800001, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 75), "Enemy active spatial overlap applies damage")
	player_health._on_valid_contact(enemy_detector.valid_events.back())
	check(is_equal_approx(player_health.hp, 75), "Player HP rejects duplicate enemy event")
	enemy_detector._on_sample(800002, 0, timed_pose(inside, 0.6, enemy_window))
	check(is_equal_approx(player_health.hp, 75), "Enemy return contact does no damage")
	var enemy_only := {"base": enemy.global_position + Vector3.UP * 0.4, "tip": enemy.global_position + Vector3.UP * 1.4}
	check(enemy_detector.sweep_blade(enemy_only, enemy_only).is_empty(), "Enemy contact mask excludes its own area/body")
	# Smooth turn limit and facing frozen during a swing.
	health._unhandled_key_input(reset_key)
	player.position = enemy.position + Vector3.RIGHT
	enemy.rotation.y = 0
	await ticks(1)
	check(absf(enemy.rotation.y) <= deg_to_rad(enemy_attack.turn_speed_degrees) / 60 + 0.001 and absf(enemy.rotation.y) > 0, "Enemy turns with angular speed limit rather than snapping")
	enemy_attack.start_attack()
	var swing_heading := enemy.rotation.y
	player.position = enemy.position + Vector3.LEFT
	await ticks(5)
	check(is_equal_approx(enemy.rotation.y, swing_heading), "Enemy does not home during its swing")
	# Killing enemy cancels its current motion and future attempts.
	var lethal := {"request_id": 900100, "contact_kind": "valid_attack", "target": enemy}
	health.test_damage = 100
	health._on_valid_contact(lethal)
	check(health.dead and enemy_attack.active_request_id == 0 and not enemy_attack.start_attack(), "Enemy death cancels motion and rejects new attacks")
	count_before = enemy_attack.accepted_request_count
	await ticks(90)
	check(enemy_attack.accepted_request_count == count_before, "Dead enemy never starts periodic attack")
	health.test_damage = 25
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	enemy.global_transform = enemy_start
	# Stage 4 Step 5: input edge, facing filter, event-based defense and no buffering.
	var defense: Node = player.get_node("DebugDefense")
	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	var defense_rmb := InputEventMouseButton.new()
	defense_rmb.button_index = MOUSE_BUTTON_RIGHT
	var lb := InputEventJoypadButton.new()
	lb.device = 0
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	check(InputMap.event_is_action(defense_rmb, "active_defense") and InputMap.event_is_action(lb, "active_defense"), "RMB and unchanged L1/LB map to active defense")
	check(not InputMap.event_is_action(q, "active_defense"), "Q no longer maps to player defense")
	var no_conflict := true
	for action in InputMap.get_actions():
		if action != "active_defense":
			no_conflict = no_conflict and not InputMap.event_is_action(defense_rmb, action) and not InputMap.event_is_action(lb, action)
	check(no_conflict, "Defense bindings do not overlap prior actions")
	check(is_equal_approx(defense.perfect_window_seconds, 0.15) and is_equal_approx(defense.defense_half_angle_degrees, 60), "Temporary parry/cone Inspector defaults")
	reset_player()
	health._unhandled_key_input(reset_key)
	await ticks(2)
	check(defense.state_name() == "None", "Default/reset defense is None")
	q.pressed = true
	Input.parse_input_event(q)
	await ticks(1)
	check(defense.state_name() == "None" and not Input.is_action_pressed("active_defense"), "Actual Q press cannot start defense")
	q.pressed = false
	Input.parse_input_event(q)
	defense_rmb.pressed = true
	Input.parse_input_event(defense_rmb)
	await ticks(1)
	check(defense.state_name() == "Perfect Parry" and defense.perfect_remaining > 0, "Actual RMB press starts original perfect window")
	await ticks(11)
	check(defense.state_name() == "Held Guard" and defense.perfect_remaining == 0, "Held RMB becomes guard without refreshing parry")
	defense_rmb.pressed = false
	Input.parse_input_event(defense_rmb)
	await ticks(1)
	check(defense.state_name() == "None" and not Input.is_action_pressed("active_defense"), "Actual RMB release exits defense")
	await ticks(20)
	Input.action_press("active_defense")
	await ticks(1)
	check(defense.state_name() == "Perfect Parry" and defense.perfect_remaining > 0, "Press starts perfect parry window")
	var request_count: int = demo.accepted_request_count
	check(not demo.request_motion(0) and not demo.request_ordinary_motion(), "Perfect parry refuses debug and ordinary attacks")
	await ticks(11)
	check(defense.state_name() == "Held Guard" and is_zero_approx(defense.perfect_remaining), "Held input expires into guard without extending parry")
	check(not demo.request_motion(1) and demo.accepted_request_count == request_count, "Held guard refuses new attack requests")
	Input.action_release("active_defense")
	await ticks(1)
	check(defense.state_name() == "None", "Release exits defense")
	await ticks(20)
	check(demo.accepted_request_count == request_count, "Defense-rejected attacks never buffer")

	# Native real-cylinder contact events during fresh parry, held guard and failed rear defense.
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	await ticks(2)
	inside = {"base": player.global_position + Vector3.UP * 0.4, "tip": player.global_position + Vector3.UP * 1.4}
	trajectory.debug_display_enabled = false
	Input.action_press("active_defense")
	await ticks(1)
	enemy_detector._on_sample(810001, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Perfect Parry" and is_zero_approx(player_health.last_damage), "Front actual valid contact parried without HP loss while F4 off")
	check(is_equal_approx(defense.last_prevented_damage, 25), "Parry records prevented test damage")
	await ticks(12)
	enemy_detector._on_sample(810002, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Front held guard blocks valid contact")
	player.rotation.y = PI
	enemy_detector._on_sample(810003, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 75) and defense.last_result == "Failed", "Rear source bypasses held front guard")
	Input.action_release("active_defense")
	await ticks(1)
	player.rotation.y = 0
	enemy_detector._on_sample(810004, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 50) and defense.last_result == "Failed", "Unguarded valid contact still damages")
	enemy_detector._on_sample(810005, 0, timed_pose(inside, 0.3, enemy_window))
	enemy_detector._on_sample(810006, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.dead and defense.state_name() == "None" and defense.last_result == "Failed", "Lethal failed defense disables guard but retains last result")
	Input.action_press("active_defense")
	await ticks(1)
	check(defense.state_name() == "None", "Dead player cannot open parry window")
	Input.action_release("active_defense")
	await ticks(1)

	# Full existing enemy animation, timed defense at actual sweep arrival.
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = true
	enemy_attack.sequence_recovery_seconds = 10
	enemy.rotation.y = PI
	enemy_attack.cancel_attack()
	enemy_attack.start_attack()
	await ticks(14)
	Input.action_press("active_defense")
	await ticks(12)
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Perfect Parry", "Timed input parries actual animated enemy thrust")
	Input.action_release("active_defense")
	await ticks(30)
	health._unhandled_key_input(reset_key)
	Input.action_press("active_defense")
	await ticks(12)
	enemy_attack.start_attack()
	await ticks(60)
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Long-held input blocks next actual thrust without new parry")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Defense: Held Guard") and trajectory.legend.text.contains("Last defense: Block") and trajectory.legend.text.contains("Last injury: 0.0 HP"), "F4 shows held state/result and zero injury")
	Input.action_release("active_defense")
	await ticks(1)
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible, "F4 off hides defense text")
	enemy_attack.enabled = false

	# Guard cancels the old motion immediately but retains its existing no-buffer lock.
	health._unhandled_key_input(reset_key)
	demo.request_motion(2)
	await ticks(3)
	var old_lock: float = demo.lock_remaining
	var current_hand := hand.transform
	Input.action_press("active_defense")
	await ticks(1)
	check(demo.active_request_id == 0 and not demo.window_live and not demo.motion_tween.is_running(), "Defense closes and cancels current attack")
	check(demo.lock_remaining > 0 and demo.lock_remaining <= old_lock, "Defense cancellation preserves remaining original lock")
	check(hand.position.distance_to(current_hand.origin) < 0.18 and hand.basis.get_rotation_quaternion().angle_to(current_hand.basis.get_rotation_quaternion()) < 0.7, "Defense begins from current pose with bounded first-frame step")
	Input.action_release("active_defense")
	await ticks(1)
	check(not demo.request_motion(0), "Release cannot bypass preserved lock")
	await ticks(20)
	check(demo.request_motion(0), "Fresh input after release and lock expiry is accepted")
	await ticks(60)
	# Adjustable cone and window are used without turning the player automatically.
	health._unhandled_key_input(reset_key)
	Input.action_press("active_defense")
	await ticks(1)
	var actor_rotation := player.rotation
	defense.defense_half_angle_degrees = 20
	enemy.position = player.position + Vector3(0.7, 0, -0.7)
	check(not defense.resolve_valid_contact(enemy, 25), "Narrow Inspector cone rejects side-front source")
	defense.defense_half_angle_degrees = 60
	check(defense.resolve_valid_contact(enemy, 25) and player.rotation.is_equal_approx(actor_rotation), "Wider cone accepts without auto-facing")
	Input.action_release("active_defense")
	await ticks(1)
	defense.perfect_window_seconds = 0
	Input.action_press("active_defense")
	await ticks(1)
	check(defense.state_name() == "Held Guard", "Zero Inspector parry duration immediately uses held guard")
	defense.perfect_window_seconds = 0.15
	health._unhandled_key_input(reset_key)
	check(defense.state_name() == "None" and defense.last_result == "None" and is_zero_approx(defense.last_prevented_damage), "F7 clears defense state and temporary results")
	await ticks(2)
	check(defense.state_name() == "None", "Holding through F7 cannot automatically restart parry")
	Input.action_release("active_defense")
	await ticks(1)
	Input.action_press("active_defense")
	await ticks(1)
	check(defense.state_name() == "Perfect Parry", "Release and new press rearm after reset")
	Input.action_release("active_defense")
	await ticks(1)
	# Stage 4 Step 6: hand motion and independent two-moving-blade geometry.
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	var clash: Node = arena.get_node("BladeClashDebug")
	var idle_pose := hand.transform
	Input.action_press("active_defense")
	defense.refresh_input()
	check(hand.transform.is_equal_approx(idle_pose), "Guard transition has no immediate transform snap")
	await ticks(4)
	var parry_pose := hand.transform
	check(hand.position.distance_to(idle_pose.origin) > 0.1, "Parry visibly raises grip")
	await ticks(12)
	var held_pose := hand.transform
	check(held_pose.is_equal_approx(demo._pose(defense.guard_position, defense.guard_rotation_degrees)), "Guard settles into configured stable pose")
	check(not held_pose.is_equal_approx(parry_pose), "Parry and held poses differ")
	check(weapon.global_position.is_equal_approx(hand.global_position) and weapon.transform.is_equal_approx(Transform3D.IDENTITY), "Defensive weapon stays attached to right hand")
	var max_guard_step := 0.0
	var previous_guard := hand.transform
	Input.action_release("active_defense")
	for _frame in 20:
		await ticks(1)
		max_guard_step = maxf(max_guard_step, hand.position.distance_to(previous_guard.origin))
		previous_guard = hand.transform
	check(hand.transform.is_equal_approx(idle_pose) and max_guard_step < 0.18, "Release returns smoothly to idle guard")
	Input.action_press("active_defense")
	await ticks(15)
	Input.action_release("active_defense")
	await ticks(1)
	demo.lock_remaining = 0
	var return_pose := hand.transform
	demo.request_motion(0)
	check(hand.transform.is_equal_approx(return_pose), "Attack interrupts visual return from current pose")
	await ticks(60)
	check(hand.transform.is_equal_approx(idle_pose), "Only attack tween controls hand after return interruption")

	var p := blade_pose(Vector3(0, 0, 0), Vector3(0, 1, 0))
	var e := blade_pose(Vector3(-0.5, 0.5, 0), Vector3(0.5, 0.5, 0))
	var crossing := {"player": p, "enemy": e}
	var contact: Dictionary = clash.sweep_pair(crossing, crossing)
	check(not contact.is_empty() and contact["position"].distance_to(Vector3(0, 0.5, 0)) < 0.001, "True crossing produces real blade contact position")
	var separated := {"player": p, "enemy": blade_pose(Vector3(-0.5, 0.5, 0.1), Vector3(0.5, 0.5, 0.1))}
	check(clash.sweep_pair(separated, separated).is_empty(), "Near but separated blades do not clash")
	var fast_a := {"player": p, "enemy": blade_pose(Vector3(-1, 0, 0), Vector3(-1, 1, 0))}
	var fast_b := {"player": p, "enemy": blade_pose(Vector3(1, 0, 0), Vector3(1, 1, 0))}
	check(clash.sweep_pair(fast_a, fast_a).is_empty() and clash.sweep_pair(fast_b, fast_b).is_empty(), "Fast translating blade endpoints miss")
	check(not clash.sweep_pair(fast_a, fast_b).is_empty(), "Between-frame blade translation detects crossing")
	var both_a := {"player": fast_a["enemy"], "enemy": fast_b["enemy"]}
	var both_b := {"player": fast_b["enemy"], "enemy": fast_a["enemy"]}
	check(not clash.sweep_pair(both_a, both_b).is_empty(), "Relative sweep accounts for both moving blades")
	var rotation_p := blade_pose(Vector3(0, -0.4, -0.8), Vector3(0, 0.6, -0.8))
	var rotating_a := {"player": rotation_p, "enemy": blade_pose(Vector3.ZERO, Vector3(-0.8660254, 0, -0.5))}
	var rotating_b := {"player": rotation_p, "enemy": blade_pose(Vector3.ZERO, Vector3(0.8660254, 0, -0.5))}
	check(not clash.sweep_pair(rotating_a, rotating_b).is_empty(), "Rotation interpolation detects intermediate blade contact")
	var actual_p: Dictionary = clash.pose(clash.player_weapon)
	check(actual_p["base"].is_equal_approx(weapon.get_node("BladeBase").global_position) and actual_p["tip"].is_equal_approx(weapon.get_node("BladeTip").global_position), "Blade clash references actual player markers")

	# Temporary weapon relocation exercises real-transform event delivery/dedup only in test.
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = true
	enemy_attack.sequence_recovery_seconds = 10
	enemy_attack.start_attack()
	var original_enemy_weapon: Transform3D = enemy_attack.weapon.transform
	enemy_attack.weapon.global_transform = weapon.global_transform
	clash._start(enemy_attack.active_request_id)
	var event_count: int = clash.events.size()
	clash.sample_attack(enemy_attack.active_request_id)
	clash.sample_attack(enemy_attack.active_request_id)
	check(event_count > 0 and clash.events.size() == event_count, "One enemy request deduplicates actual marker overlap")
	check(clash.events.back()["physics_frame"] > 0 and clash.events.back()["kind"] == "blade_clash", "Blade event carries request/world point/frame and independent kind")
	check(is_equal_approx(player_health.hp, 100), "Blade diagnostic event cannot independently change HP")
	enemy_attack.weapon.transform = original_enemy_weapon
	enemy_attack.cancel_attack()
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Blade clash: true") and trajectory.legend.text.contains("Body physical:"), "F4 differentiates clash and body statuses")
	check(trajectory.contact_markers.any(func(marker: Dictionary) -> bool: return marker["kind"] == "blade_clash"), "Clash emits separate debug position marker")
	trajectory.debug_display_enabled = false
	check(not trajectory.lines.visible and not trajectory.legend.visible, "F4 off hides all new geometry and text")
	health._unhandled_key_input(reset_key)
	check(clash.latest.is_empty() and clash.events.is_empty() and trajectory.contact_markers.is_empty(), "F7 clears clash history and contact markers")

	# Observe actual pose coverage, keeping Step 5 body-angle outcome authoritative.
	reset_player()
	await ticks(30)
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	Input.action_press("active_defense")
	await ticks(16)
	enemy_attack.start_attack()
	await ticks(60)
	check(clash.latest["body_contact"] and clash.latest["valid_body_contact"] and clash.latest["damage_prevented"] == "YES", "Body contact, active defense and final prevention recorded together")
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Guard pose/clash diagnostics preserve baseline blocked damage")
	print("HELD_GUARD_BLADE_COVERAGE ", JSON.stringify(clash.latest))
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Damage prevented: YES") and trajectory.contact_markers.any(func(marker: Dictionary) -> bool: return marker["kind"] == "enemy_body"), "F4 shows final prevention and separate enemy-body marker")
	Input.action_release("active_defense")
	await ticks(20)
	trajectory.debug_display_enabled = false
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	check(clash.capped_segments == 0, "Test motions stay below clash subdivision cap")

	# Stage 4 Step 7: bounded matching in the previously uncovered stance.
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	matching.enabled = true
	enemy_attack.enabled = true
	enemy_attack.sequence_recovery_seconds = 10
	Input.action_press("active_defense")
	await ticks(16)
	var matching_root := player.transform
	var matching_weapon := weapon.transform
	enemy_attack.start_attack()
	var max_correction := 0.0
	var max_turn := 0.0
	var max_hand_step := 0.0
	var max_hand_turn := 0.0
	var last_hand := hand.transform
	var saw_active := false
	var saw_matched := false
	var body_safe := true
	var attached := true
	for _frame in 60:
		await ticks(1)
		saw_active = saw_active or matching.active
		saw_matched = saw_matched or matching.result == "Matched"
		max_correction = maxf(max_correction, matching.position_correction)
		max_turn = maxf(max_turn, matching.rotation_correction_degrees)
		max_hand_step = maxf(max_hand_step, hand.position.distance_to(last_hand.origin))
		max_hand_turn = maxf(max_hand_turn, last_hand.basis.get_rotation_quaternion().angle_to(hand.basis.get_rotation_quaternion()))
		if matching.active: body_safe = body_safe and matching._safe(hand.transform)
		attached = attached and weapon.global_position.is_equal_approx(hand.global_position)
		last_hand = hand.transform
	check(saw_active, "Guard responds to actual active enemy blade with matching")
	check(clash.latest["blade_contact"], "Previously uncovered 0.24 right / 0.9 forward stance now produces real clash")
	check(saw_matched, "Reachable pose reports matched separately from clash")
	check(max_correction <= matching.max_position_correction + 0.001 and max_turn <= matching.max_rotation_degrees + 0.1, "Matching stays inside Inspector correction bounds")
	check(max_hand_step < 0.08 and max_hand_turn < 0.20, "Matching and recovery have bounded sampled steps without teleport")
	check(body_safe, "Matching keeps grip and entire blade forward of body")
	check(player.transform.is_equal_approx(matching_root) and weapon.transform.is_equal_approx(matching_weapon) and attached, "Matching preserves actor root and hand attachment")
	check(is_equal_approx(clash.blade_radius, 0.012), "Matching does not enlarge clash radius")
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Real clash improvement preserves accepted guard damage result")
	print("MATCHING_TYPICAL_STANCE ", JSON.stringify({"clash": clash.latest, "result": matching.result,
		"max_position_correction": max_correction, "max_rotation_degrees": max_turn, "max_frame_step": max_hand_step}))
	await ticks(20)
	check(not matching.active and hand.transform.is_equal_approx(demo._pose(defense.guard_position, defense.guard_rotation_degrees)), "After contact matching stops and recovers stable guard")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Contact Matching:") and trajectory.legend.text.contains("Blade clash: true") and trajectory.legend.text.contains("Damage prevented: YES"), "F4 separates matching, actual clash and defense result")
	trajectory.debug_display_enabled = false
	check(not trajectory.lines.visible and not trajectory.legend.visible, "F4 off hides matching target and text")
	Input.action_release("active_defense")
	await ticks(20)
	health._unhandled_key_input(reset_key)
	check(not matching.active and matching.request_id == 0 and is_zero_approx(matching.position_correction), "F7 clears matching state and corrections")

	# Tight limits cannot force a reach; body-angle baseline must remain unaffected.
	matching.max_position_correction = 0
	matching.max_rotation_degrees = 0
	Input.action_press("active_defense")
	await ticks(16)
	enemy_attack.start_attack()
	await ticks(60)
	check(matching.result == "Failed" and matching.reason.contains("limits"), "Unreachable correction records explicit failure reason")
	check(not clash.latest["blade_contact"] and is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Failed matching never fabricates clash or changes successful baseline block")
	Input.action_release("active_defense")
	await ticks(20)
	health._unhandled_key_input(reset_key)
	matching.max_position_correction = 0.30
	matching.max_rotation_degrees = 35
	player.rotation.y = PI
	Input.action_press("active_defense")
	await ticks(16)
	enemy_attack.start_attack()
	await ticks(60)
	check(not matching.active and matching.reason.contains("cone") and player_health.hp < 100, "Rear attack is neither tracked nor blocked")
	Input.action_release("active_defense")
	await ticks(20)
	health._unhandled_key_input(reset_key)
	player.rotation.y = 0
	enemy_attack.start_attack()
	await ticks(22)
	Input.action_press("active_defense")
	await ticks(60)
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Perfect Parry", "Matching does not extend or replace timed parry validation")
	print("MATCHING_PARRY_STANCE ", JSON.stringify(clash.latest))
	Input.action_release("active_defense")
	await ticks(20)
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	# Stage 4 Step 8: native multi-direction bursts and current 5 HP damage.
	player_health.incoming_test_damage = 5
	enemy_attack.sequence_recovery_seconds = 0.8
	enemy_attack.attack_gap_seconds = 0.15
	matching.enabled = false
	var enemy_hand: Node3D = enemy_attack.hand
	var trails: Dictionary = {}
	for size in [3, 4, 5]:
		health._unhandled_key_input(reset_key)
		reset_player()
		await ticks(30)
		enemy.position = player.position + Vector3(0.24, 0, -0.9)
		enemy.rotation.y = PI
		enemy_attack.sequence_length = size
		enemy_attack.enabled = true
		var origin_before := enemy.position
		var start_count: int = enemy_attack.accepted_request_count
		var burst_entry_pose := enemy_hand.transform
		check(enemy_attack.start_sequence(), "Starts native burst of " + str(size))
		check(enemy_hand.transform.is_equal_approx(burst_entry_pose), "Burst entry retains existing hand pose")
		var step_max := 0.0
		var angle_max := 0.0
		var prior := enemy_hand.transform
		for _frame in 300:
			await ticks(1)
			step_max = maxf(step_max, enemy_hand.position.distance_to(prior.origin))
			angle_max = maxf(angle_max, prior.basis.get_rotation_quaternion().angle_to(enemy_hand.basis.get_rotation_quaternion()))
			prior = enemy_hand.transform
			if enemy_attack.active_request_id != 0:
				var move: int = enemy_attack.motion
				if not trails.has(move): trails[move] = []
				trails[move].append(enemy_attack.weapon.get_node("BladeTip").global_position)
			if not enemy_attack.sequence_active and enemy_attack.active_request_id == 0: break
		check(enemy_attack.accepted_request_count == start_count + size and not enemy_attack.sequence_active, "Burst executes exact independently identified attack count")
		check(step_max < 0.18 and angle_max < 0.6, "Burst transitions stay continuous in position and rotation")
		check(enemy.position.is_equal_approx(origin_before), "Burst never translates enemy")
		var ids: Array[int] = []
		var order: Array[int] = []
		for record in clash.records:
			ids.append(record["request_id"])
			order.append(record["motion"])
		check(order == ([0, 1, 2, 0, 1].slice(0, size)), "Predictable Thrust/Left/Right cycle without consecutive duplicates")
		check(ids.size() == size and ids[0] > start_count and ids.back() == start_count + size, "Each attack has its own blade-contact record")
		var hits: Array = enemy_detector.valid_events.filter(func(event: Dictionary) -> bool: return event["request_id"] in ids)
		check(not hits.is_empty() and is_equal_approx(player_health.hp, 100 - hits.size() * 5), "Actual burst valid contacts each remove 5 HP with F4 off")
		for id in ids:
			check(enemy_detector.valid_events.filter(func(event: Dictionary) -> bool: return event["request_id"] == id).size() <= 1, "Per-enemy-request valid damage deduplicated")
		for hit in hits:
			var bounds: Vector2 = [Vector2(0.25, 0.50), Vector2(0.12, 0.32), Vector2(0.12, 0.32)][hit["motion"]]
			check(hit["playback_time"] >= bounds.x and hit["playback_time"] < bounds.y and hit["motion_name"] in ["Thrust", "Left Cut", "Right Cut"], "Enemy event uses own move name and active window")
		for i in range(1, clash.records.size()):
			var interval: float = float(clash.records[i]["start_frame"] - clash.records[i - 1]["end_frame"]) / 60
			check(absf(interval - 0.15) < 0.04, "Group gap follows configured short interval after actual completion")
		var recovery_count: int = enemy_attack.accepted_request_count
		await ticks(20)
		check(enemy_attack.accepted_request_count == recovery_count and enemy_hand.transform.is_equal_approx(enemy_attack.idle), "End-of-group recovery blends to idle without immediate new burst")
		enemy_attack.enabled = false
	check(trails.has(0) and trails.has(1) and trails.has(2), "Three native enemy trajectories sampled")
	var left_mid: Vector3 = trails[1][trails[1].size() / 2]
	var right_mid: Vector3 = trails[2][trails[2].size() / 2]
	check(left_mid.distance_to(right_mid) > 0.05, "Left and right cuts have distinct ordered world trajectories")

	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	enemy_attack.sequence_length = 4
	enemy_attack.enabled = true
	matching.enabled = true
	Input.action_press("active_defense")
	await ticks(16)
	enemy_attack.start_sequence()
	var matching_summary: Dictionary = {}
	var player_step_max := 0.0
	var player_turn_max := 0.0
	var player_prior := hand.transform
	for _frame in 300:
		await ticks(1)
		player_step_max = maxf(player_step_max, hand.position.distance_to(player_prior.origin))
		player_turn_max = maxf(player_turn_max, player_prior.basis.get_rotation_quaternion().angle_to(hand.basis.get_rotation_quaternion()))
		player_prior = hand.transform
		if matching.request_id == enemy_attack.active_request_id and matching.request_id != 0:
			matching_summary[enemy_attack.motion] = {"result": matching.result, "reason": matching.reason}
		if not enemy_attack.sequence_active and enemy_attack.active_request_id == 0: break
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Held Guard blocks actual burst without resource costs")
	check(is_zero_approx(defense.perfect_remaining) and defense.state_name() == "Held Guard", "Burst never refreshes held-input parry window")
	check(player_step_max < 0.18 and player_turn_max < 0.6, "Matching and recovery avoid large steps between directional attacks")
	check(matching_summary.has(0) and matching_summary.has(1) and matching_summary.has(2), "Matching independently attempts every enemy direction")
	var real_clashes := 0
	for record in clash.records:
		if record["blade_contact"]: real_clashes += 1
		check(clash.events.filter(func(event: Dictionary) -> bool: return event["request_id"] == record["request_id"]).size() <= 1, "Burst real clashes independently deduplicate")
	print("BURST_GUARD_MATCHING ", JSON.stringify({"records": clash.records, "matching": matching_summary, "real_clashes": real_clashes,
		"player_max_step": player_step_max, "player_max_turn": player_turn_max}))
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Enemy burst:") and (trajectory.legend.text.contains("Right Cut") or trajectory.legend.text.contains("Thrust")), "F4 exposes burst and current enemy motion")
	trajectory.debug_display_enabled = false
	Input.action_release("active_defense")
	await ticks(1)
	health._unhandled_key_input(reset_key)
	enemy_attack.start_sequence()
	await ticks(4)
	player.position = Vector3(4, 0, 4)
	var leave_count: int = enemy_attack.accepted_request_count
	await ticks(100)
	check(enemy_attack.accepted_request_count == leave_count and not enemy_attack.sequence_active, "Range exit finishes current sword and aborts remaining group")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(1)
	enemy_attack.start_sequence()
	await ticks(5)
	health._unhandled_key_input(reset_key)
	check(not enemy_attack.sequence_active and enemy_attack.active_request_id == 0 and enemy_attack.sequence_index == 0, "F7 immediately clears burst state")
	await ticks(10)
	check(enemy_attack.active_request_id == 0, "Reset cooldown prevents stale delayed sword")
	enemy_attack.start_sequence()
	await ticks(5)
	health.test_damage = 100
	health._on_valid_contact({"request_id": 990001, "contact_kind": "valid_attack", "target": enemy})
	check(health.dead and not enemy_attack.sequence_active and enemy_attack.active_request_id == 0, "Enemy death cancels burst and pending attacks")
	health.test_damage = 25
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	# Stage 4 Step 9: actual valid contacts, resource dedup, exhausting block and recovery.
	defense.held_guard_cost = 25
	defense.max_resource = 100
	defense.guard_break_seconds = 1
	defense.recovery_delay_seconds = 1
	defense.recovery_per_second = 20
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(2)
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	inside = {"base": player.global_position + Vector3.UP * 0.4, "tip": player.global_position + Vector3.UP * 1.4}
	Input.action_press("active_defense")
	await ticks(1)
	enemy_detector._on_sample(910001, 0, timed_pose(inside, 0, enemy_window))
	check(is_equal_approx(defense.resource, 100), "Physical-only overlap costs no defensive resource")
	enemy_detector._on_sample(910001, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Perfect Parry" and is_equal_approx(defense.resource, 100) and is_zero_approx(defense.last_resource_cost) and is_equal_approx(player_health.hp, 100), "Perfect parry fully blocks without resource cost")
	await ticks(12)
	enemy_detector._on_sample(910002, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Block" and is_equal_approx(defense.resource, 75) and is_equal_approx(defense.last_resource_cost, 25), "Held block charges exactly 25 on actual valid contact")
	player_health._on_valid_contact(enemy_detector.valid_events.back())
	check(defense.resolve_valid_contact(enemy, 5, 910002) and is_equal_approx(defense.resource, 75), "Duplicate delivery cannot charge resource twice")
	await ticks(20)
	check(is_equal_approx(defense.resource, 75) and defense.recovery_elapsed == 0, "Holding defense neither drains over time nor recovers")
	player.rotation.y = PI
	enemy_detector._on_sample(910003, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(defense.resource, 75) and is_equal_approx(player_health.hp, 95), "Failed rear defense damages HP without block cost")
	player.rotation.y = 0
	for id in [910004, 910005, 910006]:
		enemy_detector._on_sample(id, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_zero_approx(defense.resource) and defense.guard_break_remaining > 0, "Fourth held block reaches zero and immediately breaks guard")
	check(is_equal_approx(player_health.hp, 95) and is_zero_approx(player_health.last_damage) and defense.last_result == "Block", "Exhausting block still prevents its full HP damage")
	check(not defense.held and is_zero_approx(defense.perfect_remaining) and not matching.active, "Guard Break immediately clears effective defense and matching")
	check(defense.resolve_valid_contact(enemy, 5, 910006) and is_zero_approx(defense.resource), "Exhausting request stays blocked after break without replay cost")
	enemy_detector._on_sample(910007, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_equal_approx(player_health.hp, 90) and defense.last_result == "Failed", "Subsequent valid hit during Guard Break damages HP")
	Input.action_release("active_defense")
	await ticks(1)
	Input.action_press("active_defense")
	await ticks(1)
	enemy_detector._on_sample(910008, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.guard_break_remaining > 0 and not defense.held and is_equal_approx(player_health.hp, 85), "Release/repress cannot bypass Guard Break or parry subsequent hit")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Resource: 0.0 / 100.0") and trajectory.legend.text.contains("Guard Break: true") and trajectory.legend.text.contains("Last block cost: 25.0"), "F4 shows depleted resource, real last cost and break timer")
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible, "F4 off hides resource/break text")
	Input.action_release("active_defense")
	await ticks(20)
	check(is_zero_approx(defense.resource) and defense.guard_break_remaining > 0 and is_zero_approx(defense.recovery_elapsed), "Guard Break suppresses recovery even after release")
	for _frame in 90:
		await ticks(1)
		if defense.guard_break_remaining == 0: break
	check(is_zero_approx(defense.resource) and is_zero_approx(defense.recovery_elapsed), "Break expiry starts a fresh recovery delay, without immediate refill")
	Input.action_press("active_defense")
	await ticks(15)
	check(is_zero_approx(defense.resource) and not defense.held, "Zero resource and held input cannot regain defense or recovery")
	Input.action_release("active_defense")
	await ticks(30)
	check(is_zero_approx(defense.resource) and defense.recovery_state == "Delay", "Released defense waits for configured recovery delay")
	await ticks(60)
	check(absf(defense.resource - 10) < 0.75 and defense.recovery_state == "Recovering", "After 1 s delay resource recovers at 20 points per second")
	var recovering_amount: float = defense.resource
	Input.action_press("active_defense")
	await ticks(12)
	check(is_equal_approx(defense.resource, recovering_amount) and defense.recovery_state.contains("Paused"), "New held input pauses recovery without refreshing resource")
	Input.action_release("active_defense")
	await ticks(360)
	check(is_equal_approx(defense.resource, 100) and defense.recovery_state == "Full", "Recovery clamps at maximum")
	defense.max_resource = 10
	health._unhandled_key_input(reset_key)
	await ticks(1)
	Input.action_press("active_defense")
	await ticks(12)
	enemy_detector._on_sample(910009, 0, timed_pose(inside, 0.3, enemy_window))
	check(is_zero_approx(defense.resource) and is_equal_approx(defense.last_resource_cost, 10) and is_equal_approx(player_health.hp, 100), "Insufficient positive resource still absorbs hit then clamps/breaks; cost shows actual reduction")
	defense.max_resource = 100
	health._unhandled_key_input(reset_key)
	check(is_equal_approx(defense.resource, 100) and is_zero_approx(defense.guard_break_remaining) and is_zero_approx(defense.recovery_elapsed) and is_zero_approx(defense.last_resource_cost), "F7 refills configured maximum and clears break/recovery/cost records")
	Input.action_release("active_defense")
	await ticks(1)
	# Real five-sword burst: four blocks exhaust resource; fifth valid contact damages.
	enemy_attack.sequence_length = 5
	enemy_attack.sequence_recovery_seconds = 0.8
	enemy_attack.enabled = true
	matching.enabled = true
	Input.action_press("active_defense")
	await ticks(16)
	enemy_attack.start_sequence()
	for _frame in 350:
		await ticks(1)
		if not enemy_attack.sequence_active and enemy_attack.active_request_id == 0: break
	check(is_equal_approx(player_health.hp, 95) and is_zero_approx(defense.resource), "Native five-sword group blocks four then damages during break")
	var prevented_count := 0
	for record in clash.records:
		if record["damage_prevented"] == "YES": prevented_count += 1
	check(prevented_count == 4 and clash.records.back()["damage_prevented"] == "NO", "Actual records distinguish exhausting block from following damaging hit")
	check(clash.records[3]["defense_on_body_contact"] == "Held Guard", "Exhausting hit snapshot retains successful pre-break defense state")
	print("RESOURCE_NATIVE_BURST ", JSON.stringify({"resource": defense.resource, "HP": player_health.hp, "prevented": prevented_count, "records": clash.records}))
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	# Step 10: isolated resource exhaustion uses the same real body-contact receiver.
	matching.enabled = false
	defense.max_resource = 25
	health._unhandled_key_input(reset_key)
	await ticks(1)
	Input.action_press("active_defense")
	await ticks(16)
	var break_start_pose: Transform3D = hand.transform
	var break_root: Transform3D = player.transform
	enemy_detector._on_sample(920001, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.is_guard_broken() and defense.combat_state_name() == "Guard Break", "Break is an explicit combat state")
	check(hand.transform.is_equal_approx(break_start_pose), "Break entry blends from current hand pose without snapping")
	check(is_equal_approx(player_health.hp, 100) and defense.last_result == "Block", "Break animation does not retroactively damage exhausting hit")
	check(defense.last_break_request_id == 920001, "Break records its triggering attack ID")
	check(not defense.attack_allowed() and not defense.defense_allowed(), "Break disables attack and defense independently of ordinary lock")
	check(not demo.request_ordinary_motion() and not demo.request_motion(demo.Motion.BROAD_CUT), "Ordinary and forced debug attacks are both rejected during break")
	var previous_break_pose: Transform3D = hand.transform
	var peak_deflection := 0.0
	var largest_break_step := 0.0
	for _frame in 32:
		await ticks(1)
		peak_deflection = maxf(peak_deflection, hand.position.distance_to(break_start_pose.origin))
		largest_break_step = maxf(largest_break_step, hand.position.distance_to(previous_break_pose.origin))
		previous_break_pose = hand.transform
	check(peak_deflection > 0.15 and largest_break_step < 0.1, "Break has visible bounded continuous hand deflection")
	check(hand.transform.is_equal_approx(demo._idle_guard()), "Break motion returns to non-defensive idle before state expiry")
	check(player.transform.is_equal_approx(break_root) and weapon.transform == Transform3D.IDENTITY, "Break moves only hand, preserving root and weapon attachment")
	check(not matching.active and matching.request_id == 0, "Break clears matching and cannot continue sword tracking")
	var movement_start: Vector3 = player.position
	var camera_start: Basis = camera.global_basis
	Input.action_press("move_back")
	Input.action_press("look_right")
	await ticks(8)
	Input.action_release("move_back")
	Input.action_release("look_right")
	check(player.position.distance_to(movement_start) > 0.05, "Movement remains available during break")
	check(not camera.global_basis.is_equal_approx(camera_start), "Camera remains controllable during break")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Attack allowed: false") and trajectory.legend.text.contains("Defense allowed: false") and trajectory.legend.text.contains("Break request: 920001"), "F4 exposes break permissions and triggering request")
	trajectory.debug_display_enabled = false
	check(not demo.request_motion(demo.Motion.THRUST), "F4 visibility does not bypass break attack restriction")
	for _frame in 90:
		await ticks(1)
		if not defense.is_guard_broken(): break
	check(defense.attack_allowed() and demo.request_motion(demo.Motion.SHORT_CUT), "Attack permission restores on break expiry even with RMB held")
	check(not defense.held and defense.require_release, "Holding RMB through expiry cannot automatically re-enter defense")
	player.transform = break_root
	player.velocity = Vector3.ZERO
	defense._resource = 25 # Isolate release latch from zero-resource availability.
	defense.refresh_input()
	check(not defense.held, "Even positive resource cannot bypass post-break release latch")
	Input.action_release("active_defense")
	await ticks(1)
	Input.action_press("active_defense")
	await ticks(1)
	check(defense.held and defense.perfect_remaining > 0, "Fresh post-break release/press restores parry")
	await ticks(16)
	enemy_detector._on_sample(920002, 0, timed_pose(inside, 0.3, enemy_window))
	await ticks(5)
	check(defense.is_guard_broken() and not hand.transform.is_equal_approx(demo._idle_guard()), "F7 fixture is actually mid-break deflection")
	health._unhandled_key_input(reset_key)
	check(hand.transform.is_equal_approx(demo._idle_guard()) and demo.lock_remaining == 0 and demo.active_request_id == 0, "F7 clears attack lock and snaps debug pose out of mid-break animation")
	check(not defense.is_guard_broken() and defense.last_break_request_id == 0 and defense.resource == 25 and not matching.active, "F7 clears break, trigger, resource and matching state")
	await ticks(32)
	check(hand.transform.is_equal_approx(demo._idle_guard()), "No old break tween overwrites reset pose later")
	Input.action_release("active_defense")
	defense.max_resource = 100
	health._unhandled_key_input(reset_key)
	# Step 11: same real swept-contact fixture; historical behavior remains isolated above.
	defense.instinctive_enabled = true
	check(defense.instinctive_cost == 50 and defense.instinctive_raise_seconds == 0.06, "Instinctive defaults are full 50 cost and continuous 0.06 s raise")
	player.transform = break_root
	player.velocity = Vector3.ZERO
	matching.enabled = false
	health._unhandled_key_input(reset_key)
	await ticks(1)
	enemy_detector._on_sample(930001, 0, timed_pose(inside, 0.1, enemy_window))
	check(defense.resource == 100 and player_health.hp == 100 and not defense.last_instinctive_triggered, "Physical-only contact never triggers instinctive defense")
	check(demo.request_motion(demo.Motion.THRUST), "Player attack starts before emergency intercept")
	var auto_lock: float = demo.lock_remaining
	var auto_start: Transform3D = hand.transform
	enemy_detector._on_sample(930002, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Instinctive Defense" and defense.last_instinctive_triggered and player_health.hp == 100, "Unheld frontal valid contact automatically prevents injury")
	check(defense.resource == 50 and defense.last_instinctive_cost == 50 and defense.instinctive_request_id == 930002, "Instinctive payment and request ID are recorded")
	check(hand.transform.is_equal_approx(auto_start), "Automatic raise starts continuously from current attack pose")
	check(demo.active_request_id == 0 and not demo.window_live and demo.lock_remaining == auto_lock, "Emergency interruption closes attack window without clearing input lock")
	check(not demo.request_motion(demo.Motion.SHORT_CUT), "Emergency reaction cannot create a new buffered attack")
	var enemy_hp_before_auto: float = health.hp
	health._on_valid_contact({"request_id": demo.accepted_request_count + 100, "target": enemy, "contact_kind": "valid_attack"})
	check(health.hp == enemy_hp_before_auto, "Canceled attack's stale event cannot damage during instinctive reaction")
	player_health._on_valid_contact(enemy_detector.valid_events.back())
	check(defense.resource == 50 and player_health.hp == 100, "Duplicate instinctive event cannot charge or damage again")
	await ticks(6)
	check(defense.instinctive_phase == "Intercept" and hand.position.distance_to(defense.guard_position) < 0.01, "Continuous raise reaches safe guard envelope before matching")
	await ticks(12)
	check(defense.instinctive_phase == "Stagger / Return" and not defense.is_guard_broken(), "Ordinary instinctive hand stagger is distinct from Guard Break")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Instinctive Defense: true") and trajectory.legend.text.contains("request 930002") and trajectory.legend.text.contains("cost 50.0"), "F4 reports instinctive payment, request and phase")
	trajectory.debug_display_enabled = false
	await ticks(24)
	check(defense.instinctive_phase == "Idle" and demo.active_request_id == 0 and hand.transform.is_equal_approx(demo._idle_guard()), "Reaction smoothly returns without restoring interrupted attack")
	defense._resource = 50 # Exact-payment fixture, avoiding unrelated recovery delta.
	enemy_detector._on_sample(930003, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.resource == 0 and defense.is_guard_broken() and player_health.hp == 100, "Second independent automatic payment blocks exhausting hit then breaks")
	check(defense.instinctive_phase == "Idle" and defense.last_break_request_id == 930003, "Break takes animation priority over normal instinctive stagger")
	enemy_detector._on_sample(930004, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 95 and defense.instinctive_reason == "Guard Break", "Later valid contact during break causes normal 5 HP injury")
	health._unhandled_key_input(reset_key)
	defense._resource = 49
	enemy_detector._on_sample(930005, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 95 and defense.resource == 49 and defense.instinctive_reason.contains("Insufficient"), "Underfunded positive resource cannot trigger this temporary full-payment rule")
	health._unhandled_key_input(reset_key)
	player.rotation.y += PI
	enemy_detector._on_sample(930006, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 95 and defense.resource == 100 and defense.instinctive_reason.contains("cone"), "Rear valid contact damages without automatic turn or payment")
	player.transform = break_root
	health._unhandled_key_input(reset_key)
	Input.action_press("active_defense")
	await ticks(1)
	enemy_detector._on_sample(930007, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Perfect Parry" and defense.resource == 100 and not defense.last_instinctive_triggered, "Successful active parry takes priority at zero cost")
	await ticks(16)
	enemy_detector._on_sample(930008, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Block" and defense.resource == 75 and not defense.last_instinctive_triggered, "Successful held block takes priority with original 25 cost")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	enemy_detector._on_sample(930009, 0, timed_pose(inside, 0.3, enemy_window))
	await ticks(2)
	health._unhandled_key_input(reset_key)
	check(defense.instinctive_phase == "Idle" and defense.instinctive_request_id == 0 and not defense.last_instinctive_triggered and defense.last_instinctive_cost == 0, "F7 clears automatic action and request/payment records")
	await ticks(40)
	check(hand.transform.is_equal_approx(demo._idle_guard()) and not matching.active and demo.lock_remaining == 0, "No automatic tween, matching or input-lock residue survives F7")
	# Actual animated sword and matching: do not seed or emit a clash for success.
	reset_player()
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	matching.enabled = true
	enemy_attack.enabled = true
	enemy_attack.cooldown = 999
	health._unhandled_key_input(reset_key)
	enemy_attack.cooldown = 999
	await ticks(2) # Settle the reset player's 1 cm floor offset before root comparison.
	check(enemy_attack.start_attack(), "Native enemy sword starts automatic-defense test")
	var observed_auto_matching := false
	var native_auto_root: Transform3D = player.transform
	for _frame in 70:
		await ticks(1)
		observed_auto_matching = observed_auto_matching or (matching.active and defense.instinctive_phase == "Intercept")
	check(player_health.hp == 100 and defense.last_result == "Instinctive Defense", "Native swept sword triggers unheld automatic defense")
	check(observed_auto_matching, "Native automatic interception uses existing bounded Contact Matching")
	check(player.transform.is_equal_approx(native_auto_root) and weapon.transform == Transform3D.IDENTITY, "Automatic matching preserves actor root and grip attachment")
	check(clash.latest["defense_on_body_contact"] == "Instinctive Defense" and clash.latest["damage_prevented"] == "YES", "Native body record distinguishes automatic prevention from active guard")
	print("INSTINCTIVE_NATIVE ", JSON.stringify({"matching": matching.result, "reason": matching.reason, "clash": clash.latest, "resource": defense.resource}))
	for native_motion in [1, 2]:
		health._unhandled_key_input(reset_key)
		enemy_attack.cooldown = 999
		check(enemy_attack.start_attack(native_motion), "Native directional cut starts automatic-defense test")
		for _frame in 60: await ticks(1)
		check(player_health.hp == 100 and defense.last_result == "Instinctive Defense", "Actual directional cut is automatically defended without RMB")
		if native_motion == 2:
			check(clash.latest["blade_contact"] and matching.result == "Matched", "Right Cut automatically produces independently detected real clash and matched pose")
		print("INSTINCTIVE_DIRECTION ", JSON.stringify({"motion": native_motion, "matching": matching.result, "reason": matching.reason, "clash": clash.latest}))
	health._unhandled_key_input(reset_key)
	enemy_attack.cooldown = 999
	enemy_attack.sequence_length = 5
	check(enemy_attack.start_sequence(), "Native five-sword automatic-defense sequence starts")
	for _frame in 350:
		await ticks(1)
		if not enemy_attack.sequence_active and enemy_attack.active_request_id == 0: break
	var automatic_count := 0
	var damaging_count := 0
	for record in clash.records:
		if record["defense_on_body_contact"] == "Instinctive Defense": automatic_count += 1
		if record["damage_prevented"] == "NO": damaging_count += 1
	check(automatic_count == 2 and damaging_count == 3 and player_health.hp == 85, "Native burst permits two full-cost automatic blocks then three ordinary injuries")
	print("INSTINCTIVE_BURST ", JSON.stringify({"automatic": automatic_count, "damaging": damaging_count, "HP": player_health.hp, "records": clash.records}))
	health._unhandled_key_input(reset_key)
	enemy.position = player.position + Vector3(0, 0, -4)
	enemy_attack.cooldown = 999
	enemy_attack.start_attack()
	await ticks(65)
	check(player_health.hp == 100 and defense.resource == 100 and not defense.last_instinctive_triggered, "Attack without real body contact cannot cause automatic payment or injury")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	# Step 12: deterministic event arbitration, reset epochs and hand-writer ownership.
	reset_player()
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	enemy.rotation.y = PI
	await ticks(2)
	inside = {"base": player.global_position + Vector3.UP * 0.4, "tip": player.global_position + Vector3.UP * 1.4}
	health._unhandled_key_input(reset_key)
	Input.action_press("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(940001, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Perfect Parry" and defense.resource == 100, "Same-frame active parry wins over automatic defense")
	var settled_parry: Dictionary = player_health.last_settlement.duplicate()
	Input.action_release("active_defense")
	defense.refresh_input()
	player_health._on_valid_contact(enemy_detector.valid_events.back())
	check(player_health.last_settlement == settled_parry and defense.resource == 100, "Replayed parry cannot become automatic defense after release")
	Input.action_press("active_defense")
	defense.refresh_input()
	defense.perfect_remaining = 0.15
	defense._physics_process(0.15)
	enemy_detector._on_sample(940002, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.perfect_remaining == 0 and player_health.last_settlement["result"] == "Block" and defense.resource == 75, "Exact parry expiry is held block without floating-point extension")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	check(demo.request_motion(0), "Arbitration same-frame attack begins")
	var arbitration_lock: float = demo.lock_remaining
	enemy_detector._on_sample(940003, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Instinctive Defense" and demo.active_request_id == 0 and demo.lock_remaining == arbitration_lock, "Same-frame attack then enemy contact is interrupted with lock retained")
	check(not demo.request_motion(2) and defense.pose_owner == "Instinctive Raise", "Reverse same-frame order cannot accept new attack during automatic reaction")
	var automatic_event: Dictionary = enemy_detector.valid_events.back().duplicate()
	var saved_auto: Dictionary = player_health.last_settlement.duplicate()
	Input.action_press("active_defense")
	defense.refresh_input()
	player_health._on_valid_contact(automatic_event)
	check(player_health.last_settlement == saved_auto and defense.resource == 50, "Automatic settlement cannot be charged again as held guard")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	check(demo.active_request_id == 0 and defense.pose_owner == "Idle" and not matching.active, "F7 during automatic raise releases all hand writers")
	player_health._on_valid_contact(automatic_event)
	check(player_health.last_settlement.is_empty() and defense.resource == 100, "Old-generation event is rejected after F7 even with synthetic high request ID")
	# Matching must consume at most one physics step and yield to a fresh parry.
	Input.action_press("active_defense")
	defense.refresh_input()
	await ticks(16)
	enemy_attack.enabled = true
	enemy_attack.cooldown = 999
	enemy_attack.start_attack(2)
	for _frame in 35:
		await ticks(1)
		if matching.active: break
	var once_pose: Transform3D = hand.transform
	var once_hold: float = matching.hold_remaining
	matching.update_matching(enemy_attack.active_request_id, 1.0 / 60)
	check(hand.transform.is_equal_approx(once_pose) and matching.hold_remaining == once_hold, "Duplicate matching call in same frame cannot advance hand or hold timer twice")
	Input.action_release("active_defense")
	defense.refresh_input()
	Input.action_press("active_defense")
	defense.refresh_input()
	matching._finish_if_inactive()
	check(defense.pose_owner == "Guard" and not matching.active and defense.perfect_remaining == 0.15, "Old matching recovery cannot overwrite a new same-frame parry")
	check(demo.motion_tween == null or not demo.motion_tween.is_running(), "Active defense excludes the attack Tween writer")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	# Exact exhaustion and subsequent IDs, including repeats during break.
	defense._resource = 50
	enemy_detector._on_sample(940004, 0, timed_pose(inside, 0.3, enemy_window))
	var exhausting_event: Dictionary = enemy_detector.valid_events.back().duplicate()
	var break_time: float = defense.guard_break_remaining
	check(player_health.last_settlement["result"] == "Instinctive Defense" and player_health.hp == 100 and defense.pose_owner == "Guard Break", "Exact payment keeps exhausting result and hands animation to break")
	player_health._on_valid_contact(exhausting_event)
	check(defense.guard_break_remaining == break_time and defense.resource == 0, "Duplicate exhausting ID cannot restart break or pay again")
	Input.action_press("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(940005, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 95 and player_health.last_settlement["result"] == "Damage" and not demo.request_motion(1), "Independent same-frame hit after break damages; repeated inputs cannot bypass")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	check(defense.pose_owner == "Idle" and hand.transform.is_equal_approx(demo._idle_guard()), "F7 during break restores hand immediately")
	# Death during an unfinished guard raise clears both matching and defense writers.
	Input.action_press("active_defense")
	defense.refresh_input()
	player_health._hp = 5
	player.rotation.y = PI
	enemy_detector._on_sample(940006, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.dead and not defense.held and defense.instinctive_phase == "Idle" and not matching.active, "Lethal rear contact clears unfinished defense and matching immediately")
	check(not defense.attack_allowed() and not defense.defense_allowed() and not defense.matching_defense_active(), "Dead outranks every offensive and defensive permission")
	check(not defense.resolve_valid_contact(enemy, 5, 940007), "Direct defense entry cannot defend a new request while dead")
	Input.action_release("active_defense")
	await ticks(16)
	check(defense.pose_owner == "Idle" and hand.transform.is_equal_approx(demo._idle_guard()), "Death return finishes and releases hand control")
	health._unhandled_key_input(reset_key)
	player.rotation.y = 0 # F7 intentionally does not change actor orientation.
	# Reentrant F7 inside physical contact must abort the remaining valid sweep.
	enemy_detector.contact_detected.connect(func(_event): health._unhandled_key_input(reset_key), CONNECT_ONE_SHOT)
	enemy_detector._on_sample(940008, 0, timed_pose(inside, 0.3, enemy_window))
	check(enemy_detector.valid_events.is_empty() and player_health.last_settlement.is_empty() and player_health.hp == 100, "F7 inside physical-contact callback prevents old valid settlement")
	check(enemy_detector.current_request_id == 0 and enemy_detector.previous_sample.is_empty(), "F7 clears detector's in-flight request and samples")
	# Reentrant F7 while an attack ends cannot resurrect an automatic Tween/result.
	check(demo.request_motion(0), "Attack starts before reentrant transition reset")
	demo.motion_ended.connect(func(_id, _reason): health._unhandled_key_input(reset_key), CONNECT_ONE_SHOT)
	enemy_detector._on_sample(940009, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 100 and defense.resource == 100 and player_health.last_settlement.is_empty(), "F7 during attack interruption cancels the in-flight payment/result")
	check(defense.pose_owner == "Idle" and defense.instinctive_phase == "Idle" and demo.active_request_id == 0 and not demo.ending_record, "Reentrant reset leaves no old automatic or attack writer")
	await ticks(40)
	check(hand.transform.is_equal_approx(demo._idle_guard()) and not matching.active, "Reset pose survives later queued transitions")
	# Finish a normal attack, then F7 during its active window.
	check(demo.request_motion(1), "Normal attack permission recovers after reset")
	await ticks(40)
	check(defense.pose_owner == "Idle" and demo.active_request_id == 0, "Completed attack releases hand ownership")
	demo.request_motion(0)
	await ticks(10)
	check(demo.playback_state()["window_active"], "Reset fixture is inside the player active window")
	health._unhandled_key_input(reset_key)
	await ticks(40)
	check(not demo.window_live and demo.active_request_id == 0 and demo.lock_remaining == 0 and defense.pose_owner == "Idle", "F7 inside active window closes attack and clears all locks/writers")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Final: None") and trajectory.legend.text.contains("hand owner: Idle"), "F4 compact settlement and hand source are reset consistently")
	trajectory.debug_display_enabled = false
	# Diagnostic provenance uses the settled request, never another request's last_result.
	Input.action_press("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(940010, 0, timed_pose(inside, 0.3, enemy_window))
	var parry_event: Dictionary = enemy_detector.valid_events.back().duplicate()
	Input.action_release("active_defense")
	defense.refresh_input()
	defense._resource = 0
	enemy_detector._on_sample(940011, 0, timed_pose(inside, 0.3, enemy_window))
	clash.latest = {"request_id": 940010} # Only replay the diagnostic consumer, not detection.
	clash._on_valid_body(parry_event)
	check(clash.latest["defense_on_body_contact"] == "Perfect Parry" and clash.latest["damage_prevented"] == "YES", "Older diagnostic reads its own parry settlement after a later damaging request")
	health._unhandled_key_input(reset_key)
	# Force actual marker overlap solely to test F7 inside the clash signal.
	hand.global_transform = enemy.get_node("VisualRoot/RightHand").global_transform
	clash.clash_detected.connect(func(_event): health._unhandled_key_input(reset_key), CONNECT_ONE_SHOT)
	clash._start(940012)
	check(clash.events.is_empty() and clash.latest.is_empty() and clash.previous.is_empty(), "F7 inside real blade clash cannot repopulate old sweep history")
	check(trajectory.contact_markers.is_empty() and hand.transform.is_equal_approx(demo._idle_guard()), "Clash-triggered reset leaves no debug marker or old hand pose")
	# Step 13: single real Enemy reference, smooth orbit/heading and unchanged combat rules.
	reset_player()
	enemy.position = Vector3(0, 0, -1.5)
	enemy.rotation.y = PI
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	await ticks(30)
	check(InputMap.has_action("toggle_soft_lock"), "Soft Lock input action exists")
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	var r3 := InputEventJoypadButton.new()
	r3.button_index = JOY_BUTTON_RIGHT_STICK
	r3.pressed = true
	check(tab.is_action_pressed("toggle_soft_lock") and r3.is_action_pressed("toggle_soft_lock"), "Tab and Godot JOY_BUTTON_RIGHT_STICK map to lock toggle")
	check(not r3.is_action_pressed("ordinary_motion_request") and not r3.is_action_pressed("active_defense") and not tab.is_action_pressed("toggle_run"), "Lock input does not conflict with attack, defense or run")
	check(rig.lock_camera_follow_speed == 8 and rig.lock_character_turn_speed == 8 and rig.lock_target_height_offset == 0.85 and rig.lock_camera_shoulder_bias == 1, "Inspector lock defaults retain shoulder geometry")
	var free_view: Transform3D = camera.global_transform
	var stationary_position: Vector3 = player.position
	var requests_before_lock: int = demo.accepted_request_count
	player.rotation.y = 1.0
	rig._unhandled_input(tab)
	check(rig.is_locked() and rig.locked_target == enemy, "Tab locks actual Enemy rather than a surrogate")
	check(rig.lock_point().distance_to(enemy.to_global(Vector3.UP * 0.85)) < 0.001, "Lock point uses enemy body-center world transform")
	check(camera.global_transform.is_equal_approx(free_view) and player.rotation.y == 1, "Lock entry does not snap view or actor yaw")
	var echo_tab := tab.duplicate() as InputEventKey
	echo_tab.echo = true
	rig._unhandled_input(echo_tab)
	check(rig.is_locked(), "Tab key repeat does not repeatedly toggle lock")
	await ticks(1)
	check(player.rotation.y < 1 and player.rotation.y > 0.5 and is_zero_approx(player.rotation.x) and is_zero_approx(player.rotation.z), "Locked actor turns gradually in yaw only")
	await ticks(60)
	check(absf(player.rotation.y) < 0.02 and player.position.distance_to(stationary_position) < 0.001, "Stationary locked actor faces target without pursuit")
	check(demo.accepted_request_count == requests_before_lock and defense.resource == 100, "Lock alone creates no attack or automatic resource use")
	check(camera.is_position_in_frustum(rig.lock_point()), "Locked body-center target lies in camera frustum")
	check(camera.unproject_position(player.global_position + Vector3.UP * 1.55).x < root.size.x / 2, "Locked orbit retains player-left right-shoulder composition")
	check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE and absf(rig.spring_arm.spring_length - Vector2(1, 2.5).length()) < 0.001, "Lock preserves perspective and shoulder spring geometry")
	var yaw_offset_before: float = rig.lock_yaw_offset
	rig._apply_mouse_look(Vector2(30, -10))
	check(rig.lock_yaw_offset != yaw_offset_before and rig.is_locked(), "Mouse remains an adjustable offset during lock")
	Input.action_press("look_right")
	await ticks(8)
	Input.action_release("look_right")
	check(absf(rig.lock_yaw_offset) > 0.01 and rig.is_locked(), "Right-stick look remains active without unlocking")
	rig.lock_yaw_offset = 0
	rig.lock_pitch_offset = 0
	await ticks(30)
	var strafe_start: Vector3 = player.position
	Input.action_press("move_right")
	await ticks(30)
	Input.action_release("move_right")
	check(player.position.x > strafe_start.x + 0.5 and rig.is_locked(), "Locked camera-relative movement supports side stepping")
	var to_enemy: Vector3 = enemy.global_position - player.global_position
	to_enemy.y = 0
	check((-player.global_basis.z).dot(to_enemy.normalized()) > 0.95, "Strafing actor continues facing target rather than movement")
	var distance_before_back: float = player.global_position.distance_to(enemy.global_position)
	Input.action_press("move_back")
	await ticks(15)
	Input.action_release("move_back")
	check(player.global_position.distance_to(enemy.global_position) > distance_before_back + 0.25, "Locked player can back away without automatic approach")
	var forward_start: float = player.global_position.distance_to(enemy.global_position)
	Input.action_press("move_forward")
	await ticks(10)
	Input.action_release("move_forward")
	check(player.global_position.distance_to(enemy.global_position) < forward_start - 0.15, "Locked forward movement remains controlled by player input")
	var original_enemy_position: Vector3 = enemy.position
	var view_before_target_shift: Transform3D = camera.global_transform
	enemy.position.x += 1.0 # Fixture only: the real enemy remains stationary in gameplay.
	check(rig.lock_point().x == enemy.position.x, "Lock point immediately reflects target world-space change")
	await ticks(1)
	check(camera.global_position.distance_to(view_before_target_shift.origin) < 0.3, "Target-direction change is followed without camera position teleport")
	await ticks(60)
	check(camera.is_position_in_frustum(rig.lock_point()), "Orbit follows the actual target after direction changes")
	enemy.position = original_enemy_position
	trajectory.debug_display_enabled = true
	await ticks(2)
	check(trajectory.legend.text.contains("Soft Lock: true") and trajectory.legend.text.contains("target Enemy") and trajectory.legend.text.contains("yaw error") and trajectory.legend.text.contains("camera follow: true"), "F4 shows target, distance, angle and locked camera follow")
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible, "F4 off hides lock information")
	var unlock_view: Transform3D = camera.global_transform
	rig._unhandled_input(r3)
	check(not rig.is_locked() and camera.global_transform.is_equal_approx(unlock_view), "R3 unlocks without snapping camera")
	var unlocked_yaw: float = rig.target_yaw
	rig._apply_mouse_look(Vector2(20, 0))
	check(rig.target_yaw != unlocked_yaw, "Unlock restores original free mouse orbit")
	Input.action_press("move_left")
	await ticks(25)
	Input.action_release("move_left")
	check((-player.global_basis.z).dot(-camera.global_basis.x) > 0.85, "Unlocked actor again turns toward actual movement")
	# Locked combat uses exactly the existing shared motion/defense paths and values.
	reset_player()
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	health._unhandled_key_input(reset_key)
	await ticks(2)
	rig.toggle_soft_lock()
	await ticks(30)
	check(demo.request_ordinary_motion(), "Locked ordinary attack remains player-requested and available")
	await ticks(36)
	Input.action_press("active_defense")
	defense.refresh_input()
	inside = {"base": player.global_position + Vector3.UP * 0.4, "tip": player.global_position + Vector3.UP * 1.4}
	enemy_detector._on_sample(950001, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Perfect Parry" and defense.resource == 100, "Lock does not change active parry priority or free cost")
	await ticks(16)
	enemy_detector._on_sample(950002, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Block" and defense.resource == 75, "Locked held guard retains 25 resource cost")
	Input.action_release("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(950003, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Instinctive Defense" and defense.resource == 25 and rig.is_locked(), "Lock retains automatic defense's full 50 payment")
	await ticks(40)
	player.rotation.y += PI
	enemy_detector._on_sample(950004, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.last_settlement["result"] == "Damage", "Lock reference cannot bypass actual rear-facing defense cone")
	player.rotation.y -= PI
	defense._resource = 50
	enemy_detector._on_sample(950005, 0, timed_pose(inside, 0.3, enemy_window))
	var break_view: float = rig.rotation.y
	rig._apply_mouse_look(Vector2(50, 0))
	await ticks(5)
	check(defense.is_guard_broken() and rig.is_locked() and rig.rotation.y != break_view, "Guard Break leaves locked camera adjustment available")
	health._unhandled_key_input(reset_key)
	check(not rig.is_locked() and rig.locked_target == null, "F7 restores explicitly unlocked state")
	rig.toggle_soft_lock()
	var facing_before_death: float = player.rotation.y
	player_health.dead = true
	await ticks(3)
	check(player.rotation.y == facing_before_death and not rig.is_locked(), "Dead actor is not forced to turn and lock is cleared")
	health._unhandled_key_input(reset_key)
	rig.toggle_soft_lock()
	for id in range(960001, 960005):
		health._on_valid_contact({"request_id": id, "contact_kind": "valid_attack", "target": enemy})
	check(health.dead and not rig.is_locked() and rig.locked_target == null, "Actual enemy HP death signal immediately releases target reference")
	check(not rig.toggle_soft_lock(), "Dead enemy cannot be reacquired")
	health._unhandled_key_input(reset_key)
	check(rig.toggle_soft_lock() and rig.locked_target == enemy, "Reset enemy may be manually locked again")
	# Step 14: current 10/10 values and full single-target soft-lock behavior.
	health.test_damage = 10
	defense.held_guard_cost = 10
	health._unhandled_key_input(reset_key)
	reset_player()
	enemy.position = Vector3(0, 0, -1.5)
	await ticks(30)
	check(defense.held_guard_cost == 10 and health.test_damage == 10 and health.max_hp == 100 and player_health.max_hp == 100 and player_health.incoming_test_damage == 5, "Current 10/10 tuning preserves both HP maxima and 5 HP enemy damage")
	var current_enemy_body := blade_pose(enemy.global_position + Vector3.UP * 0.4, enemy.global_position + Vector3.UP * 1.4)
	for hit in range(10):
		detector._on_sample(970001 + hit, hit % 3, timed_pose(current_enemy_body, 0.2, Vector2(0.12, 0.26)))
		check(health.hp == 100 - (hit + 1) * 10, "Current valid blade contact removes exactly 10 HP: " + str(hit))
		health._on_valid_contact(detector.valid_events.back())
		check(health.hp == 100 - (hit + 1) * 10, "Same attack request cannot charge damage twice: " + str(hit))
		if hit < 9: check(not health.dead, "Enemy stays alive before tenth 10 HP hit")
	check(health.dead and health.last_damage == 10, "Full enemy needs ten current effective hits")
	health._unhandled_key_input(reset_key)
	Input.action_press("active_defense")
	await ticks(16)
	inside = blade_pose(player.global_position + Vector3.UP * 0.4, player.global_position + Vector3.UP * 1.4)
	for hit in range(10):
		enemy_detector._on_sample(980001 + hit, 0, timed_pose(inside, 0.3, enemy_window))
		check(defense.resource == 100 - (hit + 1) * 10 and player_health.hp == 100, "Current held block costs 10 while preventing damage: " + str(hit))
		player_health._on_valid_contact(enemy_detector.valid_events.back())
		check(defense.resource == 100 - (hit + 1) * 10, "Current block remains independently deduplicated")
	check(defense.is_guard_broken() and defense.last_break_request_id == 980010, "Tenth current held block exhausts resource and starts unchanged break")
	enemy_detector._on_sample(980011, 0, timed_pose(inside, 0.3, enemy_window))
	check(player_health.hp == 95, "Independent contact after current-value exhaustion still injures for 5")
	Input.action_release("active_defense")
	health._unhandled_key_input(reset_key)
	check(rig.mode_name() == "Free Camera" and not rig.is_locked() and rig.overrun_elapsed == 0 and not rig.reacquire_armed, "F7 resets lock mode, intent timer and rearm state")
	check(rig.lock_yaw_limit_degrees == 40 and rig.lock_overrun_seconds == 0.5 and rig.reacquire_camera_degrees == 40 and rig.reacquire_movement_degrees == 20, "Loaded arena inherits Inspector thresholds 40/0.5/40/20")
	var a179 := -Basis(Vector3.UP, deg_to_rad(179)).z
	var b179 := -Basis(Vector3.UP, deg_to_rad(-179)).z
	check(absf(absf(rig.horizontal_angle(a179, b179)) - 2) < 0.001, "Horizontal angle reliably crosses plus/minus 180 without 358-degree error")
	check(rig._angle_response(0.25) == 0.25, "Absent Curve preserves linear angle response")
	rig.toggle_soft_lock()
	rig._apply_mouse_look(Vector2(-1000, 0))
	await ticks(1)
	check(rig.is_locked() and absf(rad_to_deg(rig.lock_yaw_offset) - 40) < 0.001 and rig.overrun_elapsed < 0.03, "Single-frame mouse overrun clamps at 40 but does not unlock")
	await ticks(2)
	check(rig.overrun_elapsed == 0 and rig.is_locked(), "Stopping mouse overrun clears time even while offset stays at boundary")
	for _frame in range(20):
		rig._apply_mouse_look(Vector2(-2, 0))
		await ticks(1)
	check(rig.is_locked() and absf(rig.overrun_elapsed - 20.0 / 60) < 0.02, "Sustained mouse intent accumulates independently of clamped angle")
	rig._apply_mouse_look(Vector2(5, 0))
	await ticks(1)
	check(rig.overrun_elapsed == 0 and rig.is_locked(), "Inward input clears overrun accumulation")
	for _frame in range(27):
		rig._apply_mouse_look(Vector2(-10, 0))
		await ticks(1)
	check(rig.is_locked(), "Mouse overrun below 0.5 seconds retains lock")
	for _frame in range(6):
		rig._apply_mouse_look(Vector2(-10, 0))
		await ticks(1)
	check(not rig.is_locked() and rig.mode_name() == "Orient to Movement" and rig.last_unlock_reason == "Sustained boundary input", "Continuous mouse overrun releases into Orient to Movement")
	var stationary_heading: float = player.rotation.y
	await ticks(10)
	check(player.rotation.y == stationary_heading and not rig.is_locked(), "Unlocked stationary actor is not forcibly reoriented or recaptured")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig.toggle_soft_lock()
	rig.lock_yaw_offset = deg_to_rad(-40)
	Input.action_press("look_right")
	await ticks(29)
	check(rig.is_locked() and rig.overrun_elapsed > 0.47, "Right-stick outward intent remains locked just before 0.5 seconds")
	await ticks(1)
	Input.action_release("look_right")
	check(not rig.is_locked() and rig.mode_name() == "Orient to Movement", "Right stick releases at configured 0.5 seconds")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig.toggle_soft_lock()
	for _frame in range(6):
		rig._apply_mouse_look(Vector2(-1000 if _frame % 2 == 0 else 1000, 0))
		await ticks(1)
	check(rig.overrun_elapsed < 0.04 and rig.is_locked(), "Changing overrun side restarts intent rather than accumulating jitter")
	# No fixed cooldown: eligibility must leave then re-enter after either unlock path.
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig.toggle_soft_lock()
	Input.action_press("move_forward")
	await ticks(3)
	rig.toggle_soft_lock()
	await ticks(4)
	check(not rig.is_locked() and rig.mode_name() == "Orient to Movement" and rig.camera_condition and rig.movement_condition and not rig.reacquire_armed, "Manual release cannot instantly relock while both conditions remain true")
	Input.action_release("move_forward")
	await ticks(1)
	check(rig.reacquire_armed and not rig.movement_condition, "Condition exit arms recapture without a timed cooldown")
	var recapture_view: Vector3 = camera.global_position
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and camera.global_position.distance_to(recapture_view) < 0.2, "Fresh simultaneous conditions recapture smoothly on the next physics frame")
	await ticks(30)
	check(rig.is_locked() and rig.overrun_elapsed == 0, "Recaptured stationary lock remains stable without alternating states")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig._release_lock("Angle fixture")
	Input.action_press("move_right")
	await ticks(3)
	Input.action_release("move_right")
	check(not rig.is_locked() and rig.camera_condition and not rig.movement_condition, "Camera cone alone cannot reacquire sideways movement")
	reset_player()
	await ticks(2)
	rig.rotation.y = deg_to_rad(120)
	rig.target_yaw = rig.rotation.y
	Input.action_press("move_back")
	Input.action_press("move_right")
	await ticks(3)
	Input.action_release("move_back")
	Input.action_release("move_right")
	check(not rig.is_locked() and not rig.camera_condition and rig.movement_condition, "Movement cone alone cannot reacquire with camera outside cone")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	Input.action_press("move_forward")
	await ticks(5)
	Input.action_release("move_forward")
	check(rig.mode_name() == "Free Camera" and not rig.is_locked(), "Reset Free Camera prohibits spontaneous capture even with eligible movement")
	# Optional local Curve, with monotonic bounded response and linear fallback.
	var response := Curve.new()
	response.add_point(Vector2(0, 0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	response.add_point(Vector2(0.5, 0.25), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	response.add_point(Vector2(1, 1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	rig.lock_angle_response_curve = response
	check(absf(rig._angle_response(0.5) - 0.25) < 0.001 and rig._angle_response(1) == 1, "Optional Curve shapes response without changing boundary endpoint")
	rig.toggle_soft_lock()
	rig.lock_yaw_offset = deg_to_rad(20)
	await ticks(60)
	check(absf(absf(rig.horizontal_deviation()) - 10) < 0.1, "Nonlinear Curve is locally applied to desired yaw offset")
	rig.lock_yaw_offset = deg_to_rad(40)
	await ticks(60)
	check(absf(absf(rig.horizontal_deviation()) - 40) < 0.1 and rig.is_locked() and rig.overrun_elapsed == 0, "Curve keeps 40-degree boundary; angle alone never starts unlock timer")
	var invalid_response := Curve.new()
	invalid_response.add_point(Vector2(0, 1))
	invalid_response.add_point(Vector2(1, 0))
	rig.lock_angle_response_curve = invalid_response
	check(rig._angle_response(0.25) == 0.25, "Invalid/reversed Curve safely falls back to linear response")
	rig.lock_angle_response_curve = null
	# Current-value combat remains independent of view mode, including re-acquisition.
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig.toggle_soft_lock()
	check(demo.request_ordinary_motion(), "Current-tuning ordinary attack remains available in full lock")
	await ticks(36)
	Input.action_press("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(990001, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Perfect Parry" and defense.resource == 100, "Full lock retains free precise defense")
	await ticks(16)
	enemy_detector._on_sample(990002, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Block" and defense.resource == 90, "Full lock uses current 10 resource held cost")
	Input.action_release("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(990003, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Instinctive Defense" and defense.resource == 40, "Full lock preserves unchanged full 50 automatic payment")
	rig._release_lock("Combat fixture")
	check(not demo.request_ordinary_motion(), "Unlock does not bypass automatic reaction attack restrictions")
	await ticks(40)
	check(demo.request_ordinary_motion(), "Attack permissions return normally in Orient to Movement")
	await ticks(40)
	Input.action_press("active_defense")
	defense.refresh_input()
	await ticks(16)
	enemy_detector._on_sample(990004, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Block", "Unlocked held guard remains functional")
	Input.action_release("active_defense")
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked(), "Combat does not prevent fresh eligible automatic capture")
	defense._resource = 10
	Input.action_press("active_defense")
	defense.refresh_input()
	await ticks(16)
	enemy_detector._on_sample(990005, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.is_guard_broken() and rig.is_locked() and player_health.hp == 100, "Current cost exhausts held guard without altering exhausting-hit prevention")
	Input.action_release("active_defense")
	Input.action_press("move_right")
	Input.action_press("look_left")
	await ticks(4)
	Input.action_release("move_right")
	Input.action_release("look_left")
	check(defense.is_guard_broken() and rig.is_locked(), "Break permits view adjustment and manual movement in full lock")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Mode: Soft Lock") and trajectory.legend.text.contains("overrun") and trajectory.legend.text.contains("Held cost: 10") and trajectory.legend.text.contains("Player damage: 10"), "F4 reports mode, overrun and current combat values")
	rig._release_lock("Debug fixture")
	await ticks(1)
	check(trajectory.legend.text.contains("Reacquire: camera") and trajectory.legend.text.contains("move") and trajectory.legend.text.contains("release: Debug fixture"), "F4 displays both recapture angle tests and last release reason")
	trajectory.debug_display_enabled = false
	health._unhandled_key_input(reset_key)
	check(rig.mode_name() == "Free Camera" and rig.last_unlock_reason == "None" and rig.overrun_elapsed == 0 and not rig.reacquire_armed and not rig.mouse_overrun_intent, "F7 clears all full-lock temporary intent/history and inhibits automatic capture")
	check(health.test_damage == 10 and defense.held_guard_cost == 10 and defense.instinctive_cost == 50, "F7 preserves Inspector's accepted current tuning")
	# Step 15: normal Free Camera acquisition and shared re-acquisition with source labels.
	rig.initial_auto_acquisition_enabled = true
	health._unhandled_key_input(reset_key)
	reset_player()
	enemy.position = Vector3(0, 0, -1.5)
	await ticks(30)
	check(rig.mode_name() == "Free Camera" and not rig.is_locked() and not rig.movement_condition, "Free Camera without movement cannot acquire from stale actor facing")
	var initial_view: Transform3D = camera.global_transform
	var auto_requests_before: int = demo.accepted_request_count
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and rig.locked_target == enemy and rig.last_lock_event == "Auto Acquisition", "Initial Free Camera acquires actual enemy without Tab or R3")
	check(camera.global_position.distance_to(initial_view.origin) < 0.15, "First automatic acquisition preserves smooth shoulder-camera entry")
	await ticks(2)
	var auto_stationary_position: Vector3 = player.position
	await ticks(30)
	check(player.position.distance_to(auto_stationary_position) < 0.001 and demo.accepted_request_count == auto_requests_before, "Automatic acquisition cannot pursue or request a player attack")
	check(defense.resource == 100 and player_health.hp == 100 and health.hp == 100, "Lock acquisition alone never settles defense, resource or damage")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("event: Auto Acquisition"), "F4 identifies first automatic acquisition")
	trajectory.debug_display_enabled = false
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	Input.action_press("move_right")
	await ticks(3)
	Input.action_release("move_right")
	check(not rig.is_locked() and rig.camera_condition and not rig.movement_condition, "First acquisition rejects camera-only eligibility")
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	rig.rotation.y = deg_to_rad(120)
	rig.target_yaw = rig.rotation.y
	Input.action_press("move_back")
	Input.action_press("move_right")
	await ticks(3)
	Input.action_release("move_back")
	Input.action_release("move_right")
	check(not rig.is_locked() and not rig.camera_condition and rig.movement_condition, "First acquisition rejects movement-only eligibility outside camera cone")
	var manual_auto_view: Transform3D = camera.global_transform
	rig._unhandled_input(tab)
	check(rig.is_locked() and rig.last_lock_event == "Manual Acquisition" and camera.global_transform.is_equal_approx(manual_auto_view), "Manual acquisition remains available outside automatic cones without snapping")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("event: Manual Acquisition"), "F4 distinguishes manual acquisition")
	trajectory.debug_display_enabled = false
	health._unhandled_key_input(reset_key)
	reset_player()
	await ticks(30)
	Input.action_press("move_forward")
	await ticks(3)
	rig._unhandled_input(r3)
	await ticks(4)
	check(not rig.is_locked() and rig.mode_name() == "Orient to Movement" and rig.last_lock_event == "Manual Unlock" and not rig.reacquire_armed, "Manual unlock cannot bypass condition-exit protection via initial acquisition")
	check(rig.camera_condition and rig.movement_condition, "Manual-unlock protection applies even while both automatic angles pass")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("event: Manual Unlock"), "F4 identifies manual unlock")
	trajectory.debug_display_enabled = false
	Input.action_release("move_forward")
	await ticks(1)
	check(rig.reacquire_armed, "A genuine condition exit re-arms automatic reacquisition")
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and rig.last_lock_event == "Auto Reacquisition", "Fresh simultaneous eligibility uses shared entry with reacquisition source")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("event: Auto Reacquisition"), "F4 distinguishes automatic reacquisition")
	trajectory.debug_display_enabled = false
	rig.lock_yaw_offset = deg_to_rad(40)
	for _frame in range(30):
		rig._apply_mouse_look(Vector2(-2, 0))
		await ticks(1)
	check(not rig.is_locked() and rig.last_lock_event == "Boundary Unlock" and rig.lock_overrun_seconds == 0.5, "Automatic lock preserves latest 0.5 s boundary release and source")
	await ticks(20)
	check(not rig.is_locked() and rig.mode_name() == "Orient to Movement", "Boundary unlock is stable while movement criterion remains absent")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("event: Boundary Unlock"), "F4 identifies boundary unlock")
	trajectory.debug_display_enabled = false
	rig.target_yaw = 0
	await ticks(60)
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and rig.last_lock_event == "Auto Reacquisition", "Boundary release allows reacquisition only after newly satisfied conditions")
	# Current combat remains independent of acquisition source.
	health._unhandled_key_input(reset_key)
	reset_player()
	enemy.position = player.position + Vector3(0.24, 0, -0.9)
	await ticks(30)
	Input.action_press("move_forward")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and rig.last_lock_event == "Auto Acquisition", "Initial auto acquisition works at current combat-test distance")
	check(demo.request_ordinary_motion(), "Automatically acquired lock preserves ordinary player-requested attack")
	await ticks(36)
	inside = blade_pose(player.global_position + Vector3.UP * 0.4, player.global_position + Vector3.UP * 1.4)
	Input.action_press("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(1100001, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Perfect Parry" and defense.resource == 100, "Automatic acquisition does not alter free perfect parry")
	await ticks(16)
	enemy_detector._on_sample(1100002, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Block" and defense.resource == 90, "Automatically acquired lock preserves 10 Resource held block")
	Input.action_release("active_defense")
	defense.refresh_input()
	enemy_detector._on_sample(1100003, 0, timed_pose(inside, 0.3, enemy_window))
	check(defense.last_result == "Instinctive Defense" and defense.resource == 40, "Automatically acquired lock preserves full 50 automatic defense")
	health._unhandled_key_input(reset_key)
	check(not rig.is_locked() and rig.locked_target == null and rig.last_lock_event == "None", "F7 immediately clears reference and acquisition-source records")
	await ticks(2)
	check(not rig.is_locked(), "F7 with no movement stays in initial Free Camera")
	player_health.dead = true
	var dead_auto_heading: float = player.rotation.y
	Input.action_press("move_forward")
	await ticks(2)
	check(not rig.is_locked() and player.rotation.y == dead_auto_heading, "Player death prevents automatic acquisition and forced turn")
	health._unhandled_key_input(reset_key)
	check(not rig.is_locked() and rig.locked_target == null, "F7 while moving still clears lock synchronously")
	await ticks(1)
	Input.action_release("move_forward")
	check(rig.is_locked() and rig.last_lock_event == "Auto Acquisition" and rig.locked_target == enemy, "Post-reset fresh moving frame may reacquire only a valid living target")
	for id in range(1200001, 1200011):
		health._on_valid_contact({"request_id": id, "contact_kind": "valid_attack", "target": enemy})
	check(health.dead and not rig.is_locked() and rig.locked_target == null, "Enemy death clears an automatically acquired target immediately")
	Input.action_press("move_forward")
	await ticks(3)
	Input.action_release("move_forward")
	check(not rig.is_locked(), "Dead target cannot be automatically acquired despite moving input")
	health._unhandled_key_input(reset_key)
	check(rig.toggle_soft_lock(), "Manual acquisition remains available for valid reset target")
	# Step 16: manual enemy guard, shared real blade sweep, independent settlement.
	health._unhandled_key_input(reset_key)
	rig.initial_auto_acquisition_enabled = false
	reset_player()
	enemy_attack.enabled = false
	var enemy_guard: Node = enemy.get_node("DebugDefense")
	enemy_hand = enemy.get_node("VisualRoot/RightHand")
	check(not enemy_guard.enemy_debug_guard_enabled and enemy_guard.state_name() == "Not Guarding", "Enemy guard defaults off")
	check(enemy_guard.enemy_guard_arc == 60 and enemy_guard.guard_enter_duration > 0 and enemy_guard.guard_exit_duration > 0, "Enemy guard Inspector defaults are bounded temporary values")
	await ticks(30)
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	enemy.rotation.y = PI
	await ticks(2)
	var unguarded_request: int = demo.accepted_request_count + 1
	check(demo.request_motion(0), "Default enemy behavior accepts existing thrust")
	await ticks(60)
	check(health.hp == 90 and health.last_settlement.get("request_id") == unguarded_request, "Default real thrust still removes exactly 10 HP")
	health._unhandled_key_input(reset_key)
	var enemy_guard_key := InputEventKey.new()
	enemy_guard_key.physical_keycode = KEY_KP_0
	enemy_guard_key.keycode = KEY_KP_0
	enemy_guard_key.unicode = 48 # Num Lock on: numeric keypad event producing the character 0.
	enemy_guard_key.pressed = true
	check(InputMap.has_action("debug_toggle_enemy_guard") and InputMap.event_is_action(enemy_guard_key, "debug_toggle_enemy_guard"), "Num Lock-on KP 0 maps to Enemy Debug Guard")
	check(not InputMap.get_actions().any(func(action: StringName) -> bool: return action != &"debug_toggle_enemy_guard" and InputMap.event_is_action(enemy_guard_key, action)), "KP 0 conflicts with no other project action")
	var guard_bindings: Array[InputEvent] = InputMap.action_get_events("debug_toggle_enemy_guard")
	check(guard_bindings.size() == 1 and guard_bindings[0] is InputEventKey and guard_bindings[0].physical_keycode == KEY_KP_0 and guard_bindings[0].keycode == 0, "Enemy guard uses only physical keypad 0, not logical/top-row 0")
	for old_guard_code in [KEY_0, KEY_F8, KEY_SEMICOLON]:
		var wrong_guard_key := InputEventKey.new()
		wrong_guard_key.physical_keycode = old_guard_code
		wrong_guard_key.keycode = old_guard_code
		wrong_guard_key.pressed = true
		enemy_guard._unhandled_key_input(wrong_guard_key)
		check(not enemy_guard.guarding and not enemy_guard.enemy_debug_guard_enabled and not InputMap.event_is_action(wrong_guard_key, "debug_toggle_enemy_guard"), "Non-keypad/old key cannot toggle guard: " + str(old_guard_code))
	var reserved_guard_key := InputEventKey.new()
	reserved_guard_key.physical_keycode = KEY_F8
	var reserved_guard_conflict: bool = InputMap.event_is_action(reserved_guard_key, "debug_toggle_enemy_guard")
	reserved_guard_key.physical_keycode = KEY_F9
	check(not reserved_guard_conflict and not InputMap.event_is_action(reserved_guard_key, "debug_toggle_enemy_guard"), "Editor Stop and breakpoint keys are not enemy guard inputs")
	var start_guard_pose: Transform3D = enemy_hand.transform
	enemy_guard._unhandled_key_input(enemy_guard_key)
	check(enemy_guard.guarding and enemy_guard.owns_hand and enemy_guard.enemy_debug_guard_enabled, "Num Lock-on KP 0 begins enemy guard with sole hand ownership")
	check(enemy_hand.transform.is_equal_approx(start_guard_pose), "Guard entry starts at current pose without snap")
	check(not enemy_attack.start_attack() and not enemy_attack.start_sequence(), "Guard blocks both single swing and new burst")
	await ticks(15)
	check(enemy_hand.transform.is_equal_approx(enemy_attack._pose(enemy_guard.guard_hand_position, enemy_guard.guard_hand_rotation_degrees)), "Guard reaches exported pose even with attack logic disabled")
	var guarded_enemy_root: Transform3D = enemy.global_transform
	var enemy_guard_real_clashes := 0
	check(enemy_guard.contact_matching_enabled, "Enemy contact matching is enabled by default")
	for motion_id in [0, 1, 2]:
		check(demo.request_motion(motion_id), "Guard fixture accepts player motion " + str(motion_id))
		var guard_id: int = demo.active_request_id
		var enemy_match_seen := false
		var enemy_match_safe := true
		var enemy_match_limited := true
		var enemy_match_previous: Transform3D = enemy_hand.transform
		var enemy_match_peak_step := 0.0
		var enemy_match_peak_turn := 0.0
		var enemy_match_peak_correction := 0.0
		var enemy_match_baseline: Transform3D = enemy_attack._pose(enemy_guard.guard_hand_position, enemy_guard.guard_hand_rotation_degrees)
		for _match_frame in 60:
			await ticks(1)
			enemy_match_seen = enemy_match_seen or enemy_guard.matching_active
			var enemy_match_offsets: Array[Vector3] = enemy_guard._blade_offsets()
			enemy_match_safe = enemy_match_safe and matching.safe_contact_pose(enemy_hand.transform, enemy_match_offsets[0], enemy_match_offsets[1])
			var correction := enemy_hand.position.distance_to(enemy_match_baseline.origin)
			enemy_match_peak_correction = maxf(enemy_match_peak_correction, correction)
			enemy_match_limited = enemy_match_limited and correction <= enemy_guard.matching_max_position + 0.0001 and rad_to_deg(enemy_match_baseline.basis.get_rotation_quaternion().angle_to(enemy_hand.basis.get_rotation_quaternion())) <= enemy_guard.matching_max_rotation_degrees + 0.001
			enemy_match_peak_step = maxf(enemy_match_peak_step, enemy_hand.position.distance_to(enemy_match_previous.origin))
			enemy_match_peak_turn = maxf(enemy_match_peak_turn, enemy_match_previous.basis.get_rotation_quaternion().angle_to(enemy_hand.basis.get_rotation_quaternion()))
			enemy_match_previous = enemy_hand.transform
		check(enemy_match_seen and enemy_guard.matching_request_id == guard_id, "Enemy observes actual player request for matching: " + str(motion_id))
		check(enemy_match_safe and enemy_match_limited, "Entire matching/recovery path respects body clearance and correction limits: " + str(motion_id))
		check(enemy_match_peak_step <= enemy_guard.matching_hand_speed / Engine.physics_ticks_per_second + 0.0001 and enemy_match_peak_turn <= deg_to_rad(enemy_guard.matching_rotation_speed_degrees) / Engine.physics_ticks_per_second + 0.001, "Matching/recovery per-frame speed is bounded: " + str(motion_id))
		check(not enemy_guard.matching_active and enemy_hand.transform.is_equal_approx(enemy_match_baseline), "Enemy releases matching and smoothly returns after each request")
		if motion_id == 2: check(enemy_match_peak_correction > 0.01, "Broad Cut requires actual dynamic hand correction, not fixed-pose event")
		var guard_hits: Array = detector.valid_events.filter(func(event: Dictionary) -> bool: return event["request_id"] == guard_id)
		check(guard_hits.size() == 1 and health.hp == 100, "Actual valid frontal motion is guarded once: " + str(motion_id))
		check(health.last_settlement.get("result") == "Successful Guard" and enemy_guard.last_front and health.last_damage == 0, "Guard settlement uses actual enemy front, not clash: " + str(motion_id))
		check(clash.player_latest.get("request_id") == guard_id, "Each player swing has independent clash record")
		var guard_clashes: Array = clash.events.filter(func(event: Dictionary) -> bool: return event.get("attack_side") == "Player" and event["request_id"] == guard_id)
		check(guard_clashes.size() <= 1, "Player swing clash deduplicates independently")
		check(guard_clashes.size() == 1, "Dynamic enemy guard has genuine clash for native motion " + str(motion_id))
		enemy_guard_real_clashes += guard_clashes.size()
		print("STEP16_NATIVE_MOTION ", motion_id, " body=", guard_hits.size(), " clash=", guard_clashes.size())
		if not guard_hits.is_empty(): health._on_valid_contact(guard_hits[0])
		check(health.hp == 100 and health.last_settlement.get("request_id") == guard_id, "Repeated valid callback cannot resettle guarded request")
		check(enemy.global_transform.is_equal_approx(guarded_enemy_root) and enemy_hand.get_node("Gunblade").transform == Transform3D.IDENTITY, "Guard retains root and hand attachment")
	print("STEP16_NATIVE_GUARD_CLASHES ", enemy_guard_real_clashes, " / 3 motions")
	check(enemy_guard_real_clashes == 3, "Dynamic guard covers all three unchanged trajectories at reference stance")
	# Separate geometry proof: real markers overlap, then miss; no state-only event.
	var saved_player_hand: Transform3D = hand.global_transform
	hand.global_transform = enemy_hand.global_transform
	clash._start_player(2100001, 0)
	clash._sample_player(2100001, 0, {})
	check(clash.player_latest["blade_contact"] and clash.events.back().get("attack_side") == "Player", "Actual overlapping blade markers emit player-side clash")
	clash._sample_player(2100001, 0, {})
	check(clash.events.filter(func(event: Dictionary) -> bool: return event["request_id"] == 2100001).size() == 1, "Actual overlap cannot repeat same player clash")
	hand.global_position += Vector3.UP * 10
	clash._start_player(2100002, 0)
	clash._sample_player(2100002, 0, {})
	check(not clash.player_latest["blade_contact"], "Held Guard alone cannot fabricate a blade clash")
	hand.global_transform = saved_player_hand
	var physical_guard := {"request_id": 2100010, "contact_kind": "physical", "target": enemy}
	var before_guard_record: int = enemy_guard.last_request_id
	health._on_valid_contact(physical_guard)
	check(enemy_guard.last_request_id == before_guard_record and health.hp == 100, "Physical-only contact cannot settle enemy defense")
	var frontal_guard := {"request_id": 2100011, "contact_kind": "valid_attack", "target": enemy}
	health._on_valid_contact(frontal_guard)
	check(health.hp == 100 and health.last_settlement["result"] == "Successful Guard" and not clash.player_latest["blade_contact"], "Successful Guard remains independent of Actual Blade Clash")
	enemy.rotation.y = 0
	var rear_guard := {"request_id": 2100012, "contact_kind": "valid_attack", "target": enemy}
	health._on_valid_contact(rear_guard)
	check(health.hp == 90 and not enemy_guard.last_front, "Rear valid attack bypasses frontal guard")
	enemy.rotation.y = PI * 0.5
	health._on_valid_contact({"request_id": 2100013, "contact_kind": "valid_attack", "target": enemy})
	check(health.hp == 80 and not enemy_guard.last_front, "Side valid attack bypasses frontal guard")
	enemy.rotation.y = PI
	health._on_valid_contact(rear_guard)
	check(health.hp == 80 and health.last_settlement["request_id"] == 2100013, "Changing yaw after damage cannot settle same request again")
	# Rear geometry also uses the unchanged real blade-to-body detector.
	enemy.rotation.y = 0
	check(demo.request_motion(0), "Rear-side fixture accepts real thrust")
	await ticks(60)
	check(health.hp == 70 and health.last_damage == 10 and not enemy_guard.last_front, "Actual rear thrust damages guarding enemy without hit-time rotation")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("KP 0 Enemy Guard: Held Guard") and trajectory.legend.text.contains("Player swing actual Blade Clash"), "F4 exposes guard and separate player-side clash")
	check(trajectory.legend.text.contains("Enemy Matching:"), "F4 distinguishes enemy matching state from actual clash")
	trajectory.debug_display_enabled = false
	check(not trajectory.legend.visible and not trajectory.lines.visible, "F4 off hides all enemy-guard feedback")
	var enemy_guard_exit_pose: Transform3D = enemy_hand.transform
	enemy_guard.set_guard_enabled(false)
	check(not enemy_guard.guarding and enemy_guard.owns_hand and enemy_hand.transform.is_equal_approx(enemy_guard_exit_pose), "Guard exit releases judgment immediately but preserves hand until return")
	check(not enemy_attack.start_attack(), "Attack cannot overwrite unfinished guard exit")
	await ticks(20)
	check(not enemy_guard.owns_hand and enemy_hand.transform.is_equal_approx(enemy_attack.idle), "Exit completes and releases hand to existing attacker")
	enemy_attack.enabled = true
	enemy_attack.cooldown = 100
	check(enemy_attack.start_attack(), "Existing attack resumes after guard exit")
	var rejected_id: int = enemy_attack.active_request_id
	var attack_hand_before: Transform3D = enemy_hand.transform
	check(not enemy_guard.set_guard_enabled(true) and not enemy_guard.guarding and not enemy_guard.enemy_debug_guard_enabled, "Enabling guard during a swing is consistently rejected")
	check(enemy_attack.active_request_id == rejected_id and enemy_hand.transform.is_equal_approx(attack_hand_before), "Rejected toggle leaves attack ID and pose untouched")
	health._unhandled_key_input(reset_key)
	enemy_attack.cooldown = 100
	check(enemy_guard.set_guard_enabled(true), "Guard can enter after reset when no swing is active")
	await ticks(3)
	health._unhandled_key_input(reset_key)
	check(not enemy_guard.owns_hand and not enemy_guard.guarding and not enemy_guard.enemy_debug_guard_enabled and enemy_hand.transform.is_equal_approx(enemy_attack.idle), "F7 mid-entry clears toggle, ownership and pose")
	check(clash.player_records.is_empty() and clash.player_latest.is_empty() and health.last_settlement.is_empty() and enemy_guard.last_result == "None", "F7 clears player-side clash and enemy settlement records")
	await ticks(20)
	check(not enemy_guard.owns_hand and enemy_guard.state_name() == "Not Guarding", "Reset cannot resurrect a guard tween")
	# Reset during real dynamic correction; no old target or hand writer survives.
	enemy_attack.enabled = false
	enemy.rotation.y = PI
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	demo.request_motion(2)
	await ticks(2)
	check(enemy_guard.matching_active and enemy_guard.matching_request_id == demo.active_request_id, "F7 fixture is actively matching Broad Cut")
	health._unhandled_key_input(reset_key)
	check(not enemy_guard.matching_active and enemy_guard.matching_request_id == 0 and enemy_guard.matching_target == Vector3.ZERO and enemy_guard.matching_completed_request == 0, "F7 clears live matching and completed-contact target")
	await ticks(3)
	check(enemy_hand.transform.is_equal_approx(enemy_attack.idle) and not enemy_guard.owns_hand, "Deferred matching cannot resurrect guard after reset")
	# Unreachable/out-of-cone geometry remains honest and never forces a pose.
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	enemy.rotation.y = 0
	demo.request_motion(2)
	await ticks(15)
	check(not enemy_guard.matching_active and enemy_hand.transform.is_equal_approx(enemy_attack._pose(enemy_guard.guard_hand_position, enemy_guard.guard_hand_rotation_degrees)), "Back-facing guard cannot track player blade")
	health._unhandled_key_input(reset_key)
	enemy.rotation.y = PI
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	var unreachable_matching_enemy: Vector3 = enemy.position
	enemy.position += Vector3(0, 0, -5)
	demo.request_motion(2)
	await ticks(15)
	check(enemy_guard.matching_active and enemy_guard.matching_result == "Failed" and not clash.player_latest["blade_contact"], "Unreachable attack reports matching failure without fabricated clash")
	health._unhandled_key_input(reset_key)
	enemy.position = unreachable_matching_enemy
	enemy_attack.enabled = false
	enemy_guard.set_guard_enabled(true)
	enemy.rotation.y = 0
	for id in range(2100100, 2100110):
		health._on_valid_contact({"request_id": id, "contact_kind": "valid_attack", "target": enemy})
	check(health.dead and not enemy_guard.guarding and not enemy_guard.owns_hand and not enemy_guard.enemy_debug_guard_enabled, "Enemy death stops guard and releases pending pose")
	check(not enemy_guard.set_guard_enabled(true), "Dead enemy cannot re-enter guard")
	health._unhandled_key_input(reset_key)
	rig.initial_auto_acquisition_enabled = true
	check(rig.toggle_soft_lock(), "Soft Lock still uses living original enemy after defense reset")
	check(demo.request_ordinary_motion(), "Existing automatic player move selection remains available")
	health._unhandled_key_input(reset_key)
	check(rig.toggle_soft_lock(), "Final freed-target fixture retains original lock behavior")
	# Step 17: real motion recognition, delayed defense and manual override arbitration.
	health._unhandled_key_input(reset_key)
	rig.initial_auto_acquisition_enabled = false
	reset_player()
	await ticks(30)
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	enemy.rotation.y = PI
	enemy_attack.enabled = false
	enemy_guard.auto_defense_enabled = true
	check(enemy_guard.reaction_delay == 0.20 and enemy_guard.guard_hold_duration == 0.35 and enemy_guard.threat_distance == 2.0, "Auto-defense Inspector defaults are 0.20/0.35 seconds and 2 m range")
	await ticks(2)
	enemy_guard._on_player_attack_started(demo.accepted_request_count + 1, 2)
	check(enemy_guard.ai_state == "Idle" and not enemy_guard.guarding and enemy_guard.recognized_request_id == 0, "Unexecuted request/intention cannot trigger recognition")
	check(demo.request_motion(2), "Real Broad Cut starts auto-defense fixture")
	var ai_broad_request: int = demo.active_request_id
	check(enemy_guard.ai_state == "Reacting" and enemy_guard.recognized_request_id == ai_broad_request and enemy_guard.recognized_motion_name() == "Broad Cut" and not enemy_guard.guarding, "Actual motion start is recognized before any valid hit, without immediate defense")
	check(not demo.request_motion(0) and enemy_guard.last_seen_request_id == ai_broad_request, "Rejected buffered input is not a recognized new threat")
	await ticks(8)
	check(not enemy_guard.guarding and enemy_guard.ai_state == "Reacting" and enemy_guard.reaction_elapsed > 0 and enemy_guard.reaction_elapsed < 0.20, "0.20 s reaction delay actually gates guard")
	await ticks(4)
	check(enemy_guard.guarding and enemy_guard.ai_state == "Guarding" and enemy_guard.auto_guard_count == 1 and not enemy_guard.manual_guard_override, "Reaction expiry enters existing guard in Auto mode")
	check(not enemy_attack.start_attack(), "Automatic guard prevents stationary enemy swing")
	await ticks(15)
	check(enemy_guard.guarding and health.hp == 100 and health.last_settlement.get("result") == "Successful Guard", "Automatic guard settles real Broad Cut through unchanged body-contact ledger")
	check(clash.player_latest.get("request_id") == ai_broad_request and enemy_guard.matching_request_id == ai_broad_request, "Default Auto guard feeds actual Broad Cut request to independent matching/clash diagnostics")
	print("AUTO_DEFENSE_DEFAULT_BROAD ", JSON.stringify({"matching": enemy_guard.matching_result, "reason": enemy_guard.matching_reason, "clash": clash.player_latest["blade_contact"], "hp": health.hp}))
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Enemy Defense: Auto / Guarding") and trajectory.legend.text.contains("Broad Cut") and trajectory.legend.text.contains("reaction 0.20/0.20"), "F4 reports defense mode/state/type/reaction progress")
	trajectory.debug_display_enabled = false
	await ticks(6)
	check(enemy_guard.ai_state == "Recovering" and not enemy_guard.guarding and enemy_guard.owns_hand, "0.35 s auto hold ends judgment and starts existing exit transition")
	await ticks(20)
	check(enemy_guard.ai_state == "Idle" and not enemy_guard.owns_hand and enemy_guard.auto_guard_count == 1, "Auto guard returns hand ownership and never retriggers same request")
	# Fast strike may hit before recognition delay; no retroactive healing/block.
	health._unhandled_key_input(reset_key)
	demo.request_motion(1)
	await ticks(11)
	check(health.hp == 90 and not enemy_guard.guarding, "Early Short Cut can damage before delayed guard")
	await ticks(40)
	check(health.hp == 90, "Late guard cannot retroactively change settled damage")
	# Faster Inspector reaction fixture proves Auto and the existing real matching cooperate.
	health._unhandled_key_input(reset_key)
	enemy_guard.reaction_delay = 0.05
	demo.request_motion(2)
	var ai_fast_request: int = demo.active_request_id
	await ticks(22)
	check(enemy_guard.auto_guard_count == 1 and enemy_guard.matching_request_id == ai_fast_request, "Adjustable shorter reaction enters same automatic matching path")
	check(clash.player_latest["request_id"] == ai_fast_request and clash.player_latest["blade_contact"], "Feasible Auto-defense timing produces real Broad Cut clash without radius/speed changes")
	check(health.hp == 100, "Feasible automatic guard uses original zero-damage settlement")
	enemy_guard.reaction_delay = 0.20
	# A canceled/ended threat is not queued into a belated guard.
	health._unhandled_key_input(reset_key)
	enemy_guard.reaction_delay = 0.50
	demo.request_motion(0)
	await ticks(20)
	check(not enemy_guard.guarding and enemy_guard.auto_guard_count == 0 and enemy_guard.ai_reason == "Attack Ended", "Reaction longer than actual strike cancels during return rather than guarding stale motion")
	health._unhandled_key_input(reset_key)
	enemy_guard.reaction_delay = 0.20
	demo.request_motion(2)
	await ticks(3)
	demo.cancel_debug_motion("ai_test_cancel")
	await ticks(20)
	check(enemy_guard.ai_state == "Idle" and enemy_guard.ai_reason == "Attack Ended" and enemy_guard.auto_guard_count == 0, "Interrupted player attack cancels pending reaction")
	health._unhandled_key_input(reset_key)
	var ai_reference_position: Vector3 = enemy.position
	enemy.position = player.position + Vector3(0.38, 0, -5)
	demo.request_motion(2)
	check(enemy_guard.ai_state == "Idle" and enemy_guard.ai_reason == "Out of Range", "Distant real whiff is rejected at recognition")
	await ticks(35)
	check(enemy_guard.auto_guard_count == 0 and not enemy_guard.guarding, "Far attack never queues a delayed guard")
	health._unhandled_key_input(reset_key)
	enemy.position = ai_reference_position
	enemy.rotation.y = 0
	demo.request_motion(2)
	check(enemy_guard.ai_reason == "Outside Guard Arc" and enemy_guard.ai_state == "Idle", "Back attack is not recognized from Soft Lock or player intent")
	await ticks(20)
	check(not enemy_guard.guarding and health.hp == 90, "Real rear attack remains damaging with auto-defense enabled")
	health._unhandled_key_input(reset_key)
	enemy.rotation.y = PI
	demo.request_motion(2)
	await ticks(3)
	enemy.rotation.y = 0
	await ticks(15)
	check(enemy_guard.ai_reason == "Outside Guard Arc" and enemy_guard.auto_guard_count == 0, "Direction must remain valid through reaction, not only at start")
	health._unhandled_key_input(reset_key)
	enemy.rotation.y = PI
	enemy_attack.enabled = true
	enemy_attack.cooldown = 100
	check(enemy_attack.start_attack(), "Enemy active-attack AI fixture starts original thrust")
	var ai_enemy_swing: int = enemy_attack.active_request_id
	demo.request_motion(2)
	check(enemy_guard.ai_reason == "Already Attacking" and not enemy_guard.guarding and enemy_attack.active_request_id == ai_enemy_swing, "Auto defense cannot cancel an existing enemy swing")
	await ticks(55)
	check(enemy_guard.auto_guard_count == 0 and not enemy_guard.guarding, "Rejected attacking-state threat cannot wait in a queue until swing ends")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	demo.request_motion(2)
	await ticks(2)
	enemy_attack.enabled = true
	enemy_attack.cooldown = 100
	enemy_attack.start_attack()
	await ticks(2)
	check(enemy_guard.ai_reason == "Already Attacking" and enemy_guard.ai_state == "Idle" and not enemy_guard.guarding, "Enemy attack started during reaction invalidates pending guard deterministically")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	enemy_guard.set_guard_enabled(false)
	demo.request_motion(2)
	check(enemy_guard.ai_reason == "Recovering" and not enemy_guard.guarding, "Exit pose ownership rejects new threat without overwriting recovery")
	await ticks(30)
	check(enemy_guard.auto_guard_count == 0, "Recovery rejection does not queue guard")
	# Manual takes over pending reaction, then returns to Auto without a new queue.
	health._unhandled_key_input(reset_key)
	demo.request_motion(2)
	await ticks(3)
	enemy_guard._unhandled_key_input(enemy_guard_key)
	check(enemy_guard.manual_guard_override and enemy_guard.defense_mode() == "Manual Override" and enemy_guard.recognized_request_id == 0 and enemy_guard.guarding, "KP 0 overrides reacting AI via same guard, clearing reaction")
	await ticks(35)
	check(enemy_guard.guarding and enemy_guard.auto_guard_count == 0, "Manual override remains held beyond automatic hold duration")
	demo.request_motion(0)
	await ticks(2)
	check(enemy_guard.guarding and enemy_guard.recognized_request_id == 0, "New player attack cannot race manual guard ownership")
	enemy_guard._unhandled_key_input(enemy_guard_key)
	check(not enemy_guard.manual_guard_override and enemy_guard.defense_mode() == "Auto" and enemy_guard.ai_state == "Recovering", "KP 0 off returns to Auto through smooth exit")
	await ticks(30)
	check(enemy_guard.ai_state == "Idle" and enemy_guard.auto_guard_count == 0, "Manual release cannot auto-defend an already observed request")
	demo.request_motion(2)
	check(enemy_guard.ai_state == "Reacting", "Fresh real request is recognized after manual release and recovery")
	health._unhandled_key_input(reset_key)
	check(enemy_guard.ai_state == "Idle" and enemy_guard.recognized_request_id == 0 and enemy_guard.reaction_elapsed == 0 and not enemy_guard.manual_guard_override, "F7 clears pending AI reaction and manual override")
	await ticks(30)
	check(not enemy_guard.guarding and enemy_guard.auto_guard_count == 0, "No old reaction callback survives reset")
	demo.request_motion(2)
	await ticks(13)
	check(enemy_guard.ai_state == "Guarding", "F7 auto-guard fixture has begun guarding")
	health._unhandled_key_input(reset_key)
	check(enemy_guard.guard_hold_remaining == 0 and not enemy_guard.owns_hand and not enemy_guard.matching_active and enemy_guard.matching_request_id == 0, "F7 clears auto guard hold, hand transition and Contact Matching")
	await ticks(20)
	check(enemy_guard.ai_state == "Idle" and enemy_hand.transform.is_equal_approx(enemy_attack.idle), "Reset pose cannot be overwritten by old AI or matching")
	# Death during reaction cancels it; alive reset restores the current Auto mode.
	demo.request_motion(2)
	await ticks(2)
	check(enemy_guard.ai_state == "Reacting", "Death fixture has a pending real attack reaction")
	for id in range(3100000, 3100010):
		health._on_valid_contact({"request_id": id, "contact_kind": "valid_attack", "target": enemy})
	check(health.dead and enemy_guard.ai_state == "Idle" and enemy_guard.recognized_request_id == 0 and not enemy_guard.guarding, "Enemy death synchronously clears reaction and guard")
	await ticks(30)
	check(enemy_guard.auto_guard_count == 0 and not enemy_guard.owns_hand, "Dead enemy never executes waiting defense")
	health._unhandled_key_input(reset_key)
	check(enemy_guard.auto_defense_enabled and enemy_guard.defense_mode() == "Auto" and not enemy_guard.manual_guard_override, "F7 restores Auto configuration and clears manual toggle")
	check(health.test_damage == 10 and player_health.incoming_test_damage == 5 and defense.held_guard_cost == 10 and defense.instinctive_cost == 50 and rig.lock_overrun_seconds == 0.5 and player.walk_speed == 2 and player.run_speed == 3.5, "Enemy defensive AI leaves every accepted combat/control tuning unchanged")
	rig.initial_auto_acquisition_enabled = true
	check(rig.toggle_soft_lock() and demo.request_ordinary_motion(), "Existing Soft Lock and ordinary automatic selection work with Auto defense")
	health._unhandled_key_input(reset_key)
	rig.toggle_soft_lock()
	# Step 18 uses actual executed motions and native contact events, never fake hits.
	health._unhandled_key_input(reset_key)
	rig.initial_auto_acquisition_enabled = false
	reset_player()
	await ticks(30)
	enemy_attack.enabled = false
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	enemy.rotation.y = PI
	enemy_guard.base_mistake_chance = 0.10
	enemy_guard.mistake_increase_per_pressure = 0.05
	enemy_guard.max_mistake_chance = 0.60
	enemy_guard.breathing_duration = 1.0
	enemy_guard.use_test_seed = true
	enemy_guard.test_seed = 91234
	enemy_guard.reaction_delay = 0.50 # Isolate pressure from delayed guarding, without fake contacts.
	health._unhandled_key_input(reset_key)
	check(enemy_guard.pressure_stacks == 0 and is_equal_approx(enemy_guard.current_mistake_chance(), 0.10), "Initial live enemy mistake chance is 10%")
	var pressure_reference_rng := RandomNumberGenerator.new()
	pressure_reference_rng.seed = 91234
	var pressure_expected_roll := pressure_reference_rng.randf()
	check(demo.request_motion(0), "Real thrust begins first pressure/decision fixture")
	var pressure_first_id: int = demo.active_request_id
	check(enemy_guard.last_mistake_request_id == pressure_first_id and enemy_guard.last_mistake_pressure == 0 and is_equal_approx(enemy_guard.last_mistake_chance, 0.10) and enemy_guard.last_mistake_roll == pressure_expected_roll, "Recognition snapshots pre-contact zero stacks and seeded 10% roll")
	await ticks(18)
	check(enemy_guard.pressure_stacks == 1 and health.hp == 90 and is_equal_approx(enemy_guard.current_mistake_chance(), 0.15), "Actual damaging valid thrust adds one pressure and five percentage points")
	var captured_pressure_event: Dictionary = detector.valid_events.back().duplicate()
	var pressure_first_roll: float = enemy_guard.last_mistake_roll
	var pressure_first_decisions: int = enemy_guard.mistake_decision_count
	health._on_valid_contact(captured_pressure_event)
	enemy_guard.record_valid_pressure(captured_pressure_event, false)
	enemy_guard._on_player_attack_started(pressure_first_id, 0)
	check(enemy_guard.pressure_stacks == 1 and health.hp == 90 and enemy_guard.mistake_decision_count == pressure_first_decisions and enemy_guard.last_mistake_roll == pressure_first_roll, "Captured real signal duplicates cannot repeat pressure, damage or RNG decision")
	check(enemy_guard.last_mistake_pressure == 0 and is_equal_approx(enemy_guard.last_mistake_chance, 0.10), "Current contact never changes its own stored mistake chance")
	await ticks(18)
	for expected_stack in range(2, 6):
		check(demo.request_motion(0), "Real pressure chain accepts request " + str(expected_stack))
		check(enemy_guard.last_mistake_pressure == expected_stack - 1 and is_equal_approx(enemy_guard.last_mistake_chance, 0.10 + (expected_stack - 1) * 0.05), "Next request uses only previous pressure stacks")
		await ticks(36)
		check(enemy_guard.pressure_stacks == expected_stack and is_equal_approx(enemy_guard.current_mistake_chance(), 0.10 + expected_stack * 0.05), "Native valid pressure follows +5pp curve")
	check(health.hp == 50 and not enemy_guard.breathing_eligible, "Unblocked damage pressure grants no breathing qualification")
	await ticks(70)
	check(enemy_guard.pressure_stacks == 5, "Long inactivity without prior successful guard cannot clear pressure")
	check(enemy_guard.set_guard_enabled(true), "Manual guard protects HP while testing high pressure stacks")
	await ticks(15)
	var manual_pressure_decisions: int = enemy_guard.mistake_decision_count
	for expected_stack in range(6, 12):
		demo.request_motion(0)
		await ticks(36)
		check(enemy_guard.pressure_stacks == expected_stack and health.hp == 50 and enemy_guard.last_result == "Successful Guard", "Successive genuine guarded hits add pressure without HP loss")
		check(is_equal_approx(enemy_guard.current_mistake_chance(), minf(0.10 + expected_stack * 0.05, 0.60)), "Pressure probability respects temporary 60% cap")
	check(enemy_guard.mistake_decision_count == manual_pressure_decisions, "Manual override consumes no random decisions while pressure increases")
	check(enemy_guard.breathing_eligible and enemy_guard.breathing_elapsed < 1.0 and enemy_guard.pressure_stacks == 11, "Continuous successful pressure restarts breathing instead of clearing stacks")
	enemy_guard.set_guard_enabled(false)
	await ticks(13)
	demo.request_motion(0)
	check(enemy_guard.last_mistake_pressure == 11 and is_equal_approx(enemy_guard.last_mistake_chance, 0.60), "Fresh automatic request snapshots capped existing pressure")
	await ticks(36)
	check(enemy_guard.pressure_stacks == 12 and not enemy_guard.breathing_eligible and enemy_guard.breathing_elapsed == 0, "New unblocked pressure cancels an older guard's recovery qualification")
	# Force outcomes through Inspector probabilities; contact itself is always real.
	health._unhandled_key_input(reset_key)
	enemy_guard.reaction_delay = 0.20
	enemy_guard.base_mistake_chance = 1
	enemy_guard.mistake_increase_per_pressure = 0
	enemy_guard.max_mistake_chance = 1
	enemy_guard.threat_distance = 3.0
	enemy.position = player.position + Vector3(0.38, 0, -2.8)
	demo.request_motion(0)
	check(enemy_guard.last_mistake and enemy_guard.ai_state == "Idle" and not enemy_guard.guarding, "Certain mistake skips automatic reaction without touching enemy attack")
	await ticks(40)
	check(health.hp == 100 and enemy_guard.pressure_stacks == 0 and enemy_guard.auto_guard_count == 0, "Mistake during in-range but spatially missing thrust cannot manufacture damage or pressure")
	health._unhandled_key_input(reset_key)
	enemy_guard.threat_distance = 2.0
	enemy.position = player.position + Vector3(0.38, 0, -5)
	demo.request_motion(2)
	await ticks(40)
	check(enemy_guard.pressure_stacks == 0 and enemy_guard.mistake_decision_count == 0 and health.hp == 100, "Far whiff has neither pressure nor eligible RNG decision")
	health._unhandled_key_input(reset_key)
	enemy.position = player.position + Vector3(0.38, 0, -0.9)
	demo.request_motion(0)
	var repeatable_pressure_roll: float = enemy_guard.last_mistake_roll
	await ticks(36)
	check(enemy_guard.last_mistake and enemy_guard.mistake_decision_count == 1 and health.hp == 90 and enemy_guard.pressure_stacks == 1, "Mistake exposes only the real native hit, exactly once")
	await ticks(70)
	check(enemy_guard.pressure_stacks == 1 and not enemy_guard.breathing_eligible, "Mistake/damage plus time alone cannot reset pressure")
	health._unhandled_key_input(reset_key)
	demo.request_motion(0)
	check(enemy_guard.last_mistake_roll == repeatable_pressure_roll, "F7 with explicit seed reproduces RNG for a new real executed attack")
	health._unhandled_key_input(reset_key)
	enemy_guard.base_mistake_chance = 0
	enemy_guard.max_mistake_chance = 0.60
	demo.request_motion(2)
	check(not enemy_guard.last_mistake and enemy_guard.ai_state == "Reacting", "No-mistake decision retains original delayed reaction")
	await ticks(8)
	check(not enemy_guard.guarding and enemy_guard.reaction_elapsed < 0.20, "No mistake does not bypass 0.20 s reaction delay")
	await ticks(19)
	check(enemy_guard.auto_guard_count == 1 and enemy_guard.pressure_stacks == 1 and enemy_guard.breathing_eligible and health.hp == 100, "Genuine automatic block adds pressure and starts breathing qualification")
	check(not clash.player_latest["blade_contact"], "Default delayed guard adds pressure independently of missing actual clash")
	# Manual fixed pose isolates the same guard/clash distinction without RNG.
	health._unhandled_key_input(reset_key)
	enemy_guard.base_mistake_chance = 1
	enemy_guard.max_mistake_chance = 1
	enemy_guard.contact_matching_enabled = false
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	demo.request_motion(2)
	await ticks(20)
	check(enemy_guard.mistake_decision_count == 0 and health.hp == 100 and enemy_guard.pressure_stacks == 1 and enemy_guard.breathing_eligible, "Manual override ignores even certain mistakes but records guarded pressure")
	check(not clash.player_latest["blade_contact"] and health.last_settlement["result"] == "Successful Guard", "Pressure requires valid body settlement, not actual blade clash")
	check(enemy_guard.breathing_elapsed < 1.0, "Successful Guard itself does not immediately clear pressure")
	await ticks(30)
	check(enemy_guard.pressure_stacks == 1 and enemy_guard.breathing_eligible, "Partial breathing interval preserves pressure")
	await ticks(35)
	check(enemy_guard.pressure_stacks == 0 and not enemy_guard.breathing_eligible and enemy_guard.last_pressure_reason.contains("complete breathing"), "Successful Guard plus complete 1s quiet interval clears pressure and consumes qualification")
	# Real physical-only animation and cancellation cannot create pressure.
	health._unhandled_key_input(reset_key)
	enemy_guard.contact_matching_enabled = true
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	demo.thrust_active_window = Vector2(0.26, 0.26)
	demo.request_motion(0)
	await ticks(36)
	check(not detector.events.is_empty() and detector.valid_events.is_empty() and enemy_guard.pressure_stacks == 0 and health.hp == 100, "Actual windup/return physical contacts with disabled valid window produce no pressure")
	demo.thrust_active_window = Vector2(0.12, 0.26)
	demo.request_motion(2)
	await ticks(3)
	demo.cancel_debug_motion("pressure_cancel_test")
	await ticks(40)
	check(enemy_guard.pressure_stacks == 0 and health.hp == 100, "Canceled pre-strike real motion cannot add pressure")
	# A fresh guarded contact restarts the interval before the old one finishes.
	health._unhandled_key_input(reset_key)
	enemy_guard.set_guard_enabled(true)
	await ticks(15)
	demo.request_motion(0)
	await ticks(36)
	var first_breathing_elapsed: float = enemy_guard.breathing_elapsed
	demo.request_motion(0)
	await ticks(12)
	check(enemy_guard.pressure_stacks == 2 and enemy_guard.breathing_eligible and enemy_guard.breathing_elapsed < first_breathing_elapsed, "New valid guarded pressure cancels old breathing attempt and requalifies from zero")
	trajectory.debug_display_enabled = true
	await ticks(1)
	check(trajectory.legend.text.contains("Pressure: 2") and trajectory.legend.text.contains("Breathing eligible: true") and trajectory.legend.text.contains("roll"), "F4 shows pressure, probability/roll snapshot and recovery qualification")
	trajectory.debug_display_enabled = false
	# During an enemy swing no eligible roll, cancellation or queued defense occurs.
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = true
	enemy_attack.cooldown = 100
	enemy_attack.start_attack()
	var pressure_enemy_attack_id: int = enemy_attack.active_request_id
	demo.request_motion(2)
	check(enemy_guard.mistake_decision_count == 0 and enemy_attack.active_request_id == pressure_enemy_attack_id and enemy_guard.ai_reason == "Already Attacking", "Mistake eligibility cannot interrupt enemy attack or roll while already attacking")
	health._unhandled_key_input(reset_key)
	enemy_attack.enabled = false
	check(enemy_guard.pressure_stacks == 0 and enemy_guard.pressure_requests.is_empty() and not enemy_guard.breathing_eligible and enemy_guard.breathing_elapsed == 0 and enemy_guard.last_mistake_roll == -1 and enemy_guard.last_mistake_request_id == 0 and enemy_guard.mistake_decision_count == 0, "F7 clears all pressure, breathing and RNG result records")
	# Native lethal hits verify death cleanup, without fabricated valid contacts/HP.
	for lethal_hit in 10:
		demo.request_motion(0)
		await ticks(36)
		if lethal_hit < 9: check(enemy_guard.pressure_stacks == lethal_hit + 1 and health.hp == 100 - 10 * (lethal_hit + 1), "Native damage pressure remains until death")
	check(health.dead and enemy_guard.pressure_stacks == 0 and not enemy_guard.breathing_eligible and enemy_guard.last_mistake_roll == -1 and enemy_guard.mistake_decision_count == 0 and enemy_guard.last_pressure_reason == "Enemy Dead", "Native lethal hit clears pressure, breathing and random-decision state")
	demo.request_motion(0)
	await ticks(36)
	check(enemy_guard.pressure_stacks == 0 and health.hp == 0 and enemy_guard.mistake_decision_count == 0, "Dead target cannot gain pressure or roll new defense")
	health._unhandled_key_input(reset_key)
	enemy_guard.base_mistake_chance = 0.10
	enemy_guard.mistake_increase_per_pressure = 0.05
	enemy_guard.max_mistake_chance = 0.60
	enemy_guard.reaction_delay = 0.20
	check(enemy_guard.current_mistake_chance() == 0.10 and enemy_guard.guard_hold_duration == 0.35 and enemy_guard.threat_distance == 2.0 and enemy_guard.enemy_guard_arc == 60 and demo.thrust_active_window == Vector2(0.12, 0.26), "Pressure fixtures restore all default AI and attack parameters")
	rig.initial_auto_acquisition_enabled = true
	rig.toggle_soft_lock()
	enemy.queue_free()
	await ticks(3)
	check(not rig.is_locked() and rig.locked_target == null, "Freed target is safely cleared without dangling-reference errors")
	print("STAGE1_CONTROL_CHECK ", JSON.stringify({"checks": checks, "failures": failures}))
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
