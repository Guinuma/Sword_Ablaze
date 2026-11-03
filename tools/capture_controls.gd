extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var menu = load("res://scenes/main/menu.tscn").instantiate()
	root.add_child(menu)
	menu._show_bindings()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://keyboard-options.png"
	var result := root.get_texture().get_image().save_png(path)
	menu.free()
	quit(0 if result == OK else 1)
