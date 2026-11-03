extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var enemies = load("res://scripts/enemies/enemy_system.gd").new()
	var shots = load("res://scripts/combat/projectile_system.gd").new()
	shots.weapon = shots.weapon.duplicate()
	var bounds := Rect2(0, 0, 640, 360)
	var random := RandomNumberGenerator.new()
	enemies.spawn(Vector2(300, 180), bounds, random, &"guardian")
	var enemy: Dictionary = enemies.items[0]
	enemy.position = Vector2(200, 180)
	enemy.spawn_time = 0.0
	enemy.facing = Vector2.RIGHT
	shots.fire(Vector2(220, 180), Vector2.LEFT)
	shots.advance(0.1, enemies.items, bounds)
	check(enemy.health == 7, "Basic frontal shot must deal one damage")
	check(absf(enemy.knockback.length() - shots.weapon.knockback * 0.2) < 0.01, "Guardian must resist knockback")
	shots.fire(Vector2(180, 180), Vector2.RIGHT)
	shots.advance(0.1, enemies.items, bounds)
	check(enemy.health == 5, "Flanking shot must deal double damage")
	shots.weapon.damage = 3
	shots.fire(Vector2(220, 180), Vector2.LEFT)
	shots.advance(0.1, enemies.items, bounds)
	check(enemy.health == 3, "Armor must halve upgraded damage, rounding up")
	enemy.knockback = Vector2.ZERO
	for rate in [30, 60, 120, 144, 240]:
		enemy.facing = Vector2.RIGHT
		enemy.position = Vector2(200, 180)
		var delta: float = 1.0 / rate
		enemies.advance(delta, Vector2(100, 180), 7, bounds)
		check(absf(Vector2.RIGHT.angle_to(enemy.facing)) <= enemies.guardian_settings.turn_speed * delta + 0.001, "Turning must be capped at every tested rate")
	check(enemies.guardian_settings.health > enemies.settings.health, "Guardian must be tougher than chaser")
	var waves = load("res://scripts/run/wave_director.gd").new()
	waves.number = 7
	waves.remaining = 14
	var kinds: Array[StringName] = []
	waves.spawn_requested.connect(func(kind): kinds.append(kind))
	for index in range(14):
		waves.spawn_cooldown = 0.0
		waves.advance(0.01, 0)
	check(kinds.count(&"guardian") == 2, "Wave seven must introduce guardians at the configured cadence")
	enemies.clear()
	check(enemies.items.is_empty(), "Reset must clear guardians")
	print("Guardian checks complete: %d failures" % failures)
	quit(1 if failures else 0)
