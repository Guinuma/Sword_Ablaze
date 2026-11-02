extends SceneTree
## Capture the actual renderer with a deterministic visual review encounter.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.waves.number = 3
	arena.waves.remaining = 3
	arena.run.elapsed = 32.0
	var positions: Array[Vector2] = [Vector2(150, 150), Vector2(430, 150), Vector2(245, 270), Vector2(505, 250), Vector2(120, 285), Vector2(500, 100)]
	for index in range(positions.size()):
		arena._spawn_enemy(&"ranged" if index >= 3 else &"chaser")
		var enemy: Dictionary = arena.enemies.items.back()
		enemy["position"] = positions[index]
		enemy["spawn_time"] = 0.0
		if index == 3:
			enemy["windup"] = 0.4
			enemy["shot_direction"] = positions[index].direction_to(arena.player.player_position)
	arena.projectiles.fire(Vector2(355, 200), Vector2.RIGHT)
	arena.projectiles.fire(Vector2(385, 200), Vector2.RIGHT)
	arena.hostile_projectiles.fire(Vector2(420, 230), Vector2.LEFT, 130.0)
	arena.player_visual.present(arena.player.player_position, Vector2.RIGHT, Vector2.ZERO, 0.0, false, false, false)
	arena._update_hud()
	arena.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var arguments := OS.get_cmdline_user_args()
	var output: String = arguments[0] if not arguments.is_empty() else "res://docs/art/celestial-courtyard-gameplay-01.png"
	var result := root.get_texture().get_image().save_png(output)
	arena.free()
	quit(0 if result == OK else 1)
