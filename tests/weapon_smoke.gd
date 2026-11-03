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
func _run() -> void:
	check(damage_at("res://resources/scatter_weapon.tres", 40) == 5, "Close target must receive all five pellets")
	check(damage_at("res://resources/scatter_weapon.tres", 200) == 1, "Distant small target must receive only center pellet")
	check(damage_at("res://resources/default_weapon.tres", 40) == 1 and damage_at("res://resources/default_weapon.tres", 200) == 1, "Rifle must retain accurate single hits at both ranges")
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://weapon_smoke.json")
	arena.preferences.selected_weapon = &"scatter"
	check(arena.preferences.save() == OK, "Loadout must save")
	root.add_child(arena)
	arena.set_physics_process(false)
	check(arena.player.weapon.pellets == 5 and arena.projectiles.weapon == arena.player.weapon, "Selected loadout must drive both timing and projectile simulation")
	arena.upgrades.stacks[&"rapid"] = 1
	arena._apply_upgrades()
	check(arena.player.weapon.fire_interval < 0.55, "Fire-rate upgrades must affect the selected weapon")
	arena._reset_run()
	check(arena.player.weapon.pellets == 5 and is_equal_approx(arena.player.weapon.fire_interval, 0.55), "Restart must retain loadout and remove temporary upgrades")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.preferences.path + suffix)
	arena.free()
	await create_timer(0.35).timeout
	print("Weapon checks complete: %d failures" % failures)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(1 if failures else 0)
