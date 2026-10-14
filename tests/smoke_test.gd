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
	var matching: Node = arena.get_node("Player/ContactMatchingDebug")
	matching.enabled = false # Preserve the previous 345-check baseline; enable below.
	player = arena.get_node("Player")
	check(is_equal_approx(player.get_node("DebugPlayerHealth").incoming_test_damage, 5), "Current enemy damage default is 5 HP")
	player.get_node("DebugPlayerHealth").incoming_test_damage = 25 # Historical damage fixture.
	enemy_attack.sequence_length = 1 # Historical single-attack rhythm fixture.
	enemy = arena.get_node("Enemy")
	rig = arena.get_node("ThirdPersonRig")
	camera = rig.get_node("PitchPivot/SpringArm3D/Camera3D")
	var enemy_start := enemy.global_transform
	await ticks(30)
	var health: Node = enemy.get_node("DebugHealth")
	check(is_equal_approx(health.max_hp, 100.0) and is_equal_approx(health.hp, 100.0) and not health.dead, "Enemy starts alive at temporary 100 HP maximum")
	check(is_equal_approx(health.test_damage, 25.0), "All motions share temporary 25 HP damage")
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
	health._on_valid_contact(detector.valid_events.back())
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
	var lb := InputEventJoypadButton.new()
	lb.device = 0
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	check(InputMap.event_is_action(q, "active_defense") and InputMap.event_is_action(lb, "active_defense"), "Q and L1/LB map to active defense")
	var no_conflict := true
	for action in InputMap.get_actions():
		if action != "active_defense":
			no_conflict = no_conflict and not InputMap.event_is_action(q, action) and not InputMap.event_is_action(lb, action)
	check(no_conflict, "Defense bindings do not overlap prior actions")
	check(is_equal_approx(defense.perfect_window_seconds, 0.15) and is_equal_approx(defense.defense_half_angle_degrees, 60), "Temporary parry/cone Inspector defaults")
	reset_player()
	health._unhandled_key_input(reset_key)
	await ticks(2)
	check(defense.state_name() == "None", "Default/reset defense is None")
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
	print("STAGE1_CONTROL_CHECK ", JSON.stringify({"checks": checks, "failures": failures}))
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
