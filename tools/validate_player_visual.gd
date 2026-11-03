extends SceneTree
## Graphical regression: checks rendering across facing/travel/state combinations.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Player visual check requires graphical rendering")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var visual = load("res://scripts/player/exile_visual.gd").new()
	root.add_child(visual)
	for index in range(16):
		for movement in range(16):
			for state in range(4):
				visual.present(Vector2(320, 200), Vector2.RIGHT.rotated(index * TAU / 16), Vector2.RIGHT.rotated(movement * TAU / 16), 0.1, state == 1, state == 2, state == 3, 0.1 if state == 3 else 0.0)
				await process_frame
				await RenderingServer.frame_post_draw
	visual.free()
	print("Player visual sweep complete: 1024 rendered combinations")
	quit()
