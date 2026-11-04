extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://player_art_capture_profile.json")
	call_deferred("_run")
func label_at(parent: Node, text: String, point: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 8)
	parent.add_child(label)
func save_frame(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not save player art review")
func _run() -> void:
	var board := Node2D.new()
	root.add_child(board)
	var script = load("res://scripts/player/exile_visual.gd")
	var rows := ["IDLE", "WALK", "DASH", "HURT", "MELEE", "FALL"]
	for row in range(rows.size()):
		for col in range(8):
			var panel := ColorRect.new()
			panel.position = Vector2(col * 80, 18 + row * 55)
			panel.size = Vector2(79, 54)
			panel.color = Color("777c80") if col % 2 == 0 else Color("172332")
			board.add_child(panel)
			var visual = script.new()
			board.add_child(visual)
			var aim := Vector2.RIGHT.rotated(col * TAU / 8)
			visual.present(Vector2(34 + col * 80, 49 + row * 55), aim, aim.rotated(PI / 4) if row in [1, 2] else Vector2.ZERO, 0.16, row == 2, row == 3, row == 4, 0.08 if row == 4 else 0.0)
			if row == 2:
				visual.present(visual.position, aim, aim.rotated(PI / 4), 0.08, true, false, false)
			if row == 5:
				visual.begin_defeat()
				visual.advance_defeat(col * 0.09)
				visual.set_process(false)
			label_at(board, rows[row], Vector2(2 + col * 80, 19 + row * 55))
	label_at(board, "THE EXILE / REFINED ART REVIEW / 8 AIM DIRECTIONS", Vector2(8, 1))
	await save_frame("res://docs/art/exile-native-review.png")
	board.free()
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://player_art_capture_preferences.json")
	arena.records = arena.ArenaRecords.new("user://player_art_capture_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.random.seed = 505
	arena.player.player_position = Vector2(320, 200)
	arena.player.aim = Vector2(1, -0.4).normalized()
	for index in range(12):
		arena._spawn_enemy(&"ranged" if index % 3 == 0 else &"chaser")
		var point := Vector2(100 + (index % 6) * 85, 130 + (index / 6) * 120)
		arena.enemies.items.back().position = point
		arena.enemies.items.back().spawn_time = 0.0
		arena._burst(point, Color("ed874b"), 10)
		arena.hostile_projectiles.fire(point, point.direction_to(arena.player.player_position), 100, 10)
	for index in range(24):
		var direction := Vector2.RIGHT.rotated(index * TAU / 24)
		var point: Vector2 = arena.player.player_position + direction * (45.0 + (index % 3) * 18)
		arena.hostile_projectiles.fire(point, -direction, 100, 10)
		if index % 3 == 0:
			arena._burst(point, Color("ed874b"), 5)
	for index in range(6):
		arena.projectiles.fire(arena.player.player_position + Vector2(28 + index * 13, -12 - index * 4), Vector2.RIGHT)
	arena._update_effects(0.08)
	arena.player_visual.present(arena.player.player_position, arena.player.aim, Vector2(1, 1), 0.16, false, false, true)
	arena._update_hud()
	arena.queue_redraw()
	await save_frame("res://docs/art/exile-native-gameplay.png")
	arena._set_paused(true)
	await save_frame("user://exile-native-pause.png")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://player_art_capture_preferences.json", "user://player_art_capture_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	quit()
