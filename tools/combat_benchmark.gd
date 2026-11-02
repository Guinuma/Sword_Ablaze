extends SceneTree
## Measures simulation cost with configured entity limits, without rendering.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.waves.number = 30
	arena.waves.remaining = 40
	for index in range(arena.waves.settings.max_enemies):
		arena._spawn_enemy(&"ranged" if index % 3 == 0 else &"chaser")
		var enemy: Dictionary = arena.enemies.items.back()
		enemy["spawn_time"] = 0.0
		enemy["health"] = 100000
	var samples: Array[float] = []
	var peak_memory: int = 0
	for frame in range(4200):
		# Refill caps outside timed section to measure a consistently crowded frame.
		while arena.projectiles.items.size() < arena.projectiles.MAX_PROJECTILES:
			arena.projectiles.fire(Vector2(40, 100), Vector2.RIGHT)
		while arena.hostile_projectiles.items.size() < arena.hostile_projectiles.MAX_PROJECTILES:
			arena.hostile_projectiles.fire(Vector2(600, 300), Vector2.LEFT, 130.0)
		arena._burst(Vector2(320, 200), Color.WHITE, 160)
		arena.player.hurt_cooldown = 1.0
		var started := Time.get_ticks_usec()
		arena._physics_process(1.0 / 60.0)
		var duration := float(Time.get_ticks_usec() - started) / 1000.0
		if frame >= 600:
			samples.append(duration)
		peak_memory = maxi(peak_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	samples.sort()
	var total: float = 0.0
	for value in samples:
		total += value
	var report := {
		"engine": Engine.get_version_info()["string"],
		"processor": OS.get_processor_name(),
		"platform": OS.get_name(),
		"scenario": "Headless simulation, 18 enemies (6 ranged), 128 player shots, 64 hostile shots, 160 particles; caps refilled before each measured frame",
		"measured_frames": samples.size(),
		"warmup_frames": 600,
		"mean_ms": total / samples.size(),
		"p95_ms": samples[int(samples.size() * 0.95)],
		"max_ms": samples.back(),
		"peak_static_memory_bytes": peak_memory,
		"note": "Simulation only; excludes rendering, refill setup and real input. Not a hardware requirement or FPS claim."
	}
	print(JSON.stringify(report, "  "))
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty():
		var output := FileAccess.open(arguments[0], FileAccess.WRITE)
		if output:
			output.store_string(JSON.stringify(report, "  ") + "\n")
		else:
			push_error("Cannot write benchmark report")
			arena.free()
			quit(1)
			return
	arena.free()
	quit()
