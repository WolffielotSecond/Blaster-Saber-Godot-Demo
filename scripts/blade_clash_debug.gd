extends Node
## Independent two-moving-blade diagnostic. Never changes damage or defense outcome.
signal clash_detected(event: Dictionary)
signal body_contact_detected(event: Dictionary)
@export_range(0.002, 0.05, 0.001) var blade_radius: float = 0.012
@export_range(0.001, 0.02, 0.001) var sweep_step: float = 0.005
@export_range(32, 2048, 1) var max_substeps: int = 1024
var latest: Dictionary = {}
var events: Array[Dictionary] = []
var records: Array[Dictionary] = []
var previous: Dictionary = {}
var capped_segments: int = 0
var generation: int = 0
var player_latest: Dictionary = {}
var player_previous: Dictionary = {}
var player_records: Array[Dictionary] = []
@onready var attack: Node3D = get_node("../Enemy/DebugAttack")
@onready var player_weapon: Node3D = get_node("../Player/VisualRoot/RightHand/Gunblade")
@onready var enemy_weapon: Node3D = get_node("../Enemy/VisualRoot/RightHand/Gunblade")
@onready var defense: Node = get_node("../Player/DebugDefense")

func _ready() -> void:
	attack.attack_started.connect(_start)
	attack.detector.contact_detected.connect(_on_body)
	attack.detector.valid_attack_contact_detected.connect(_on_valid_body)
	get_node("../Player/WeaponMotionDemo").motion_started.connect(_start_player)
	get_node("../Player/WeaponMotionDemo").motion_ended.connect(_end_player)
	get_node("../WeaponTrajectoryDebug").sample_recorded.connect(_sample_player)
	clash_detected.connect(get_node("../Enemy/DebugDefense")._on_clash)

func _start_player(id: int, motion: int) -> void:
	player_latest = {"request_id": id, "motion": motion, "blade_contact": false, "end_frame": 0}
	player_records.append(player_latest)
	if player_records.size() > 32: player_records.pop_front()
	player_previous = pair_pose()

func _end_player(id: int, _reason: String) -> void:
	if player_latest.get("request_id", 0) == id:
		player_latest["end_frame"] = Engine.get_physics_frames()

func _sample_player(id: int, _motion: int, _sample: Dictionary) -> void:
	if player_latest.get("request_id", 0) != id or player_previous.is_empty(): return
	var epoch := generation
	get_node("../Enemy/DebugDefense").update_matching()
	var current := pair_pose()
	if get_node("../Enemy/DebugDefense").guarding and not player_latest["blade_contact"]:
		var hit := sweep_pair(player_previous, current)
		if not hit.is_empty():
			player_latest["blade_contact"] = true
			var event := {"request_id": id, "generation": generation, "detector": self,
				"kind": "blade_clash", "attack_side": "Player", "position": hit["position"],
				"physics_frame": Engine.get_physics_frames(), "fraction": hit["fraction"], "motion": _motion}
			events.append(event)
			if events.size() > 32: events.pop_front()
			clash_detected.emit(event)
			if epoch != generation: return
	player_previous = current

func pose(weapon: Node3D) -> Dictionary:
	return {"base": weapon.get_node("BladeBase").global_position,
		"tip": weapon.get_node("BladeTip").global_position,
		"rotation": weapon.global_basis.get_rotation_quaternion()}

func pair_pose() -> Dictionary:
	return {"player": pose(player_weapon), "enemy": pose(enemy_weapon)}

func _start(id: int) -> void:
	latest = {"request_id": id, "blade_contact": false, "body_contact": false,
		"valid_body_contact": false, "damage_prevented": "pending", "defense_on_body_contact": "None",
		"motion": attack.motion, "motion_name": ["Thrust", "Left Cut", "Right Cut"][attack.motion], "start_frame": Engine.get_physics_frames()}
	records.append(latest)
	if records.size() > 32: records.pop_front()
	previous = pair_pose()
	sample_attack(id)

func sample_attack(id: int) -> void:
	var epoch := generation
	if latest.is_empty() or latest["request_id"] != id:
		return
	var current := pair_pose()
	if not latest["blade_contact"]:
		var hit := sweep_pair(previous, current)
		if not hit.is_empty():
			latest["blade_contact"] = true
			var event := {"request_id": id, "generation": generation, "detector": self, "kind": "blade_clash", "position": hit["position"],
				"physics_frame": Engine.get_physics_frames(), "fraction": hit["fraction"], "defense": defense.state_name()}
			events.append(event)
			if events.size() > 32:
				events.pop_front()
			clash_detected.emit(event)
			if epoch != generation: return
	previous = current

func _on_body(event: Dictionary) -> void:
	if not latest.is_empty() and latest["request_id"] == event["request_id"]:
		latest["body_contact"] = true
		body_contact_detected.emit(event)

func _on_valid_body(event: Dictionary) -> void:
	if not latest.is_empty() and latest["request_id"] == event["request_id"]:
		var health: Node = get_node("../Player/DebugPlayerHealth")
		var settlement = health.damaged_requests.get(event["request_id"], {})
		if not settlement is Dictionary or settlement.is_empty(): return
		latest["valid_body_contact"] = true
		var result: String = settlement["result"]
		latest["defense_on_body_contact"] = "Held Guard" if result == "Block" else (result if result in ["Perfect Parry", "Instinctive Defense"] else "None")
		latest["damage_prevented"] = "NO" if result == "Damage" else "YES"

func sweep_pair(from: Dictionary, to: Dictionary) -> Dictionary:
	var travel := _travel(from["player"], to["player"]) + _travel(from["enemy"], to["enemy"])
	var needed := maxi(1, ceili(travel / sweep_step))
	if needed > max_substeps:
		capped_segments += 1
		push_warning("Blade clash diagnostic subdivision cap reached")
	var steps := mini(needed, max_substeps)
	for i in range(steps + 1):
		var fraction := float(i) / steps
		var p := _interpolate(from["player"], to["player"], fraction)
		var e := _interpolate(from["enemy"], to["enemy"], fraction)
		var closest := Geometry3D.get_closest_points_between_segments(p["base"], p["tip"], e["base"], e["tip"])
		if closest[0].distance_to(closest[1]) <= blade_radius * 2.0:
			return {"position": (closest[0] + closest[1]) * 0.5, "fraction": fraction}
	return {}

func _travel(a: Dictionary, b: Dictionary) -> float:
	var base_a: Vector3 = a["base"]
	var base_b: Vector3 = b["base"]
	var tip_a: Vector3 = a["tip"]
	var tip_b: Vector3 = b["tip"]
	var rotation_a: Quaternion = a["rotation"]
	return base_a.distance_to(base_b) + rotation_a.angle_to(b["rotation"]) * maxf(base_a.distance_to(tip_a), base_b.distance_to(tip_b))

func _interpolate(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var base_a: Vector3 = a["base"]
	var base_b: Vector3 = b["base"]
	var tip_a: Vector3 = a["tip"]
	var tip_b: Vector3 = b["tip"]
	var rotation: Quaternion = a["rotation"]
	rotation = rotation.slerp(b["rotation"], t)
	var base := base_a.lerp(base_b, t)
	return {"base": base, "tip": base + Basis(rotation).y * lerpf(base_a.distance_to(tip_a), base_b.distance_to(tip_b), t)}

func debug_reset() -> void:
	generation += 1
	latest = {}
	previous = {}
	events.clear()
	records.clear()
	player_latest.clear()
	player_previous.clear()
	player_records.clear()
