extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Section 6 visual sweep requires rendering")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var system = load("res://scripts/enemies/enemy_system.gd").new()
	var visual = load("res://scripts/enemies/enemy_visual.gd").new()
	root.add_child(visual)
	var random := RandomNumberGenerator.new()
	var count := 0
	for kind in [&"charger", &"guardian", &"elite", &"boss"]:
		system.clear()
		system.spawn(Vector2(320, 180), Rect2(0, 0, 640, 360), random, kind)
		var enemy: Dictionary = system.items[0]
		enemy.position = Vector2(320, 200)
		enemy.spawn_time = 0.0
		for angle in range(16):
			for pose in range(4):
				for reduced in [false, true]:
					enemy.facing = Vector2.RIGHT.rotated(angle * TAU / 16)
					enemy.charge_direction = enemy.facing
					enemy.shot_direction = enemy.facing
					enemy.charge_phase = ["approach", "warning", "charge", "recovery"][pose]
					enemy.boss_phase = 1 if pose < 2 else 2
					enemy.boss_attack = "ring" if pose % 2 == 0 else "fan"
					enemy.windup = 0.5 if pose % 2 else 0.0
					enemy.flash = 0.1 if pose == 3 else 0.0
					visual.present(enemy, float(count) * 0.01, reduced, reduced)
					await process_frame
					await RenderingServer.frame_post_draw
					count += 1
	visual.free()
	print("Section 6 visual sweep complete: %d rendered combinations" % count)
	quit()
