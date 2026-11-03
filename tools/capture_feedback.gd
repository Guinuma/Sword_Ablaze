extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_feedback_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")
func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://feedback-review"
	DirAccess.make_dir_recursive_absolute(folder)
	for reduced in [false, true]:
		arena.preferences.reduced_motion = reduced
		arena.preferences.reduced_flashes = reduced
		arena.feedback.clear()
		for index in range(7):
			arena.feedback.add([&"spawn", &"dash", &"upgrade", &"heal", &"wave", &"melee", &"critical"][index], Vector2(80 + index * 80, 180))
		arena.feedback.advance(0.05)
		arena.queue_redraw()
		arena.overlay.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(folder.path_join("feedback-" + str(reduced) + ".png")) != OK:
			quit(1)
			return
	arena.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
