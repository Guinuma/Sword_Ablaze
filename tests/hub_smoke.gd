extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://hub_smoke_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func launch_from_door(hub: Node, finite: bool) -> void:
	hub.set_physics_process(false)
	hub.player.player_position = Vector2(320, 294)
	hub._interact_nearest()
	check(hub.detail_title == "LEAVE SANCTUARY", "Walkable door must open the departure menu")
	hub.detail_body.get_child(1).pressed.emit()
	check(hub.detail_title == "CHOOSE ARENA", "Departure Arenas button must open mode selection")
	hub.detail_body.get_child(1 if finite else 3).pressed.emit()
func _run() -> void:
	change_scene_to_file("res://scenes/main/menu.tscn")
	await scene_changed
	current_scene._enter_hub()
	await scene_changed
	check(current_scene.is_hub, "Title must enter sanctuary")
	current_scene._show_progression()
	check(current_scene.detail.visible and root.gui_get_focus_owner() == current_scene.back_button, "Progression must open with visible keyboard focus")
	current_scene._back()
	launch_from_door(current_scene, true)
	await scene_changed
	var arena = current_scene
	arena.set_physics_process(false)
	arena.records = arena.ArenaRecords.new("user://hub_smoke_records.json")
	check(arena.finite_mode and arena.hud_view.quit_button.text == "SANCTUARY", "Hub launch must wire finite mode and sanctuary return")
	for step in range(5000):
		if arena.run.phase == arena.RunState.Phase.UPGRADE:
			arena._choose_upgrade(arena.upgrades.offered[0].id)
		arena.player.hurt_cooldown = 1.0
		arena._physics_process(0.1)
		for enemy in arena.enemies.items.duplicate():
			if enemy.spawn_time <= 0.0:
				arena.projectiles.weapon.damage = 10000
				arena.projectiles.fire(enemy.position, Vector2.RIGHT)
				arena.projectiles.advance(0.0, arena.enemies.items, arena.ARENA)
		if arena.run.phase == arena.RunState.Phase.WON:
			break
	check(arena.run.phase == arena.RunState.Phase.WON and arena.reward_awarded == 300, "Hub-launched run must deliver one finite victory reward")
	arena.hud_view.quit_button.pressed.emit()
	await scene_changed
	check(current_scene.is_hub, "Victory return must reach sanctuary")
	var profile = current_scene.GlobalProfile.for_tree(self)
	profile.load_profile()
	check(profile.data.xp == 300, "Hub must retain exactly one victory reward")
	current_scene._show_progression()
	check(current_scene.detail_body.get_child(1).text.contains("LEVEL 4"), "Progression must display the resulting level")
	current_scene._return_to_title()
	await scene_changed
	check(not current_scene.is_hub, "Hub must return to title")
	current_scene._enter_hub()
	await scene_changed
	launch_from_door(current_scene, false)
	await scene_changed
	arena = current_scene
	arena.set_physics_process(false)
	check(not arena.finite_mode, "Hub must also launch Endless Arena")
	arena._set_paused(true)
	arena._return_to_menu()
	await scene_changed
	check(current_scene.is_hub, "Paused run must return to hub")
	profile.load_profile()
	check(profile.data.xp == 300, "Abandoning a live run must not grant XP")
	for finite in [true, false]:
		launch_from_door(current_scene, finite)
		await scene_changed
		arena = current_scene
		arena.set_physics_process(false)
		arena.records = arena.ArenaRecords.new("user://hub_smoke_records.json")
		arena.run.health = 1
		arena.player.hurt_cooldown = 0.0
		arena._take_player_damage(100)
		arena.player_visual.advance_defeat(1.0)
		arena._update_hud()
		check(arena.hud_view.menu.visible, "Defeat must expose result actions in both modes")
		arena.hud_view.restart_button.pressed.emit()
		check(arena.run.health == 100 and arena.waves.number == 1 and arena.enemies.items.is_empty(), "Defeat retry button must start a clean run")
		arena.run.health = 1
		arena.player.hurt_cooldown = 0.0
		arena._take_player_damage(100)
		var saved_xp: int = arena.profile.data.xp
		arena.hud_view.quit_button.pressed.emit()
		await scene_changed
		check(current_scene.is_hub, "Defeat return button must reach Sanctuary in both modes")
		profile.load_profile()
		check(profile.data.xp == saved_xp, "Returning after defeat must not duplicate XP")
	current_scene.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://hub_smoke_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Hub checks complete: %d failures" % failures)
	quit(1 if failures else 0)
