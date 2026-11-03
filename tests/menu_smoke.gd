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
	menu._show_loadout()
	menu._equip_weapon(&"scatter")
	var loadout_saved = menu.Preferences.new(menu.preferences.path)
	loadout_saved.load_preferences()
	check(loadout_saved.selected_weapon == &"scatter", "Loadout menu must save the equipped weapon")
	menu._equip_weapon(&"blade")
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
	menu._show_bindings()
	check(menu.detail_body.get_child(1) is GridContainer, "Keyboard settings must expose action buttons")
	menu._capture_binding(&"dash")
	var key := InputEventKey.new()
	key.keycode = KEY_Q
	key.physical_keycode = KEY_Q
	key.pressed = true
	menu._input(key)
	check(menu.binding_action == &"" and menu.preferences.bindings.get(&"dash") == KEY_Q, "Capture must apply and finish")
	menu._show_controls()
	check(menu.detail_body.get_child(4).text.begins_with("Q"), "Help must show the remapped dash key")
	menu._capture_binding(&"fire")
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	menu._input(key)
	check(menu.binding_action == &"" and not menu.preferences.bindings.has(&"fire"), "Escape must cancel capture")
	menu.preferences.reset_bindings()
	menu.preferences.save()
	menu._show_audio()
	for bus in menu.Preferences.AUDIO_BUSES:
		var index := AudioServer.get_bus_index(bus)
		check(index >= 0, "Audio bus must exist: " + bus)
		if bus != "Master":
			check(AudioServer.get_bus_send(index) == &"Master", "Category must route to Master")
	var master_slider = menu.detail_body.get_child(1).get_child(1)
	master_slider.value = 0.0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Zero Master must mute output")
	var music_slider = menu.detail_body.get_child(2).get_child(1)
	music_slider.value = 35.0
	saved.load_preferences()
	check(saved.volumes["Music"] == 0.35 and saved.volumes["Master"] == 0.0, "Independent audio values must survive reload")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.35)) < 0.01, "Music gain must apply to its bus")
	master_slider.value = 100.0
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Raising Master must unmute output")
	check(menu.preferences.volumes["Music"] == 0.35, "Master adjustment must preserve category volume")
	menu.preferences.set_volume("Music", 2.0)
	check(menu.preferences.volumes["Music"] == 1.0, "Audio values must clamp to supported range")
	for bus in menu.Preferences.AUDIO_BUSES:
		menu.preferences.set_volume(bus, 1.0)
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
	current_scene._show_modes()
	current_scene._start_game(true)
	await scene_changed
	arena = current_scene
	arena.set_physics_process(false)
	check(arena.finite_mode and arena.waves.final_wave == 10 and arena.records.path == "user://finite_records.json", "Finite menu route must select finale and separate records")
	arena._set_paused(true)
	arena.hud_view.main_menu_requested.emit()
	await scene_changed
	current_scene.free()
	await create_timer(0.35).timeout
	print("Menu checks complete: %d failures" % failures)
	quit(failures)
