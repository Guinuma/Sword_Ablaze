extends SceneTree
## Render the defeat sequence without changing the player's real records.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		quit(1)
		return
	var folder: String = args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://visual_review_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.run.health = 1
	arena.run.elapsed = 62.0
	arena.run.kills = 12
	arena.waves.number = 3
	arena._take_player_damage()
	arena.player_visual.set_process(false)
	for frame in range(20):
		if frame > 0:
			arena.player_visual.advance_defeat(0.05)
		arena._update_hud()
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		var result := capture.save_png(folder.path_join("frame-%03d.png" % frame))
		if frame == 10:
			capture.save_png("res://docs/art/exile-defeat-gameplay-01.png")
		if result != OK:
			quit(1)
			return
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.records.path + suffix)
	arena.free()
	quit()
