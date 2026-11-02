extends SceneTree
## Deterministic accelerated session exercising the real scene lifecycle.
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://soak_records.json")
	arena.preferences = arena.Preferences.new("user://soak_preferences.json")
	for path in [arena.records.path, arena.preferences.path]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.random.seed = 12345
	var highest_wave: int = 1
	var chosen: int = 0
	for frame in range(24000):
		if arena.run.phase == arena.RunState.Phase.UPGRADE:
			check(not arena.upgrades.offered.is_empty(), "Upgrade state must always have a valid option")
			if not arena.upgrades.offered.is_empty():
				arena._choose_upgrade(arena.upgrades.offered[0].id)
				chosen += 1
		# Test driver defeats activated enemies; survival balance is not tested here.
		for enemy in arena.enemies.items:
			if enemy.get("spawn_time", 0.0) == 0.0:
				arena.projectiles.fire(enemy["position"], Vector2.RIGHT)
				arena.projectiles.fire(enemy["position"], Vector2.RIGHT)
		arena.player.hurt_cooldown = 1.0
		arena._physics_process(0.05)
		highest_wave = maxi(highest_wave, arena.waves.number)
		check(arena.enemies.items.size() <= arena.waves.settings.max_enemies, "Soak must respect enemy cap")
		check(arena.projectiles.items.size() <= arena.projectiles.MAX_PROJECTILES, "Soak must respect player projectile cap")
		check(arena.hostile_projectiles.items.size() <= arena.hostile_projectiles.MAX_PROJECTILES, "Soak must respect hostile projectile cap")
		check(arena.particles.size() <= 160 and arena.player.player_position.is_finite(), "Soak must retain bounded effects and finite player position")
		if frame % 1200 == 0:
			var elapsed: float = arena.run.elapsed
			arena._set_paused(true)
			arena._physics_process(10.0)
			check(arena.run.elapsed == elapsed, "Long-session pause must freeze time")
			arena._set_paused(false)
		if frame == 20000:
			arena._reset_run()
			check(arena.upgrades.stacks.is_empty() and arena.run.kills == 0 and arena.waves.number == 1, "Long-session restart must remove modifiers and counters")
	check(highest_wave >= 30 and chosen >= 10, "Accelerated session must reach advanced waves and repeated upgrades")
	arena.run.health = 1
	arena.player.hurt_cooldown = 0.0
	arena._take_player_damage()
	check(arena.run.phase == arena.RunState.Phase.DEAD and arena.records.data["runs"] == 1, "Long session must end with exactly one recorded defeat")
	for path in [arena.records.path, arena.preferences.path]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Soak reached wave %d with %d upgrade choices" % [highest_wave, chosen])
	print("Run soak complete: %d failures" % failures)
	arena.free()
	quit(0 if failures == 0 else 1)
