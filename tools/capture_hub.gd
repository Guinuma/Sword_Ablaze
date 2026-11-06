extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://hub_capture_profile.json")
	call_deferred("_capture")
func _capture() -> void:
	var profile = load("res://scripts/run/global_profile.gd").for_tree(self)
	profile.load_profile()
	var fixture: Dictionary = profile.data.duplicate(true)
	fixture.xp = 300
	profile._commit(fixture)
	var hub = load("res://scenes/main/hub.tscn").instantiate()
	hub.preferences = hub.Preferences.new("user://hub_capture_preferences.json")
	hub.pause_on_focus_loss = false
	root.add_child(hub)
	hub.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://hub-review"
	DirAccess.make_dir_recursive_absolute(folder)
	for mode in ["home", "gabriel", "knowledge", "progression", "arsenal", "departure", "options"]:
		while hub.detail.visible:
			hub._back()
		match mode:
			"gabriel":
				hub.player.player_position = Vector2(450, 188)
				hub.advance_walk(0, Vector2.ZERO)
				hub._interact_nearest()
			"knowledge": hub._show_skill_tree()
			"progression": hub._show_progression()
			"arsenal": hub._show_loadout()
			"departure": hub._show_departure()
			"options": hub._show_options()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(folder.path_join("hub-" + mode + ".png")) != OK:
			quit(1)
			return
	hub.free()
	await create_timer(0.35).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
