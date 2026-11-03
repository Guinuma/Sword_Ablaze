extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var melee = load("res://scripts/combat/melee_system.gd").new()
	melee.weapon = melee.weapon.duplicate()
	var targets: Array[Dictionary] = [
		{"position": Vector2(120, 180), "health": 10, "flash": 0.0},
		{"position": Vector2(80, 180), "health": 10, "flash": 0.0},
		{"position": Vector2(170, 180), "health": 10, "flash": 0.0},
		{"position": Vector2(120, 180), "health": 10, "flash": 0.0, "spawn_time": 0.5}]
	melee.swing(Vector2(100, 180), Vector2.RIGHT, targets)
	check(targets[0].health == 8 and targets[1].health == 10 and targets[2].health == 10 and targets[3].health == 10, "Melee must hit only an active enemy inside its forward reach/cone")
	var criticals: Array[Vector2] = []
	melee.critical_hit.connect(func(point): criticals.append(point))
	melee.weapon.critical_chance = 1.0
	melee.swing(Vector2(100, 180), Vector2.RIGHT, targets)
	check(targets[0].health == 4 and criticals.size() == 1, "Guaranteed melee critical must double damage and emit feedback once")
	var guardian = load("res://resources/default_guardian.tres")
	targets = [{"position": Vector2(120, 180), "health": 10, "flash": 0.0, "profile": guardian, "facing": Vector2.LEFT}]
	melee.swing(Vector2(100, 180), Vector2.RIGHT, targets)
	check(targets[0].health == 8, "Guardian front must halve critical melee damage after critical multiplier")
	targets[0].facing = Vector2.RIGHT
	targets[0].health = 10
	melee.swing(Vector2(100, 180), Vector2.RIGHT, targets)
	check(targets[0].health == 2, "Guardian flank must retain its weakness for critical melee")
	var shots = load("res://scripts/combat/projectile_system.gd").new()
	shots.weapon = shots.weapon.duplicate()
	shots.weapon.critical_chance = 1.0
	var ranged_criticals: Array[Vector2] = []
	shots.critical_hit.connect(func(point): ranged_criticals.append(point))
	targets = [{"position": Vector2(130, 180), "health": 10, "flash": 0.0}]
	shots.fire(Vector2(100, 180), Vector2.RIGHT)
	shots.advance(0.2, targets, Rect2(0, 0, 640, 360))
	check(targets[0].health == 8 and ranged_criticals.size() == 1 and shots.items.is_empty(), "Guaranteed projectile critical must double damage once and consume its projectile")
	for rate in [30, 60, 120, 144, 240]:
		var player = load("res://scripts/player/player_state.gd").new()
		var attacks: Array[Vector2] = []
		player.melee.connect(func(point, _direction): attacks.append(point))
		for step in range(rate):
			player.advance(1.0 / rate, Vector2.ZERO, Vector2(600, 200), false, false, Rect2(0, 0, 640, 360), true)
		check(attacks.size() == 3, "Held melee must obey its cooldown at all tested step rates")
		player.reset()
		var before := attacks.size()
		player.advance(0.1, Vector2.ZERO, Vector2(600, 200), false, false, Rect2(0, 0, 640, 360), true)
		check(attacks.size() == before, "Restart must require melee release")
		player.advance(0.01, Vector2.ZERO, Vector2(600, 200), false, false, Rect2(0, 0, 640, 360), false)
		player.advance(0.01, Vector2.ZERO, Vector2(600, 200), false, false, Rect2(0, 0, 640, 360), true)
		check(attacks.size() == before + 1, "Melee must reactivate after release")
	var player_script = load("res://scripts/player/player_state.gd")
	check(player_script.weapon_grip(Vector2.RIGHT) == Vector2(0, -6) and player_script.weapon_grip(Vector2.UP) == Vector2(7, -6), "Shared grip must preserve cardinal attachment points")
	for index in range(360):
		var first: Vector2 = player_script.weapon_grip(Vector2.RIGHT.rotated(deg_to_rad(index)))
		var second: Vector2 = player_script.weapon_grip(Vector2.RIGHT.rotated(deg_to_rad(index + 1)))
		check(first.distance_to(second) < 1.0, "Weapon grip must interpolate continuously through every aiming angle")
	var visual_script = load("res://scripts/player/exile_visual.gd")
	for index in range(360):
		for length in [0.0, 1.0, 3.0, 10.0, 16.0]:
			var neck := Vector2(0, -9)
			var polygon: PackedVector2Array = visual_script.cape_polygon(neck, neck + Vector2.RIGHT.rotated(deg_to_rad(index)) * length)
			check(Geometry2D.triangulate_polygon(polygon).size() == 6, "Cape must retain drawable geometry through every movement direction and collapsed pose")
	var upgrades = load("res://scripts/run/upgrade_system.gd").new()
	upgrades.stacks[&"critical"] = 3
	check(is_equal_approx(upgrades.value("critical_chance", 0), 0.3), "Keen Edge must add ten percentage points per rank")
	upgrades.reset()
	check(upgrades.value("critical_chance", 0) == 0.0, "Critical chance must reset with temporary upgrades")
	print("Melee/critical checks complete: %d failures" % failures)
	quit(1 if failures else 0)
