extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_skills_profile.json")
	call_deferred("_run")
func _run() -> void:
	var profile = load("res://scripts/run/global_profile.gd").for_tree(self)
	profile.load_profile()
	var fixture: Dictionary = profile.data.duplicate(true)
	fixture.xp = 400
	fixture.skills = []
	profile._commit(fixture)
	var hub = load("res://scenes/main/hub.tscn").instantiate()
	hub.pause_on_focus_loss = false
	root.add_child(hub)
	hub.set_physics_process(false)
	hub._show_gabriel()
	hub.detail_body.get_child(3).pressed.emit()
	for mode in ["available", "learned"]:
		if mode == "learned":
			hub.skill_learn.pressed.emit()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var args := OS.get_cmdline_user_args()
		var folder: String = args[0] if not args.is_empty() else "user://skill-review"
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder.path_join("skills-" + mode + ".png"))
	hub.free()
	await create_timer(0.35).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
