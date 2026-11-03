extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://capture_elite_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_capture")
func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena._spawn_enemy(&"elite")
	var enemy: Dictionary = arena.enemies.items[0]
	enemy.position = Vector2(250, 180)
	enemy.spawn_time = 0.0
	enemy.windup = 0.8
	enemy.shot_direction = Vector2.RIGHT
	arena.waves.number = 9
	arena._update_hud()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://elite-warning.png"
	var result := root.get_texture().get_image().save_png(path)
	arena.free()
	await create_timer(0.35).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(0 if result == OK else 1)
