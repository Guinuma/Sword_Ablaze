extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://reward_flow_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	for finite in [false, true]:
		set_meta("finite_run", finite)
		var arena = load("res://scenes/main/main.tscn").instantiate()
		arena.records = arena.ArenaRecords.new("user://reward_flow_records.json")
		root.add_child(arena)
		arena.set_physics_process(false)
		arena._on_wave_cleared()
		arena._on_wave_cleared()
		check(arena.run.cleared_waves == 1, "Repeated clear callback must not count a wave twice")
		arena.run.start_combat(2)
		arena.run.kills = 7
		arena.run.health = 1
		var id: int = arena.active_run_id
		var xp: int = arena.profile.data.xp
		var path: String = arena.profile.path
		arena.profile.path = path + "/blocked.json"
		arena._take_player_damage()
		arena.player_visual.defeat_done = true
		arena._update_hud()
		check(arena.reward_pending and arena.profile.data.xp == xp, "Failed terminal save must keep pending XP without changing total")
		check(arena.hud_view.reward_retry_button.visible and arena.hud_view.reward_label.text.contains("NOT SAVED"), "Failed reward must expose retry and honest result text")
		arena._reset_run()
		check(arena.active_run_id == id and arena.run.phase == arena.RunState.Phase.DEAD, "Failed save must retain result before retry can replace it")
		arena.profile.path = path
		arena.hud_view.reward_retry_button.grab_focus()
		arena._retry_reward()
		check(arena.reward_received and not arena.reward_pending and arena.reward_awarded == 17, "Both modes must apply seven kills plus one cleared wave")
		check(arena.profile.data.xp == xp + 17, "Actual global total must increase only after successful save")
		check(not arena.hud_view.reward_retry_button.visible and root.gui_get_focus_owner() == arena.hud_view.restart_button, "Successful retry must restore usable result focus")
		arena._retry_reward()
		arena._update_hud()
		check(arena.profile.data.xp == xp + 17, "Repeated result presentation must not grant XP again")
		var loaded = arena.GlobalProfile.new(path)
		loaded.load_profile()
		check(loaded.data.xp == xp + 17 and loaded.data.active_run.id == 0, "Reward must remain settled after reload")
		arena._reset_run()
		check(arena.run.cleared_waves == 0 and arena.active_run_id > id and arena.profile.data.xp == xp + 17, "Restart must reset temporary counters while preserving global XP")
		arena.free()
		await create_timer(0.35).timeout
	var file := FileAccess.open(String(get_meta("profile_path")), FileAccess.WRITE)
	file.store_string('{"version":99}')
	file.close()
	var unavailable = load("res://scenes/main/main.tscn").instantiate()
	unavailable.records = unavailable.ArenaRecords.new("user://reward_flow_records.json")
	root.add_child(unavailable)
	unavailable.set_physics_process(false)
	check(unavailable.active_run_id == 0 and unavailable.hud_view.control_hint.text.contains("UNAVAILABLE"), "Unsupported profile must keep combat playable with an explicit notice")
	unavailable.run.kills = 5
	unavailable.run.health = 1
	unavailable._take_player_damage()
	check(not unavailable.reward_received and not unavailable.reward_pending, "Unavailable profile must not invent a reward identity")
	check(FileAccess.get_file_as_string(String(get_meta("profile_path"))) == '{"version":99}', "Combat must preserve future profile bytes")
	unavailable.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://reward_flow_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Reward flow checks complete: %d failures" % failures)
	quit(1 if failures else 0)
