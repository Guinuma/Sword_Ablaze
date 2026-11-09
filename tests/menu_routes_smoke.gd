extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://menu_routes_profile.json")
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func buttons(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	load("res://scripts/ui/focus_navigation.gd").collect(node, result)
	return result
func press(menu: Node, text: String) -> void:
	for button in buttons(menu.detail if menu.detail.visible else menu.home):
		if button is Button and button.text == text:
			button.grab_focus()
			button.pressed.emit()
			return
	check(false, "Missing visible button: " + text)
func escape(menu: Node) -> void:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	menu._unhandled_input(event)
func _run() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	var profile = load("res://scripts/run/global_profile.gd").for_tree(self)
	var candidate: Dictionary = profile.defaults()
	candidate.xp = 300
	candidate.skills = ["michael_edge", "michael_reach"]
	check(profile._commit(candidate) == OK, "Test profile must unlock Michael's weapons")
	change_scene_to_file("res://scenes/main/menu.tscn")
	await scene_changed
	var menu = current_scene
	menu.preferences = menu.Preferences.new("user://menu_routes_preferences.json")
	var labels: Array = []
	for button in buttons(menu.home):
		labels.append(button.text)
	check(labels == ["PLAY", "OPTIONS", "QUIT"], "Title must have exactly the three requested actions in order")
	press(menu, "PLAY")
	labels.clear()
	for button in buttons(menu.detail):
		labels.append(button.text)
	check(labels == ["SANCTUARY", "ARENAS", "ROGUELITE", "CAMPAIGN", "SOUNDTRACK", "QUIT", "BACK"], "Play must expose all six actions in order and Back")
	for feature in ["ROGUELITE", "CAMPAIGN", "SOUNDTRACK"]:
		press(menu, feature)
		check(menu.detail_title == feature and menu.detail_body.get_child(1).text == "WORK IN PROGRESS", "Unfinished features must show WIP")
		check(current_scene == menu and not has_meta("finite_run"), "WIP must not launch combat or change mode")
		escape(menu)
		check(menu.detail_title == "PLAY" and root.gui_get_focus_owner().text == feature, "Escape must return to Play and restore the clicked action")
	press(menu, "ARENAS")
	press(menu, "BACK")
	check(menu.detail_title == "PLAY" and root.gui_get_focus_owner().text == "ARENAS", "Arena Back must return to Play")
	escape(menu)
	check(menu.home.visible and root.gui_get_focus_owner() == menu.play_button, "Play Escape must return to title Play")
	press(menu, "OPTIONS")
	for entry in [["HOW TO PLAY", "HOW TO PLAY"], ["WEAPON LOADOUT", "WEAPON LOADOUT"], ["COMBAT FEEDBACK", "COMBAT FEEDBACK"], ["AUDIO VOLUMES", "AUDIO"], ["KEYBOARD BINDINGS", "KEYBOARD"]]:
		press(menu, entry[0])
		check(menu.detail_title == entry[1], "Options must preserve access to " + entry[0])
		if entry[0] == "WEAPON LOADOUT":
			var depth: int = menu.detail_history.size()
			press(menu, "EQUIP: JUDGMENT LANCE")
			check(menu.preferences.selected_weapon == &"judgment_lance" and menu.detail_history.size() == depth, "Equipping must save without adding duplicate history")
			var saved = menu.Preferences.new(menu.preferences.path)
			saved.load_preferences()
			check(saved.selected_weapon == &"judgment_lance", "Weapon choice must remain persistent through the new menu route")
		escape(menu)
		check(menu.detail_title == "OPTIONS" and root.gui_get_focus_owner().text == entry[0], "Nested settings must return to Options with focus restored")
	escape(menu)
	press(menu, "PLAY")
	press(menu, "SANCTUARY")
	await scene_changed
	check(current_scene.is_hub, "Sanctuary action must open the existing hub")
	current_scene._return_to_title()
	await scene_changed
	for finite in [true, false]:
		menu = current_scene
		press(menu, "PLAY")
		press(menu, "ARENAS")
		press(menu, "COURTYARD RUN" if finite else "ENDLESS ARENA")
		await scene_changed
		var arena = current_scene
		arena.set_physics_process(false)
		arena.records = arena.ArenaRecords.new("user://menu_routes_records.json")
		check(arena.finite_mode == finite and not get_meta("return_to_hub"), "Direct Play arena selection must retain its mode and title return")
		arena._set_paused(true)
		arena.hud_view.main_menu_requested.emit()
		await scene_changed
		check(current_scene.scene_file_path == "res://scenes/main/menu.tscn", "Arena pause must return to title")
	current_scene.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://menu_routes_records.json", "user://menu_routes_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Menu routes checks complete: %d failures" % failures)
	quit(1 if failures else 0)
