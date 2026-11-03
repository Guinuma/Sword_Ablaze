extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func cycle(start: Control, count: int, key: int = KEY_TAB, reverse: bool = false) -> void:
	start.grab_focus()
	for index in range(count):
		var current := root.gui_get_focus_owner()
		check(current != null and current.is_visible_in_tree(), "Focus must stay visible")
		check(current.has_theme_stylebox_override("focus"), "Focused controls must have a visible focus style")
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.shift_pressed = reverse
		event.pressed = true
		root.push_input(event)
		await process_frame
	check(root.gui_get_focus_owner() == start, "Tab must complete a closed focus cycle")
func _run() -> void:
	change_scene_to_file("res://scenes/main/menu.tscn")
	await scene_changed
	var menu = current_scene
	await cycle(menu.play_button, 4)
	await cycle(menu.play_button, 4, KEY_TAB, true)
	await cycle(menu.play_button, 4, KEY_DOWN)
	menu._show_controls()
	await cycle(menu.back_button, 1)
	menu._show_options()
	await cycle(menu.detail_body.get_child(1), 5)
	menu._show_audio()
	await cycle(menu.detail_body.get_child(1).get_child(1), 5)
	menu._show_bindings()
	await cycle(menu.detail_body.get_child(1).get_child(0), 9)
	menu._start_game()
	await scene_changed
	var arena = current_scene
	arena.set_physics_process(false)
	arena._set_paused(true)
	await cycle(arena.hud_view.resume_button, 5)
	arena._set_paused(false)
	arena.waves.number = 3
	arena._on_wave_cleared()
	arena._update_hud()
	check(arena.hud_view.pause_button.disabled, "Blessing choice must exclude combat pause button from focus")
	await cycle(arena.hud_view.choice_buttons[0], 3)
	await cycle(arena.hud_view.choice_buttons[0], 3, KEY_UP)
	arena._set_paused(true)
	await cycle(arena.hud_view.resume_button, 5)
	arena._set_paused(false)
	check(root.gui_get_focus_owner() == arena.hud_view.choice_buttons[0], "Resume must restore choice focus")
	arena.run_recorded = true
	arena.run.phase = arena.RunState.Phase.DEAD
	arena.player_visual.defeat_done = true
	arena._update_hud()
	await cycle(arena.hud_view.restart_button, 2)
	print("Navigation checks complete: %d failures" % failures)
	quit(1 if failures else 0)
