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
	var projectiles = load("res://scripts/combat/hostile_projectiles.gd").new()
	enemies.shot.connect(projectiles.fire)
	var bounds := Rect2(0, 0, 640, 360)
	var random := RandomNumberGenerator.new()
	for rate in [30, 60, 120, 144, 240]:
		enemies.clear()
		projectiles.clear()
		enemies.spawn(Vector2(320, 180), bounds, random, &"elite")
		var enemy: Dictionary = enemies.items[0]
		enemy.position = Vector2(170, 180)
		enemy.spawn_time = 0.0
		enemy.attack_cooldown = 0.0
		enemies.advance(0.01, Vector2(320, 180), 9, bounds)
		check(enemy.windup > 1.0 and projectiles.items.is_empty(), "Elite must announce its volley")
		var locked: Vector2 = enemy.shot_direction
		var delta: float = 1.0 / rate
		for step in range(rate * 2):
			enemies.advance(delta, Vector2(320, 280), 9, bounds)
			check(enemy.shot_direction == locked, "Volley directions must stay fixed during warning")
			if not projectiles.items.is_empty():
				break
		check(projectiles.items.size() == 8, "Elite must emit exactly eight radial shots")
		for index in range(8):
			var bullet: Dictionary = projectiles.items[index]
			check(bullet.direction.distance_to(locked.rotated(index * TAU / 8)) < 0.001, "Shots must match announced spokes")
			check(bullet.damage == 20 and bullet.speed == 110.0, "Elite shots must carry their own damage and speed")
		check(enemy.attack_cooldown == 3.0, "Elite must recover between volleys")
	var waves = load("res://scripts/run/wave_director.gd").new()
	waves.number = 9
	waves.remaining = waves.budget_for_wave(9)
	var kinds: Array[StringName] = []
	waves.spawn_requested.connect(func(kind): kinds.append(kind))
	for index in range(waves.remaining):
		waves.spawn_cooldown = 0.0
		waves.advance(0.01, 0)
	check(kinds[0] == &"elite" and kinds.count(&"elite") == 1, "Siege must have one elite opener inside its existing budget")
	print("Elite checks complete: %d failures" % failures)
	quit(1 if failures else 0)
