extends SceneTree
## Real rendered frames, automated dense combat; never writes player preferences.
const WARMUP := 120
const FRAMES := 600
var random := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("_run")

func stats(values: Array[float]) -> Dictionary:
	values.sort()
	var total := 0.0
	for value in values:
		total += value
	return {"mean": total / values.size(), "p95": values[int(values.size() * 0.95)], "max": values.back()}

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render benchmark requires a graphical display; omit --headless")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	random.seed = 4825
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.preferences.reduced_motion = false
	arena.preferences.reduced_flashes = false
	arena.waves.number = 30
	arena.waves.remaining = 40
	for index in range(18):
		arena._spawn_enemy([&"chaser", &"ranged", &"charger"][index % 3])
		var enemy: Dictionary = arena.enemies.items.back()
		enemy.spawn_time = 0.0
		enemy.health = 100000
	var frame_times: Array[float] = []
	var simulation_times: Array[float] = []
	var submission_times: Array[float] = []
	var peak_memory := 0
	var peak_draw_calls := 0
	var previous := Time.get_ticks_usec()
	for frame in range(WARMUP + FRAMES):
		await process_frame
		var started := Time.get_ticks_usec()
		if frame >= WARMUP:
			frame_times.append(float(started - previous) / 1000.0)
		previous = started
		arena.run.set_paused(false)
		arena.player.hurt_cooldown = 1.0
		# Distribute replenished projectiles over the arena rather than stacking them.
		while arena.projectiles.items.size() < 128:
			arena.projectiles.fire(Vector2(random.randf_range(50, 580), random.randf_range(85, 310)), Vector2.RIGHT.rotated(random.randf_range(0, TAU)))
		while arena.hostile_projectiles.items.size() < 64:
			arena.hostile_projectiles.fire(Vector2(random.randf_range(50, 580), random.randf_range(85, 310)), Vector2.RIGHT.rotated(random.randf_range(0, TAU)), 130.0)
		arena._burst(Vector2(random.randf_range(80, 560), random.randf_range(100, 300)), Color.WHITE, 160)
		var simulation_start := Time.get_ticks_usec()
		arena._physics_process(1.0 / 60.0)
		if arena.enemy_views.size() != 18 or not arena.run.is_active():
			push_error("Invalid dense scenario: all 18 enemy visuals and active combat are required")
			arena.free()
			quit(1)
			return
		var simulation_end := Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		if frame >= WARMUP:
			simulation_times.append(float(simulation_end - simulation_start) / 1000.0)
			submission_times.append(float(Time.get_ticks_usec() - simulation_end) / 1000.0)
			peak_draw_calls = maxi(peak_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			peak_memory = maxi(peak_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var report := {
		"engine": Engine.get_version_info().string,
		"platform": OS.get_name(), "processor": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"window_size": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"vsync": "disabled", "fps_cap": 0,
		"scenario": "Rendered dense arena, 18 enemies (6 each type), 128 player shots, 64 hostile shots, 160 particles; refill before each simulation step; stationary invulnerable player; seeded automation",
		"warmup_frames": WARMUP, "measured_frames": FRAMES,
		"frame_interval_ms": stats(frame_times),
		"simulation_ms": stats(simulation_times),
		"post_simulation_to_frame_post_draw_ms": stats(submission_times),
		"peak_draw_calls": peak_draw_calls, "peak_static_memory_bytes": peak_memory,
		"limitations": "Frame intervals include refill, CPU work, rendering and scheduling. frame_post_draw measures CPU-side rendering completion, not isolated GPU time. Fixed 1/60 simulation step; automated load, not difficulty playtesting. Hardware-specific; not a minimum-spec claim."
	}
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://render-benchmark.json"
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write render benchmark report")
		arena.free()
		quit(1)
		return
	output.store_string(JSON.stringify(report, "  ") + "\n")
	output.close()
	if root.get_texture().get_image().save_png(path.get_basename() + ".png") != OK:
		push_error("Cannot save benchmark screenshot")
		arena.free()
		quit(1)
		return
	print(JSON.stringify(report, "  "))
	arena.free()
	quit()
