extends SceneTree
func _initialize() -> void:
	set_meta("profile_path", "user://section6_review_profile.json")
	set_meta("finite_run", true)
	call_deferred("_run")
func save_frame(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not save section 6 capture")
func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://section6_review_preferences.json")
	arena.records = arena.ArenaRecords.new("user://section6_review_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.waves.number = 10
	arena.waves.remaining = 0
	arena.run.cleared_waves = 9
	arena.player.player_position = Vector2(320, 265)
	arena.player.aim = Vector2.RIGHT
	arena.player_visual.present(arena.player.player_position, Vector2.RIGHT, Vector2.ZERO, 0.0, false, false, false)
	var entries := [[&"boss", Vector2(320, 155)], [&"charger", Vector2(200, 230)], [&"guardian", Vector2(440, 222)], [&"elite", Vector2(245, 155)], [&"ranged", Vector2(530, 210)], [&"chaser", Vector2(90, 220)]]
	for entry in entries:
		arena._spawn_enemy(entry[0])
		var enemy: Dictionary = arena.enemies.items.back()
		enemy.position = entry[1]
		enemy.spawn_time = 0.0
		enemy.charge_phase = "warning"
		enemy.charge_direction = Vector2(1, 0.2).normalized()
		enemy.facing = Vector2.DOWN
		enemy.shot_direction = Vector2.DOWN
		enemy.boss_attack = "fan"
		enemy.boss_phase = 1
		enemy.windup = 0.0
	arena.healing_drops.spawn(Vector2(285, 280), 10)
	arena.healing_drops.spawn(Vector2(355, 280), 100)
	arena._update_hud()
	arena.queue_redraw()
	await save_frame("res://docs/art/section6-arena.png")
	arena.enemies.items[0].boss_phase = 2
	arena.enemies.items[0].health = 50
	arena.enemies.items[0].windup = 0.6
	arena.enemies.items[3].windup = 0.8
	arena._update_hud()
	arena.queue_redraw()
	await save_frame("res://docs/art/section6-warden-phase2.png")
	var debug := Node2D.new()
	debug.z_index = 2
	arena.add_child(debug)
	debug.draw.connect(func():
		for footprint in arena.geometry.obstacles:
			debug.draw_rect(footprint, Color(0.2, 1.0, 1.0, 0.6), false, 1.0)
	)
	await save_frame("user://section6-collision-review.png")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://section6_review_preferences.json", "user://section6_review_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	quit()
