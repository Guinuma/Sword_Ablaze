extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://melee_flow_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://melee_flow_records.json")
	arena.preferences = arena.Preferences.new("user://melee_flow_preferences.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	# Exercise input/release timing independently of the optional real-time accents.
	arena.preferences.hit_stop = false
	arena.preferences.screen_shake = false
	arena.run.start_intermission()
	arena.run.start_upgrade()
	arena.upgrades.offered.clear()
	arena.upgrades.offered.append(load("res://resources/upgrades/critical.tres"))
	arena._choose_upgrade(&"critical")
	check(is_equal_approx(arena.player.weapon.critical_chance, 0.1) and arena.melee.weapon == arena.projectiles.weapon, "Chosen Keen Edge must apply to both attack systems")
	arena.run.start_combat(2)
	arena.player.weapon.critical_chance = 1.0
	arena._physics_process(0.01)
	var direction: Vector2 = (arena.get_global_mouse_position() - arena.player.player_position).normalized()
	if direction.length_squared() < 0.001:
		direction = arena.player.aim
	arena.enemies.items.append({"position": arena.player.player_position + direction * 25, "health": 3, "flash": 0.0})
	Input.action_press("melee")
	arena._physics_process(0.01)
	check(arena.run.kills == 1 and arena.enemies.items.is_empty(), "Live melee input must eliminate a target through shared kill events")
	var kinds: Array = []
	for cue in arena.feedback.items:
		kinds.append(cue.kind)
	check(kinds.has(&"melee") and kinds.has(&"critical"), "Melee critical must show both distinct feedback cues")
	var cooldown: float = arena.player.melee_cooldown
	arena._set_paused(true)
	arena._physics_process(1.0)
	check(arena.player.melee_cooldown == cooldown, "Pause must freeze melee cooldown")
	arena._set_paused(false)
	arena.enemies.items.append({"position": arena.player.player_position + direction * 25, "health": 10, "flash": 0.0})
	arena._physics_process(0.6)
	check(arena.enemies.items[0].health == 10, "Held melee must not attack immediately after resume")
	Input.action_release("melee")
	arena._physics_process(0.01)
	Input.action_press("melee")
	arena._physics_process(0.01)
	check(arena.enemies.items[0].health == 6, "Fresh melee after release must apply one critical hit")
	Input.action_release("melee")
	arena._reset_run()
	check(arena.player.melee_time == 0.0 and arena.player.melee_cooldown == 0.0 and arena.player.weapon.critical_chance == 0.0, "Restart must clear melee timing and temporary critical chance")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://melee_flow_records.json", "user://melee_flow_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Melee flow checks complete: %d failures" % failures)
	quit(1 if failures else 0)
