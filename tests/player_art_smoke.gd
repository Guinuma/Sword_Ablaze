extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var visual = load("res://scripts/player/exile_visual.gd").new()
	root.add_child(visual)
	check(visual.BODY_HEIGHT == 32.0, "Refined Exile must retain the 32px gameplay height")
	for frames in [visual.FRONT, visual.BACK, visual.SIDE]:
		check(frames.get_frame_count(&"poses") == 9 and frames.get_frame_count(&"walk") == 4, "Each direction must include idle, four walk, two dash and two hurt poses")
	check(visual.DEFEAT.get_frame_count(&"poses") == 4, "Refined defeat must retain four distinct poses")
	for pair in [[Vector2.DOWN, &"front"], [Vector2.UP, &"back"], [Vector2.LEFT, &"side"], [Vector2.RIGHT, &"side"]]:
		visual.present(Vector2(100.4, 120.7), pair[0], Vector2.ZERO, 0.0, false, false, false)
		check(visual.body_direction == pair[1] and visual.sprite_frame() == 0 and visual.position == Vector2(100, 121), "Cardinal idle must keep shared grid and direction")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, 0.15, false, false, false)
	check(visual.sprite_frame() in [1, 2, 3, 4], "Diagonal travel must select an actual walk pose")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT, 0.0, true, false, false)
	check(visual.sprite_frame() == 5, "Dash onset must select its dedicated launch pose")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT, 0.08, true, false, false)
	check(visual.sprite_frame() == 6, "Dash must advance to its dedicated trailing pose")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 0.0, false, true, false)
	check(visual.sprite_frame() == 7, "Nonfatal damage must select a dedicated recoil pose")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 0.1, false, true, false)
	check(visual.sprite_frame() == 8, "Hurt pose must advance to recovery")
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 0.1, false, true, false)
	check(visual.sprite_frame() == 0, "Long invulnerability must not hold the player in recoil")
	visual.reduced_motion = true
	visual.reduced_flashes = true
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 0.0, false, false, false)
	visual.present(Vector2.ZERO, Vector2.RIGHT, Vector2.ZERO, 0.0, false, true, false)
	check(visual.sprite_frame() == 7, "Reduced effects must retain readable nonflashing damage pose")
	visual.begin_defeat()
	visual.advance_defeat(0.64)
	check(visual.defeat_done, "Native defeat must retain result timing")
	visual.reset_pose()
	check(not visual.defeated and not visual.hurt and not visual.dashing and visual.sprite_frame() == 0, "Reset must clear native animation state")
	visual.free()
	print("Player art checks complete: %d failures" % failures)
	quit(1 if failures else 0)
