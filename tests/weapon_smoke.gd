extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://weapon_smoke_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func damage_at(resource: String, distance: float) -> int:
	var player = load("res://scripts/player/player_state.gd").new()
	var shots = load("res://scripts/combat/projectile_system.gd").new()
	player.weapon = load(resource)
	shots.weapon = player.weapon
	player.player_position = Vector2(100, 180)
	player.shot.connect(shots.fire)
	var bounds := Rect2(0, 0, 640, 360)
	player.advance(0.01, Vector2.ZERO, Vector2(600, 180), false, true, bounds)
	check(shots.items.size() == player.weapon.pellets, "Trigger must emit one configured volley")
	var enemies: Array[Dictionary] = [{"position": Vector2(100 + distance, 178), "health": 100, "flash": 0.0}]
	shots.advance(1.0, enemies, bounds)
	return 100 - int(enemies[0].health)
func volleys_to_defeat(resource: String, target_profile: Resource, heavy: bool) -> int:
	var player = load("res://scripts/player/player_state.gd").new()
	var shots = load("res://scripts/combat/projectile_system.gd").new()
	player.weapon = load(resource).duplicate()
	var upgrades = load("res://scripts/run/upgrade_system.gd").new()
	upgrades.stacks[&"heavy"] = 1 if heavy else 0
	player.weapon.damage = int(upgrades.value("damage", player.weapon.damage))
	shots.weapon = player.weapon
	player.player_position = Vector2(100, 180)
	player.shot.connect(shots.fire)
	var bounds := Rect2(0, 0, 640, 360)
	var enemies: Array[Dictionary] = [{"position": Vector2(300, 180), "health": target_profile.health, "profile": target_profile, "facing": Vector2.LEFT, "flash": 0.0}]
	for volley in range(1, target_profile.health + 1):
		player.advance(player.weapon.fire_interval, Vector2.ZERO, Vector2(300, 180), false, true, bounds)
		shots.advance(1.0, enemies, bounds)
		if enemies.is_empty():
			return volley
	return -1

func _run() -> void:
	check(damage_at("res://resources/dawn_bow.tres", 200) == 1, "Dawn Bow must hit distant targets")
	check(damage_at("res://resources/judgment_lance.tres", 200) == 4, "Judgment Lance must deal heavy bolt damage")
	var bow := "res://resources/dawn_bow.tres"
	var lance := "res://resources/judgment_lance.tres"
	var charger := preload("res://resources/default_charger.tres")
	var guardian := preload("res://resources/default_guardian.tres")
	check(volleys_to_defeat(bow, charger, false) == 4 and volleys_to_defeat(lance, charger, false) == 1, "Lance must interrupt charger pressure with one shot")
	check(volleys_to_defeat(bow, guardian, false) == 8 and volleys_to_defeat(lance, guardian, true) == 3, "Heavy Rounds must cross a frontal armor breakpoint for Lance")
	var melee = load("res://scripts/combat/melee_system.gd").new()
	for melee_id in ["sword_ablaze", "seraph_halberd"]:
		melee.settings = load("res://resources/%s.tres" % melee_id)
		var group: Array[Dictionary] = [
			{"position": Vector2(124, 180), "health": 2},
			{"position": Vector2(121, 205), "health": 2},
			{"position": Vector2(147, 180), "health": 3},
		]
		melee.swing(Vector2(100, 180), Vector2.RIGHT, group)
		var remaining := Vector2(147, 180) if melee_id == "sword_ablaze" else Vector2(121, 205)
		check(group.size() == 1 and group[0].position == remaining, "Sword should cover the flank while Halberd reaches the distant target")
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://weapon_smoke.json")
	arena.preferences.selected_weapon = &"scatter"
	check(arena.preferences.save() == OK, "Legacy loadout fixture must save")
	arena.preferences.load_preferences()
	check(arena.preferences.selected_weapon == &"dawn_bow", "Legacy loadout must resolve to Dawn Bow")
	arena.preferences.selected_weapon = &"judgment_lance"
	arena.preferences.selected_melee = &"seraph_halberd"
	check(arena.preferences.save() == OK, "Loadout must save")
	root.add_child(arena)
	arena.set_physics_process(false)
	check(arena.ranged_id == &"dawn_bow" and arena.melee_id == &"sword_ablaze", "Saved locked weapons must fall back on arena entry")
	var candidate: Dictionary = arena.profile.data.duplicate(true)
	candidate.xp = 300
	check(arena.profile._commit(candidate) == OK, "Test profile must have enough XP")
	check(arena.profile.purchase_skill("michael_edge") == OK, "Ember Edge must be purchasable")
	check(arena.profile.purchase_skill("michael_reach") == OK, "Flame Reach must be purchasable")
	arena._reset_run()
	check(arena.ranged_id == &"judgment_lance" and arena.melee_id == &"seraph_halberd", "Both unlocked choices must survive reload")
	check(arena.projectiles.weapon == arena.player.weapon and arena.melee.settings == arena.player.melee_settings, "Both attacks must use their equipped tuning")
	var enemies: Array[Dictionary] = [{"position": Vector2(150, 100), "health": 20, "flash": 0.0}]
	arena.melee.swing(Vector2(100, 100), Vector2.RIGHT, enemies)
	check(enemies[0].health == 16, "Halberd must apply its reach and skill-adjusted damage")
	arena.upgrades.stacks[&"rapid"] = 1
	arena._apply_upgrades()
	check(arena.player.weapon.fire_interval < 0.48, "Fire-rate upgrades must affect the equipped ranged weapon")
	arena._reset_run()
	check(is_equal_approx(arena.player.weapon.fire_interval, 0.48), "Restart must remove temporary upgrades")
	check(arena.profile.reset_skills() == OK, "Respec must succeed")
	arena._reset_run()
	check(arena.ranged_id == &"dawn_bow" and arena.melee_id == &"sword_ablaze", "Respec must revoke both equipped unlocks")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.preferences.path + suffix)
	arena.free()
	await create_timer(0.35).timeout
	print("Weapon checks complete: %d failures" % failures)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(1 if failures else 0)
