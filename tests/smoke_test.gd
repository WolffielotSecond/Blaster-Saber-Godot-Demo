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
	player = arena.get_node("Player")
	enemy = arena.get_node("Enemy")
	rig = arena.get_node("ThirdPersonRig")
	camera = rig.get_node("PitchPivot/SpringArm3D/Camera3D")
	var enemy_start := enemy.global_transform
	await ticks(30)
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
	print("STAGE1_CONTROL_CHECK ", JSON.stringify({"checks": checks, "failures": failures}))
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
