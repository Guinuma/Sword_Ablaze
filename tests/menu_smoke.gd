extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	change_scene_to_file("res://scenes/main/menu.tscn")
	await scene_changed
	var menu = current_scene
	check(menu.home.visible and not menu.detail.visible, "Startup must show the main menu")
	check(root.gui_get_focus_owner() == menu.play_button, "Play must receive keyboard focus")
	await create_timer(0.1).timeout
	check(get_nodes_in_group("enemies").is_empty(), "Menu must not instantiate combat")
	menu._show_controls()
	check(menu.detail.visible and not menu.home.visible, "Controls must replace home")
	menu._back()
	menu.preferences = menu.Preferences.new("user://menu_smoke_preferences.json")
	menu._show_options()
	check(menu.detail_body.get_child(1) is CheckButton, "Options must expose visual preferences")
	var toggle = menu.detail_body.get_child(2)
	toggle.button_pressed = true
	var saved = menu.Preferences.new(menu.preferences.path)
	saved.load_preferences()
	check(saved.reduced_motion, "Options must persist visual preferences")
	var frozen: float = menu.clock
	menu._process(1.0)
	check(menu.clock == frozen, "Reduced motion must stop menu animation")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(menu.preferences.path + suffix)
	menu._back()
	menu._start_game()
	await scene_changed
	var arena = current_scene
	check(arena.scene_file_path == "res://scenes/main/main.tscn", "Play must open arena")
	arena.set_physics_process(false)
	check(arena.player.fire_requires_release, "Entry must require releasing the menu click")
	arena._set_paused(true)
	arena.hud_view.main_menu_requested.emit()
	await scene_changed
	check(current_scene.scene_file_path == "res://scenes/main/menu.tscn", "Pause must return to menu")
	current_scene._start_game()
	await scene_changed
	arena = current_scene
	arena.set_physics_process(false)
	check(arena.run.health == 100 and arena.run.kills == 0 and arena.upgrades.stacks.is_empty(), "New run must start fresh")
	# Avoid writing real records while verifying the results exit.
	arena.run_recorded = true
	for index in range(7):
		arena.run.take_damage()
	arena.player_visual.defeat_done = true
	arena._update_hud()
	check(arena.hud_view.menu.visible and not arena.hud_view.resume_button.visible, "Defeat must show results")
	arena.hud_view.main_menu_requested.emit()
	await scene_changed
	check(current_scene.scene_file_path == "res://scenes/main/menu.tscn", "Results must return to menu")
	print("Menu checks complete: %d failures" % failures)
	quit(failures)
