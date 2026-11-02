extends SceneTree
## Review cardinal-facing sprites with walking and idle poses in the real scene.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.player_visual.hide()
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for index in range(4):
		for row in range(2):
			var visual = arena.ExileVisual.new()
			arena.world.add_child(visual)
			var point := Vector2(170 + index * 100, 190 + row * 85)
			visual.present(point, directions[index], directions[index] if row == 0 else Vector2.ZERO, 0.2, false, false, false)
		var label := Label.new()
		label.text = ["BACK / UP", "FRONT / DOWN", "LEFT", "RIGHT"][index]
		label.position = Vector2(125 + index * 100, 130)
		label.size = Vector2(90, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		arena.hud_view.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "res://docs/art/exile-directions-02.png"
	var result := root.get_texture().get_image().save_png(path)
	arena.free()
	quit(0 if result == OK else 1)
