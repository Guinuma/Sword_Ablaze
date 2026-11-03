extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://finite_run_smoke_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var system = load("res://scripts/enemies/enemy_system.gd").new()
	var random := RandomNumberGenerator.new()
	var bounds := Rect2(0, 0, 640, 360)
	var shots: Array[Vector2] = []
	system.shot.connect(func(_origin, direction, _speed, _damage): shots.append(direction))
	system.spawn(Vector2(320, 180), bounds, random, &"boss")
	var boss: Dictionary = system.items[0]
	boss.position = Vector2(200, 180)
	boss.spawn_time = 0.0
	for phase in [1, 2]:
		for attack in [0, 1]:
			boss.health = 120 if phase == 1 else 60
			boss.attack_index = attack
			boss.attack_cooldown = 0.0
			boss.windup = 0.0
			shots.clear()
			system.advance(0.01, Vector2(320, 180), 10, bounds)
			var directions = system.boss_directions(boss)
			check(boss.boss_phase == phase and boss.windup > 0.0 and shots.is_empty(), "Boss must announce each phase attack")
			system.advance(boss.windup, Vector2(320, 280), 10, bounds)
			check(shots.size() == (8 if phase == 1 else 12) if attack == 0 else shots.size() == (3 if phase == 1 else 5), "Boss volley count must follow phase and attack")
			check(shots == directions, "Released boss projectiles must match locked warning directions")
	for weapon in [&"blade", &"scatter"]:
		root.set_meta("finite_run", true)
		set_meta("finite_run", true)
		var arena = load("res://scenes/main/main.tscn").instantiate()
		arena.preferences = arena.Preferences.new("user://finite_smoke_preferences.json")
		arena.preferences.selected_weapon = weapon
		arena.preferences.save()
		arena.records = arena.ArenaRecords.new("user://finite_smoke_records.json")
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(arena.records.path + suffix)
		root.add_child(arena)
		arena.set_physics_process(false)
		var choices := 0
		var saw_boss := false
		for step in range(5000):
			if arena.run.phase == arena.RunState.Phase.UPGRADE:
				choices += 1
				arena._choose_upgrade(arena.upgrades.offered[0].id)
			arena.player.hurt_cooldown = 1.0
			arena._physics_process(0.1)
			# Use real projectile defeat events; automated clearing is not a difficulty test.
			for enemy in arena.enemies.items.duplicate():
				if enemy.spawn_time > 0.0:
					continue
				if enemy.profile.kind == "boss":
					saw_boss = true
					var cooldown: float = enemy.attack_cooldown
					arena._set_paused(true)
					arena._physics_process(1.0)
					check(enemy.attack_cooldown == cooldown, "Pause must freeze boss timing")
					arena._set_paused(false)
				arena.projectiles.weapon.damage = 10000
				arena.projectiles.fire(enemy.position, Vector2.RIGHT)
				arena.projectiles.advance(0.0, arena.enemies.items, arena.ARENA)
			if arena.run.phase == arena.RunState.Phase.WON:
				break
		check(arena.run.cleared_waves == 10 and arena.reward_received and arena.reward_awarded == 300, "Complete finite victory must award capped global XP once")
		check(saw_boss and choices == 3, "Finite run must contain three choices and the boss")
		check(arena.run.phase == arena.RunState.Phase.WON and arena.waves.number == 10, "Finite run must stop at wave-ten victory")
		check(arena.records.data.wins == 1 and arena.records.data.runs == 1, "Victory reward must record exactly once")
		var loaded = arena.ArenaRecords.new(arena.records.path)
		loaded.load_records()
		check(loaded.data.wins == 1, "Victory count must survive reload")
		check(arena.hostile_projectiles.items.is_empty() and arena.projectiles.items.is_empty(), "Victory must clear combat projectiles")
		var health: int = arena.run.health
		var elapsed: float = arena.run.elapsed
		arena._take_player_damage(1000)
		arena._physics_process(1.0)
		arena._on_run_won()
		check(arena.run.health == health and arena.run.elapsed == elapsed and arena.records.data.wins == 1, "Victory must block later damage/time and duplicate result delivery")
		arena._set_paused(true)
		check(arena.run.phase == arena.RunState.Phase.WON, "Victory must remain terminal when pausing")
		arena._reset_run()
		check(arena.waves.number == 1 and not arena.waves.finished and arena.run.health == 100 and arena.upgrades.stacks.is_empty(), "Retry must reset finite run")
		arena.run.health = 1
		arena.player.hurt_cooldown = 0.0
		arena._take_player_damage()
		arena.waves.number = 10
		arena.waves.remaining = 0
		arena.enemies.clear()
		arena._on_run_won()
		check(arena.run.phase == arena.RunState.Phase.DEAD and arena.records.data.wins == 1, "Late boss result must not replace death with victory")
		for path in [arena.preferences.path, arena.records.path]:
			for suffix in ["", ".bak", ".tmp"]:
				DirAccess.remove_absolute(path + suffix)
		arena.free()
		await create_timer(0.35).timeout
	remove_meta("finite_run")
	root.remove_meta("finite_run")
	print("Finite run checks complete: %d failures" % failures)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(1 if failures else 0)
