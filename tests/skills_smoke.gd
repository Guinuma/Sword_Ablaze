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
	seed.xp = Profile.xp_cap()
	check(reloaded._commit(seed) == OK, "New cap fixture must save")
	var hybrid := ["michael_edge", "michael_ember", "michael_pyre", "joan_standard", "joan_break", "joan_counter", "holy_furnace"]
	for id in hybrid:
		if id == "joan_counter":
			check(reloaded.purchase_skill("holy_furnace") != OK, "Holy Furnace must require both branches")
		check(reloaded.purchase_skill(id) == OK, "Hybrid path must fit under the new cap: " + id)
	check(reloaded.skill_points() == Profile.max_level() - 1 - Profile.Skills.spent(hybrid), "Hybrid path must spend only its listed costs")
	var legacy: Dictionary = reloaded.data.duplicate(true)
	legacy.xp = 1900
	legacy.skills = []
	for definition in Profile.Skills.NODES:
		if definition.id not in ["gabriel_seal", "gabriel_verdict", "raphael_grace", "raphael_shelter"]:
			legacy.skills.append(definition.id)
	check(reloaded._commit(legacy) == OK, "Existing higher-cap build must remain valid")
	reloaded.load_profile()
	check(reloaded.data.xp == 1900 and reloaded.skill_points() == 0, "Legacy build must keep XP and skills with no extra points")
	check(reloaded.purchase_skill("gabriel_seal") != OK, "A legacy profile cannot purchase over the current cap")
	var capped_run: int = reloaded.begin_run(&"endless")
	check(reloaded.settle(capped_run, &"endless", &"defeat", 20, 2).awarded == 0 and reloaded.data.xp == 1900, "Rewards must preserve above-cap legacy XP without adding more")
	var hub = load("res://scenes/main/hub.tscn").instantiate()
	hub.pause_on_focus_loss = false
	root.add_child(hub)
	hub.set_physics_process(false)
	hub._show_gabriel()
	hub.detail_body.get_child(3).pressed.emit()
	check(hub.skill_buttons.size() == 17 and hub.skill_learn.text == "LEARNED", "Gabriel must display persistent learned state")
	hub.skill_buttons["joan_stand"].grab_focus()
	check(hub.skill_name.text == "UNBROKEN STAND" and hub.skill_learn.disabled, "Keyboard focus must inspect a learned Joan node")
	await process_frame
	check(hub.detail_body.get_child(3).get_global_rect().end.y <= hub.back_button.get_global_rect().position.y, "Glass tree must fit above Back")
	hub.skill_buttons["holy_furnace"].grab_focus()
	await process_frame
	check(hub.skill_name.text == "HOLY FURNACE" and hub.skill_learn.text == "LEARNED", "Hybrid node must be selectable in the glass")
	check(hub.skill_status.get_global_rect().end.y <= hub.back_button.get_global_rect().position.y, "Hybrid inspector must fit above Back")
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
	check(is_equal_approx(arena.player.move_speed, 126.0) and arena.melee.settings.knockback == 200.0, "Joan must improve real movement and melee knockback")
	arena.player.weapon.critical_chance = 0
	arena.enemies.items.append({"position": arena.player.player_position + Vector2(47, 0), "health": 10, "flash": 0.0})
	arena.melee.swing(arena.player.player_position, Vector2.RIGHT, arena.enemies.items)
	check(arena.enemies.items[0].health == 7, "Michael must extend a real melee hit and add its damage")
	_check_attributes(arena)
	arena.upgrades.stacks[&"vitality"] = 1
	arena.upgrades.stacks[&"critical"] = 1
	arena._apply_upgrades()
	check(arena.run.max_health == 130 and is_equal_approx(arena.player.weapon.critical_chance, 0.15), "Temporary blessings must compose with permanent knowledge once")
	arena._apply_upgrades()
	check(arena.run.max_health == 130 and arena.player.melee_settings.damage == 3, "Recalculation must not stack permanent effects again")
	arena._reset_run()
	check(arena.run.max_health == 110 and is_equal_approx(arena.player.weapon.critical_chance, 0.05), "Retry must remove blessings while preserving learned knowledge")
	profile.load_profile()
	before = profile.data.duplicate(true)
	DirAccess.make_dir_absolute(PATH + ".tmp")
	check(profile.reset_skills() != OK and profile.data == before, "Failed reset must retain learned skills")
	DirAccess.remove_absolute(PATH + ".tmp")
	check(profile.reset_skills() == OK and profile.skill_points() == Profile.max_level() - 1, "Successful reset must refund the full build")
	for id in ["gabriel_focus", "gabriel_precision", "gabriel_seal", "gabriel_verdict", "raphael_vigor", "raphael_step", "raphael_grace", "raphael_shelter"]:
		check(profile.purchase_skill(id) == OK, "Light and Vitality build must be purchasable: " + id)
	arena._reset_run()
	_check_light_and_vitality(arena)
	arena.free()
	await create_timer(0.35).timeout
	for path in [PATH, "user://skills_smoke_preferences.json", "user://skills_smoke_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Skill checks complete: %d failures" % failures)
	quit(1 if failures else 0)


func _check_attributes(arena: Node) -> void:
	var origin: Vector2 = arena.player.player_position
	var target: Dictionary = {"position": origin + Vector2(28, 0), "health": 20, "flash": 0.0}
	var neighbor: Dictionary = {"position": origin + Vector2(29, 24), "health": 15, "flash": 0.0}
	arena.enemies.items.assign([target])
	arena.melee.swing(origin, Vector2.RIGHT, arena.enemies.items)
	check(target.fire_meter == 1 and target.impact_meter == 1, "Real Sword Ablaze hits must fill Fire and Impact meters")
	arena.player.dashed.emit()
	arena.melee.swing(origin, Vector2.RIGHT, arena.enemies.items)
	check(target.health == 11 and target.burn_ticks == 0 and target.stagger_time > 0.0, "Countercharge must trigger stagger and Holy Furnace must consume all three burn ticks")
	check(arena.attributes.counter_time == 0.0, "Countercharge must be consumed by the eligible hit")
	check(not arena.enemies.touches(target.position), "Staggered enemies must not deal contact damage")

	target.health = 2
	target["burn_ticks"] = 3
	target["burn_time"] = arena.attributes.BURN_INTERVAL
	arena.enemies.items.append(neighbor)
	var kills: int = arena.run.kills
	arena.attributes.advance(arena.attributes.BURN_INTERVAL * 2.1, arena.enemies.items)
	check(arena.run.kills == kills + 1 and arena.enemies.items.size() == 1, "Burn must remove enemies and record exactly one kill")
	check(neighbor.burn_ticks == 2 and neighbor.health == 15, "Pyre must spread burn without immediately ticking the new target")
	arena.projectiles.fire(neighbor.position, Vector2.RIGHT)
	neighbor.health = 1
	var third := {"position": neighbor.position + Vector2(0, 10), "health": 10, "flash": 0.0}
	arena.enemies.items.append(third)
	arena.projectiles.advance(0.0, arena.enemies.items, arena.ARENA)
	check(third.get("burn_ticks", 0) == 2, "Ranged kills must also trigger Pyre")

	var boss := {"health": 20, "impact_meter": 3}
	arena.attributes.melee_hit(boss, true, true)
	check(boss.get("stagger_time", 0.0) == 0.0, "Bosses must require more Impact than ordinary enemies")
	arena.attributes.melee_hit(boss, true, true)
	check(is_equal_approx(boss.stagger_time, 0.18), "Boss stagger must have a short duration")


func _check_light_and_vitality(arena: Node) -> void:
	var origin: Vector2 = arena.player.player_position
	var target := {"position": origin + Vector2(24, 0), "health": 30, "flash": 0.0}
	var other := {"position": origin + Vector2(24, 20), "health": 30, "flash": 0.0}
	arena.enemies.items.assign([target, other])
	arena.player.weapon.critical_chance = 0.0
	for enemy in [target, target, other, target, target]:
		arena.projectiles.fire(enemy.position, Vector2.RIGHT)
		arena._update_bullets(0.0)
	check(target.get("light_time", 0.0) == 0.0, "Changing ranged targets must break the Light streak")
	arena.projectiles.fire(target.position, Vector2.RIGHT)
	arena._update_bullets(0.0)
	check(target.light_time > 0.0 and target.health == 25, "Third consecutive projectile must mark its target")
	arena.melee.swing(origin, Vector2.RIGHT, arena.enemies.items)
	check(target.light_time == 0.0 and target.health == 20, "Verdict must consume the mark and apply exactly three extra damage")

	arena.run.start_combat(1)
	arena.healing_drops.clear()
	arena.healing_drops.spawn(origin, 10)
	arena.healing_drops.advance(0.0, origin, arena.run)
	check(arena.attributes.shield == 12 and arena.healing_drops.items.is_empty(), "Grace must turn a full-health pickup into a shield")
	arena.healing_drops.spawn(origin, 10)
	arena.healing_drops.advance(0.0, origin, arena.run)
	check(arena.healing_drops.items.size() == 1, "Grace must preserve pickups while shielded")
	arena.projectiles.fire(target.position, Vector2.RIGHT)
	arena._update_bullets(0.0)
	check(is_equal_approx(target.knockback.length(), arena.player.weapon.knockback * 1.3), "Shelter must amplify knockback while shielded")
	var health: int = arena.run.health
	arena._take_player_damage(15)
	check(arena.attributes.shield == 0 and arena.run.health == health - 3, "Damage above shield strength must reach health")
	arena.healing_drops.advance(0.0, origin, arena.run)
	check(arena.run.health == health and arena.attributes.shield == 0, "Injured players must still collect normal healing")
	arena.healing_drops.spawn(origin, 10)
	arena.healing_drops.advance(0.0, origin, arena.run)
	arena.attributes.advance(4.0, arena.enemies.items)
	check(arena.attributes.shield == 0, "Grace must expire in active combat time")
