extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://section7_capture_profile.json")
	call_deferred("_run")
func frame(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func _run() -> void:
	var menu = load("res://scenes/main/menu.tscn").instantiate()
	root.add_child(menu)
	menu._show_options()
	await frame("res://docs/art/section7-options.png")
	menu._show_feedback_options()
	await frame("res://docs/art/section7-feedback-options.png")
	menu.free()
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://section7_capture_preferences.json")
	arena.records = arena.ArenaRecords.new("user://section7_capture_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.player.player_position = Vector2(320, 225)
	arena.player_visual.present(arena.player.player_position, Vector2.RIGHT, Vector2.ZERO, 0, false, false, false)
	for index in range(18):
		arena._spawn_enemy([&"chaser", &"ranged", &"guardian"][index % 3])
		var enemy: Dictionary = arena.enemies.items.back()
		enemy.position = Vector2(180 + (index % 6) * 43, 165 + (index / 6) * 43)
		enemy.spawn_time = 0.0
		arena.hostile_projectiles.fire(enemy.position, Vector2.DOWN, 80.0, 20)
	for index in range(7):
		arena.feedback.add([&"spawn", &"dash", &"upgrade", &"heal", &"wave", &"melee", &"critical"][index], Vector2(80 + index * 80, 270))
	arena._burst(Vector2(320, 200), Color("ffb454"), 20)
	arena._update_hud()
	arena.queue_redraw()
	await frame("res://docs/art/section7-dense.png")
	arena._change_preferences(true, true)
	await frame("res://docs/art/section7-reduced.png")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://section7_capture_preferences.json", "user://section7_capture_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	quit()
