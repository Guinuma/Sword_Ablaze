extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_tutorial_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")
func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://tutorial-review"
	DirAccess.make_dir_recursive_absolute(folder)
	for step in range(5):
		arena.tutorial.step = step
		arena._update_hud()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(folder.path_join("tutorial-%d.png" % step)) != OK:
			quit(1)
			return
	arena.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
