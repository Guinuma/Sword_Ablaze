extends SceneTree
## Render a short animation review using the same visual components as gameplay.
func _initialize() -> void:
	set_meta("profile_path", "user://capture_walk_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")


func _capture() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("Pass an output directory after --")
		quit(1)
		return
	var folder: String = arguments[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.waves.number = 3
	arena._spawn_enemy(&"ranged")
	var enemy: Dictionary = arena.enemies.items[0]
	enemy["spawn_time"] = 0.0
	for frame in range(48):
		var time := float(frame) * 0.05
		var phase := time * TAU / 2.4
		var direction := Vector2.RIGHT if cos(phase) >= 0.0 else Vector2.LEFT
		arena.run.elapsed = time
		arena.player.player_position = Vector2(320 + sin(phase) * 70.0, 190)
		arena.player_visual.present(arena.player.player_position, direction, direction, 0.05, false, false, false)
		enemy["position"] = Vector2(320 - sin(phase) * 50.0, 270)
		arena._update_hud()
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(folder.path_join("frame-%03d.png" % frame))
		if result != OK:
			arena.free()
			quit(1)
			return
	arena.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
