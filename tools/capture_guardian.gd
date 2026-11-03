extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_guardian_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")
func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena._spawn_enemy(&"guardian")
	var enemy: Dictionary = arena.enemies.items[0]
	enemy.position = Vector2(220, 180)
	enemy.spawn_time = 0.0
	enemy.charge_direction = Vector2.RIGHT
	enemy.charge_timer = 0.5
	var args := OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "user://guardian-review"
	DirAccess.make_dir_recursive_absolute(folder)
	for phase in ["front", "side", "rear"]:
		enemy.facing = {"front": Vector2.DOWN, "side": Vector2.RIGHT, "rear": Vector2.UP}[phase]
		arena._update_hud()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(folder.path_join("guardian-" + phase + ".png")) != OK:
			quit(1)
			return
	arena.free()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit()
