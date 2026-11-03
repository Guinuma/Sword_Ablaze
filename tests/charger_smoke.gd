extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var system = load("res://scripts/enemies/enemy_system.gd").new()
	var bounds := Rect2(0, 0, 600, 360)
	var random := RandomNumberGenerator.new()
	random.seed = 42
	for rate in [30, 60, 120, 144, 240]:
		system.clear()
		system.spawn(Vector2(300, 180), bounds, random, &"charger")
		var enemy: Dictionary = system.items[0]
		enemy.position = Vector2(100, 180)
		enemy.spawn_time = 0.0
		enemy.attack_cooldown = 0.0
		system.advance(0.01, Vector2(220, 180), 5, bounds)
		check(enemy.charge_phase == "warning", "Charger must warn first")
		var direction: Vector2 = enemy.charge_direction
		var start: Vector2 = enemy.position
		var delta: float = 1.0 / rate
		var crossed := false
		for index in range(rate * 2):
			system.advance(delta, Vector2(220, 250), 5, bounds)
			check(enemy.charge_direction == direction, "Warning/charge must not track the player")
			if enemy.charge_phase == "warning":
				check(enemy.position == start, "Warning must hold position")
			if system.touches(Vector2(180, 180)):
				crossed = true
			if enemy.charge_phase == "recovery":
				break
		check(crossed, "Charge path must register contact at every tested rate")
		check(enemy.charge_phase == "recovery", "Charge must enter recovery")
		var rest: Vector2 = enemy.position
		system.advance(0.2, Vector2(220, 250), 5, bounds)
		check(enemy.position == rest, "Recovery must hold position")
	# One long step crosses the player and finishes beyond the contact radius.
	var enemy: Dictionary = system.items[0]
	enemy.position = Vector2(100, 180)
	enemy.charge_phase = "charge"
	enemy.charge_timer = 0.45
	enemy.charge_direction = Vector2.RIGHT
	system.advance(0.45, Vector2(180, 180), 5, bounds)
	check(system.touches(Vector2(180, 180)), "Swept charge contact must prevent tunneling")
	system.advance(0.01, Vector2(180, 180), 5, bounds)
	check(not system.touches(Vector2(180, 180)), "Old charge path must expire next step")
	enemy.position = Vector2(580, 180)
	enemy.charge_phase = "charge"
	enemy.charge_timer = 0.45
	system.advance(0.2, Vector2(590, 180), 5, bounds)
	check(enemy.position.x <= 592 and enemy.charge_phase == "recovery", "Wall must clamp charge and trigger recovery")
	var waves = load("res://scripts/run/wave_director.gd").new()
	var kinds: Array[StringName] = []
	waves.spawn_requested.connect(func(kind): kinds.append(kind))
	waves.number = 5
	waves.remaining = 10
	for index in range(10):
		waves.spawn_cooldown = 0.0
		waves.advance(0.01, 0)
	check(kinds.count(&"charger") == 2, "Wave five must include one charger per five spawns")
	system.clear()
	check(system.items.is_empty(), "Reset must remove chargers")
	print("Charger checks complete: %d failures" % failures)
	quit(1 if failures else 0)
