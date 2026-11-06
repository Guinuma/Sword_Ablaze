extends SceneTree
var failures := 0
var shots := 0
var melees := 0
var dashes := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	set_meta("profile_path", "user://sanctuary_smoke_profile.json")
	call_deferred("_run")
func input_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)
	await process_frame
func _run() -> void:
	for path in [String(get_meta("profile_path")), "user://sanctuary_smoke_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	var hub = load("res://scenes/main/hub.tscn").instantiate()
	hub.preferences = hub.Preferences.new("user://sanctuary_smoke_preferences.json")
	root.add_child(hub)
	hub.set_physics_process(false)
	hub.pause_on_focus_loss = false
	check(hub.player.player_position == hub.Layout.START and not hub.detail.visible, "Hub must open as a walkable home")
	check(hub.geometry.obstacles.size() == hub.Layout.FURNITURE.size(), "Furniture must share visual/collision footprints")
	hub.player.shot.connect(func(_origin, _direction): shots += 1)
	hub.player.melee.connect(func(_origin, _direction): melees += 1)
	hub.player.dashed.connect(func(): dashes += 1)
	Input.action_press("move_right")
	Input.action_press("fire")
	Input.action_press("melee")
	Input.action_press("dash")
	var start: Vector2 = hub.player.player_position
	hub._physics_process(0.1)
	for action in ["move_right", "fire", "melee", "dash"]:
		Input.action_release(action)
	check(is_equal_approx(hub.player.player_position.x - start.x, 12.0), "Hub must use the existing movement action and speed")
	check(shots == 0 and melees == 0 and dashes == 0, "The home must never attack or dash")
	hub.player.player_position = Vector2(320, 250)
	hub.advance_walk(0.1, Vector2(1, 1))
	check(is_equal_approx(hub.player.player_position.distance_to(Vector2(320, 250)), 12.0), "Diagonal walking must be normalized")
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		hub.player.player_position = hub.Layout.START
		hub.advance_walk(100.0, direction)
		check(hub.Layout.BOUNDS.grow(-8).has_point(hub.player.player_position - direction * 0.001), "Even long steps must stay inside the room")
		check(is_inf(hub.geometry.segment_hit(hub.player.player_position, hub.player.player_position, 7.9)), "Movement must not tunnel into furniture")
	# Every station is reachable from the entry using the shared visibility graph.
	for station in hub.Layout.STATIONS:
		hub.player.player_position = hub.Layout.START
		for step in range(700):
			var waypoint: Vector2 = hub.geometry.waypoint(hub.player.player_position, station.point, 8.0)
			hub.advance_walk(1.0 / 60, (waypoint - hub.player.player_position).normalized())
			if hub.player.player_position.distance_to(station.point) < 4:
				break
		check(hub.player.player_position.distance_to(station.point) < 4, "Station must be reachable: " + String(station.id))
		check(hub.nearby.get("id") == station.id, "Reachable station must offer the correct interaction")
	check(hub.Layout.nearest(Vector2(450, 156), hub.geometry).is_empty(), "Gabriel interaction must not pass through a solid body")
	hub.player.player_position = Vector2(320, 200)
	hub._interact_nearest()
	check(not hub.detail.visible, "Interaction from afar must do nothing")
	hub.player.player_position = Vector2(450, 188)
	hub._update_prompt()
	await input_action(&"ui_accept")
	check(hub.detail_title == "GABRIEL", "Enter near Gabriel must open the mentor conversation")
	var point: Vector2 = hub.player.player_position
	hub.advance_walk(1.0, Vector2.LEFT)
	check(hub.player.player_position == point, "Dialogue must freeze movement")
	var skill_button = hub.detail_body.get_child(3)
	skill_button.grab_focus()
	skill_button.pressed.emit()
	check(hub.detail_title == "GABRIEL'S KNOWLEDGE" and hub.detail_body.get_child(1).text.contains("MICHAEL"), "Gabriel must open the explicit skill-tree preview")
	check(hub.detail_body.get_child(3).text == "WORK IN PROGRESS", "Future skill purchases must remain visibly unfinished")
	await input_action(&"ui_cancel")
	check(hub.detail_title == "GABRIEL" and root.gui_get_focus_owner().text == "SKILL TREE", "Nested Back must restore Gabriel and keyboard focus")
	await input_action(&"ui_cancel")
	check(not hub.detail.visible and hub.home.visible and root.gui_get_focus_owner() == null, "Closing dialogue must return control to walking")
	hub.player.player_position = Vector2(133, 276)
	hub._update_prompt()
	hub.prompt.pressed.emit()
	check(hub.detail_title == "WEAPON LOADOUT", "Arsenal click must open the existing equipment screen")
	hub._equip_weapon(&"scatter")
	hub._back()
	var saved = hub.Preferences.new(hub.preferences.path)
	saved.load_preferences()
	check(saved.selected_weapon == &"scatter", "Arsenal must save the selected weapon")
	hub.player.player_position = Vector2(320, 294)
	hub._interact_nearest()
	check(hub.detail_title == "LEAVE SANCTUARY", "Door must offer departure, not start combat automatically")
	hub.detail_body.get_child(2).pressed.emit()
	check(hub.detail_title == "ROGUELITE" and hub.detail_body.get_child(1).text == "WORK IN PROGRESS", "Door must preserve future-mode WIP")
	hub._back()
	check(hub.detail_title == "LEAVE SANCTUARY", "Future-mode Back must return to the door")
	hub._back()
	await input_action(&"ui_cancel")
	check(hub.detail_title == "SANCTUARY MENU", "Escape while walking must open the hub menu")
	hub.detail_body.get_child(2).pressed.emit()
	hub.preferences.reduced_motion = true
	hub._back()
	check(hub.detail_title == "SANCTUARY MENU", "Options must return to the hub menu")
	hub.detail_body.get_child(1).pressed.emit()
	hub._physics_process(0.0)
	check(not hub.detail.visible and hub.player_visual.reduced_motion, "Resume must apply visual preferences and restore walking")
	hub.pause_on_focus_loss = true
	hub._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(hub.detail_title == "SANCTUARY MENU", "Focus loss must pause home movement")
	hub._back()
	var profile = hub.GlobalProfile.for_tree(self)
	profile.load_profile()
	check(profile.data.xp == 0 and profile.data.active_run.id == 0, "Exploration and mentor screens must never allocate runs or grant XP")
	hub.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://sanctuary_smoke_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Sanctuary checks complete: %d failures" % failures)
	quit(1 if failures else 0)
