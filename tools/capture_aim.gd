extends SceneTree
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var canvas := Node2D.new()
	root.add_child(canvas)
	var visual_script = load("res://scripts/player/exile_visual.gd")
	for index in range(8):
		var visual = visual_script.new()
		canvas.add_child(visual)
		visual.scale = Vector2(2, 2)
		var angle := index * TAU / 8
		visual.present(Vector2(82 + (index % 4) * 155, 150 + (index / 4) * 145), Vector2.RIGHT.rotated(angle), Vector2.ZERO, 0.0, false, false, false)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else "user://aim-review.png"
	var result := root.get_texture().get_image().save_png(path)
	canvas.free()
	quit(0 if result == OK else 1)
