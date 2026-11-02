extends SceneTree
## Review HUD states without altering real records or preferences.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://hud_review_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "res://docs/art"
	DirAccess.make_dir_recursive_absolute(folder)
	for mode in ["combat", "critical", "pause", "blessing", "defeat"]:
		arena._reset_run()
		arena.run.elapsed = 125.0
		arena.run.kills = 123
		arena.waves.number = 12
		arena.player.dash_cooldown = 0.6
		if mode == "critical":
			arena.run.health = 1
			arena.run.elapsed = 5999.0
			arena.run.kills = 99999
			arena.waves.number = 125
		if mode == "pause":
			arena._set_paused(true)
		if mode == "blessing":
			arena.waves.number = 3
			arena._on_wave_cleared()
		if mode == "defeat":
			arena.run.health = 1
			arena._take_player_damage()
			arena.player_visual.advance_defeat(1.0)
		arena._update_hud()
		arena.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(folder.path_join("hud-%s-01.png" % mode))
		if result != OK:
			quit(1)
			return
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.records.path + suffix)
	arena.free()
	quit()
