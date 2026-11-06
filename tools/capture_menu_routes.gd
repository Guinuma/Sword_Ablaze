extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://menu_routes_capture_profile.json")
	call_deferred("_run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not save menu route capture")
func _run() -> void:
	var menu = load("res://scenes/main/menu.tscn").instantiate()
	root.add_child(menu)
	menu.preferences = menu.Preferences.new("user://menu_routes_capture_preferences.json")
	menu.preferences.reduced_motion = true
	menu.clock = 0
	await capture("res://docs/art/priority1-title.png")
	menu._show_play()
	await capture("res://docs/art/priority1-play.png")
	menu._show_work_in_progress("CAMPAIGN")
	await capture("res://docs/art/priority1-wip.png")
	menu._show_options()
	await capture("res://docs/art/priority1-options.png")
	menu.save_error.text = "Could not save preferences."
	await capture("res://docs/art/priority1-options-error.png")
	menu.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://menu_routes_capture_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	quit()
