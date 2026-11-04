extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://boss_reinforcement_profile.json")
	set_meta("finite_run", true)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://boss_reinforcement_preferences.json")
	arena.records = arena.ArenaRecords.new("user://boss_reinforcement_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.waves.number = 10
	arena.waves.remaining = 1
	arena.waves.spawn_cooldown = 0.0
	arena.run.cleared_waves = 9
	arena._update_waves(0.01)
	check(arena.enemies.items.size() == 1 and arena.enemies.items[0].profile.kind == "boss", "Finale must begin with exactly one Warden")
	arena._update_waves(30.0)
	check(arena.enemies.items.size() == 1, "Reinforcements must wait for Warden activation")
	arena.enemies.items[0].spawn_time = 0.0
	arena._update_waves(1.0)
	var remaining: float = arena.boss_reinforcement_time
	arena._set_paused(true)
	arena._physics_process(20.0)
	check(arena.boss_reinforcement_time == remaining and arena.enemies.items.size() == 1, "Pause must freeze reinforcement timer")
	arena._set_paused(false)
	arena._update_waves(remaining)
	check(arena.enemies.items.size() == 2 and arena.enemies.items[1].spawn_time > 0.0, "Escorts must use ordinary safe spawn warnings")
	var kinds: Array[StringName] = []
	for index in range(20):
		arena._update_waves(3.0)
		check(arena.enemies.items.size() <= 10, "Warden plus active and pending escorts must never exceed ten")
	for enemy in arena.enemies.items.slice(1):
		kinds.append(StringName(enemy.profile.kind))
	check(kinds.has(&"chaser") and kinds.has(&"ranged") and kinds.has(&"charger"), "Finale must mix pursuit, ranged and charge pressure")
	arena.enemies.items.remove_at(1)
	arena._update_waves(0.01)
	check(arena.enemies.items.size() == 10, "A freed escort slot must be replenished")
	# Kill the actual Warden through projectile events, leaving escorts alive.
	var boss: Dictionary = arena.enemies.items[0]
	boss.position = Vector2(320, 100)
	for enemy in arena.enemies.items.slice(1):
		enemy.position = Vector2(500, 280)
	arena.projectiles.weapon.damage = 10000
	arena.projectiles.fire(boss.position, Vector2.RIGHT)
	arena.projectiles.advance(0.0, arena.enemies.items, arena.ARENA)
	check(arena.enemies.items.size() == 9, "Projectile must defeat only the Warden")
	arena._update_waves(0.01)
	check(arena.run.phase == arena.RunState.Phase.WON and arena.enemies.items.is_empty(), "Warden defeat must dismiss escorts and finish immediately")
	check(arena.hostile_projectiles.items.is_empty() and arena.reward_received, "Victory must clear hostile fire and settle its reward")
	arena._physics_process(30.0)
	check(arena.enemies.items.is_empty(), "Victory must never spawn more escorts")
	arena.hud_view.restart_button.pressed.emit()
	check(arena.waves.number == 1 and arena.boss_reinforcement_count == 0 and arena.enemies.items.is_empty(), "Result retry must reset finale and all reinforcements")
	arena.run.health = 1
	arena.player.hurt_cooldown = 0.0
	arena._take_player_damage(100)
	arena._physics_process(30.0)
	check(arena.run.phase == arena.RunState.Phase.DEAD and arena.enemies.items.is_empty(), "Defeat must stop reinforcements")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://boss_reinforcement_preferences.json", "user://boss_reinforcement_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Boss reinforcement checks complete: %d failures" % failures)
	quit(1 if failures else 0)
