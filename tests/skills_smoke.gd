extends SceneTree
const Profile = preload("res://scripts/run/global_profile.gd")
const PATH := "user://skills_smoke_profile.json"
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	set_meta("profile_path", PATH)
	call_deferred("_run")
func _run() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(PATH + suffix)
	var profile = Profile.new(PATH)
	profile.load_profile()
	check(profile.purchase_skill("michael_edge") != OK and profile.skill_points() == 0, "Zero points must reject purchases")
	var seed: Dictionary = profile.data.duplicate(true)
	seed.xp = 300
	check(profile._commit(seed) == OK, "Legacy empty-skill profile must remain compatible")
	check(profile.purchase_skill("michael_reach") != OK, "Child must require its parent")
	check(profile.purchase_skill("invented") != OK, "Unknown skills must be rejected")
	check(profile.purchase_skill("michael_edge") == OK and profile.skill_points() == 2, "Root must spend exactly one derived skill point")
	var before: Dictionary = profile.data.duplicate(true)
	check(profile.purchase_skill("michael_edge") != OK and profile.data == before, "Duplicate purchase must preserve points")
	DirAccess.make_dir_absolute(PATH + ".tmp")
	check(profile.purchase_skill("michael_reach") != OK and profile.data == before, "Failed save must preserve learned nodes and balance")
	DirAccess.remove_absolute(PATH + ".tmp")
	check(profile.purchase_skill("michael_reach") == OK and profile.skill_points() == 0, "Retry must buy child exactly once")
	var reloaded = Profile.new(PATH)
	reloaded.load_profile()
	check(reloaded.data.skills.size() == 2 and reloaded.skill_points() == 0, "Reload must preserve purchases without duplicate accounting")
	var invalid: Dictionary = reloaded.data.duplicate(true)
	invalid.skills = ["michael_reach"]
	check(Profile._clean(invalid).is_empty(), "Forged missing prerequisites must reject the save")
	invalid.skills = ["michael_edge", "michael_edge"]
	check(Profile._clean(invalid).is_empty(), "Duplicate stored skills must reject the save")
	invalid.skills = ["michael_edge", "michael_reach", "raphael_vigor"]
	check(Profile._clean(invalid).is_empty(), "Stored overspending must reject the save")
	check(reloaded.reset_skills() == OK and reloaded.data.xp == 300 and reloaded.skill_points() == 3, "Free reset must refund all points without changing XP")
	seed = reloaded.data.duplicate(true)
	seed.xp = 900
	reloaded._commit(seed)
	for definition in Profile.Skills.NODES:
		check(reloaded.purchase_skill(definition.id) == OK, "All six small-tree nodes must be purchasable")
	check(reloaded.skill_points() == 0 and reloaded.data.xp == 900, "Full small tree must cost nine points and never spend XP")
	var hub = load("res://scenes/main/hub.tscn").instantiate()
	hub.pause_on_focus_loss = false
	root.add_child(hub)
	hub.set_physics_process(false)
	hub._show_gabriel()
	hub.detail_body.get_child(3).pressed.emit()
	check(hub.skill_buttons.size() == 6 and hub.skill_buttons["michael_edge"].text.begins_with("LEARNED"), "Gabriel must display persistent learned state")
	var count: int = hub.detail_history.size()
	hub._show_skill_tree()
	check(hub.detail_history.size() == count, "Refreshing purchases must not duplicate navigation history")
	hub.free()
	await process_frame
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://skills_smoke_preferences.json")
	arena.records = arena.ArenaRecords.new("user://skills_smoke_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	check(arena.run.max_health == 110 and arena.player.melee_settings == arena.melee.settings, "Learned skills must apply to actual run health and shared melee settings")
	check(is_equal_approx(arena.player.weapon.projectile_speed, 396.0) and is_equal_approx(arena.player.weapon.critical_chance, 0.05), "Gabriel skills must apply to actual weapon simulation")
	check(is_equal_approx(arena.player.dash_recharge, 1.08), "Raphael must reduce the actual dash recharge")
	arena.player.weapon.critical_chance = 0
	arena.enemies.items.append({"position": arena.player.player_position + Vector2(47, 0), "health": 10, "flash": 0.0})
	arena.melee.swing(arena.player.player_position, Vector2.RIGHT, arena.enemies.items)
	check(arena.enemies.items[0].health == 7, "Michael must extend a real melee hit and add its damage")
	arena.upgrades.stacks[&"vitality"] = 1
	arena.upgrades.stacks[&"critical"] = 1
	arena._apply_upgrades()
	check(arena.run.max_health == 130 and is_equal_approx(arena.player.weapon.critical_chance, 0.15), "Temporary blessings must compose with permanent knowledge once")
	arena._apply_upgrades()
	check(arena.run.max_health == 130 and arena.player.melee_settings.damage == 3, "Recalculation must not stack permanent effects again")
	arena._reset_run()
	check(arena.run.max_health == 110 and is_equal_approx(arena.player.weapon.critical_chance, 0.05), "Retry must remove blessings while preserving learned knowledge")
	arena.free()
	await create_timer(0.35).timeout
	profile.load_profile()
	before = profile.data.duplicate(true)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	check(profile.reset_skills() != OK and profile.data == before, "Failed reset must retain learned skills")
	DirAccess.remove_absolute(PATH + ".tmp")
	check(profile.reset_skills() == OK and profile.skill_points() == 9, "Successful reset must refund all six nodes")
	for path in [PATH, "user://skills_smoke_preferences.json", "user://skills_smoke_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Skill checks complete: %d failures" % failures)
	quit(1 if failures else 0)
