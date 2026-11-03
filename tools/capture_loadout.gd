extends SceneTree

func _initialize() -> void:
	set_meta("profile_path", "user://capture_loadout_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")

func _capture() -> void:
	var menu = load("res://scenes/main/menu.tscn").instantiate()
	root.add_child(menu)
	menu._show_loadout()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://weapon-loadout.png"
	var result := root.get_texture().get_image().save_png(path)
	menu.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(0 if result == OK else 1)
