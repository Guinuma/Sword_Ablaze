extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://obstacle_smoke_profile.json")
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var geometry = load("res://scripts/combat/arena_geometry.gd").new()
	geometry.obstacles = [Rect2(260, 150, 40, 60)] as Array[Rect2]
	var bounds := Rect2(0, 0, 640, 360)
	for rate in [30, 60, 120, 144, 240]:
		var player = load("res://scripts/player/player_state.gd").new()
		player.geometry = geometry
		player.player_position = Vector2(240, 180)
		player.try_dash(Vector2.RIGHT)
		for step in range(int(ceil(0.2 * rate))):
			player.advance(1.0 / rate, Vector2.RIGHT, Vector2(400, 180), false, false, bounds)
		check(player.player_position.x <= 252.001, "Dash must not tunnel through a ruin at any physics rate")
		var system = load("res://scripts/enemies/enemy_system.gd").new()
		system.geometry = geometry
		var random := RandomNumberGenerator.new()
		system.spawn(Vector2(400, 180), bounds, random)
		var enemy: Dictionary = system.items[0]
		enemy.position = Vector2(220, 180)
		enemy.spawn_time = 0.0
		for step in range(rate * 6):
			system.advance(1.0 / rate, Vector2(360, 180), 1, bounds)
			check(not geometry.obstacles[0].grow(7.9).has_point(enemy.position), "Navigation and separation must keep enemies outside solid geometry")
		check(Vector2(enemy.position).distance_to(Vector2(360, 180)) < 20, "Enemy must route around a ruin instead of getting stuck")
	var projectiles = load("res://scripts/combat/projectile_system.gd").new()
	projectiles.geometry = geometry
	var enemies: Array[Dictionary] = [{"position": Vector2(340, 180), "health": 2, "spawn_time": 0.0}]
	projectiles.fire(Vector2(220, 180), Vector2.RIGHT)
	projectiles.advance(0.5, enemies, bounds)
	check(enemies[0].health == 2 and projectiles.items.is_empty(), "A wall must consume a fast shot before an enemy behind it")
	enemies[0].position = Vector2(240, 180)
	projectiles.fire(Vector2(220, 180), Vector2.RIGHT)
	projectiles.advance(0.5, enemies, bounds)
	check(enemies[0].health == 1, "An enemy before a wall must still receive the nearest hit")
	var hostile = load("res://scripts/combat/hostile_projectiles.gd").new()
	hostile.geometry = geometry
	var hits: Array[int] = []
	hostile.hit_player.connect(func(damage): hits.append(damage))
	hostile.fire(Vector2(220, 180), Vector2.RIGHT, 1000)
	hostile.advance(0.2, Vector2(340, 180), bounds)
	check(hits.is_empty() and hostile.items.is_empty(), "Cover must intercept hostile fire before the player")
	var melee = load("res://scripts/combat/melee_system.gd").new()
	melee.geometry = geometry
	enemies[0].position = Vector2(304, 180)
	melee.swing(Vector2(256, 180), Vector2.RIGHT, enemies)
	check(enemies[0].health == 1, "Melee cannot damage through a wall")
	var system = load("res://scripts/enemies/enemy_system.gd").new()
	system.geometry = geometry
	var random := RandomNumberGenerator.new()
	system.spawn(Vector2(360, 180), bounds, random, &"ranged")
	system.items[0].position = Vector2(220, 180)
	system.items[0].spawn_time = 0.0
	for step in range(600):
		system.advance(0.02, Vector2(360, 180), 1, bounds)
	check(is_inf(geometry.segment_hit(system.items[0].position, Vector2(360, 180))), "Ranged enemy must seek line of sight around cover")
	system.clear()
	system.spawn(Vector2(360, 180), bounds, random, &"charger")
	var charger: Dictionary = system.items[0]
	charger.position = Vector2(220, 180)
	charger.spawn_time = 0.0
	charger.charge_phase = "charge"
	charger.charge_direction = Vector2.RIGHT
	charger.charge_timer = 0.45
	system.advance(0.2, Vector2(360, 180), 1, bounds)
	check(charger.position.x <= 252.001 and charger.charge_phase == "recovery", "A charger hitting cover must stop and enter recovery")
	check(not system.touches(Vector2(340, 180)), "A blocked charge must not damage a player behind the wall")
	var drops = load("res://scripts/run/healing_drops.gd").new()
	var narrow_geometry = load("res://scripts/combat/arena_geometry.gd").new()
	narrow_geometry.obstacles = [Rect2(260, 150, 4, 60)] as Array[Rect2]
	drops.geometry = narrow_geometry
	drops.spawn(Vector2(268, 180), 10)
	var run = load("res://scripts/run/run_state.gd").new()
	run.health = 50
	drops.advance(0.0, Vector2(256, 180), run)
	check(run.health == 50 and drops.items.size() == 1, "Nearby healing cannot be collected through cover")
	drops.advance(0.0, Vector2(268, 180), run)
	check(run.health == 60 and drops.items.is_empty(), "An unobstructed pickup must still heal")
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://obstacle_smoke_preferences.json")
	arena.records = arena.ArenaRecords.new("user://obstacle_smoke_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.geometry.obstacles = geometry.obstacles.duplicate()
	arena.player.player_position = Vector2(240, 180)
	arena._fire_player_projectile(Vector2(310, 180), Vector2.RIGHT)
	check(arena.projectiles.items.is_empty(), "A muzzle beyond cover cannot create a shot on the far side")
	arena._fire_player_projectile(Vector2(250, 180), Vector2.RIGHT)
	check(arena.projectiles.items.size() == 1, "An unobstructed muzzle path must still fire")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://obstacle_smoke_preferences.json", "user://obstacle_smoke_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Obstacle checks complete: %d failures" % failures)
	quit(1 if failures else 0)
