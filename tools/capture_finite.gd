extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_finite_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")
func _capture() -> void:
	set_meta("finite_run", true)
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://finite_capture_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.run.cleared_waves = 9
	arena.run.kills = 114
	arena.run.elapsed = 600.0
	arena.waves.number = 10
	arena.waves.remaining = 0
	arena._spawn_enemy(&"boss")
	var boss: Dictionary = arena.enemies.items[0]
	boss.position = Vector2(300, 175)
	boss.spawn_time = 0.0
	boss.shot_direction = Vector2.RIGHT
	boss.boss_attack = "ring"
	boss.windup = 0.8
	for index in range(9):
		arena._update_waves(arena.waves.settings.boss_reinforcement_interval)
	for index in range(1, arena.enemies.items.size()):
		arena.enemies.items[index].position = Vector2(100 + (index % 5) * 95, 110 + (index / 5) * 165)
		arena.enemies.items[index].spawn_time = 0.0
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://finite-review"
	DirAccess.make_dir_recursive_absolute(folder)
	for mode in ["phase-one", "phase-two", "victory"]:
		boss.boss_phase = 2 if mode == "phase-two" else 1
		boss.health = 50 if mode == "phase-two" else 120
		if mode == "victory":
			arena.enemies.clear()
			arena._on_run_won()
		arena._update_hud()
		arena.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(folder.path_join(mode + ".png")) != OK:
			quit(1)
			return
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.records.path + suffix)
	arena.free()
	await create_timer(0.35).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
