extends SceneTree
## Run with: godot --headless --path . --script tests/combat_smoke.gd
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error(description)
		failures += 1

func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://combat_smoke_preferences.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.preferences.path + suffix)
	arena.records = arena.ArenaRecords.new("user://combat_smoke_records.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.records.path + suffix)
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.enemies.items.append({"position": Vector2(150, 200), "health": 2, "flash": 0.0})
	arena.projectiles.items.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.3)
	check(arena.enemies.items[0]["health"] == 1, "Swept bullet must hit enemy even across a long frame")
	check(arena.projectiles.items.is_empty(), "A bullet must be consumed by one hit")
	arena.projectiles.items.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.3)
	check(arena.enemies.items.is_empty() and arena.run.kills == 1, "Second hit must kill and count once")
	arena.enemies.items.append({"position": arena.player.player_position, "health": 2, "flash": 0.0})
	arena.enemies.items.append({"position": arena.player.player_position, "health": 2, "flash": 0.0})
	arena._check_contact()
	arena._check_contact()
	check(arena.run.health == 4, "Overlapping enemies must respect contact invulnerability")
	for index in range(4):
		arena.player.hurt_cooldown = 0.0
		arena._check_contact()
	check(arena.run.health == 0 and (arena.run.phase == arena.RunState.Phase.DEAD), "Contact damage must trigger death at zero HP")
	var before: Vector2 = arena.player.player_position
	var time_before: float = arena.run.elapsed
	arena._physics_process(1.0)
	check(arena.player.player_position == before and arena.run.elapsed == time_before, "Death must freeze the simulation")
	arena._reset_run()
	check(arena.run.health == 5 and not (arena.run.phase == arena.RunState.Phase.DEAD), "Restart must restore health and alive state")
	check(arena.enemies.items.is_empty() and arena.projectiles.items.is_empty() and arena.run.kills == 0, "Restart must clear combat state")
	for index in range(100):
		arena._spawn_enemy()
		var point: Vector2 = arena.enemies.items.back()["position"]
		check(arena.ARENA.has_point(point) and point.distance_to(arena.player.player_position) > 100, "Spawns must be inside arena and away from player")
	arena._reset_run()
	arena.projectiles.items.append({"position": Vector2(610, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(1.0)
	check(arena.projectiles.items.is_empty(), "Offscreen bullets must be removed")
	arena.waves.spawn_cooldown = 0.0
	arena._physics_process(0.016)
	check(arena.enemies.items.size() == 1, "The run must spawn enemies automatically")
	var distance_before: float = arena.enemies.items[0]["position"].distance_to(arena.player.player_position)
	arena._update_enemies(0.1)
	check(arena.enemies.items[0]["position"].distance_to(arena.player.player_position) == distance_before, "Spawn warning must hold enemy stationary")
	arena._update_enemies(0.7)
	arena._update_enemies(0.1)
	check(arena.enemies.items[0]["position"].distance_to(arena.player.player_position) < distance_before, "Enemies must pursue player")
	arena._reset_run()
	arena.enemies.items.append({"position": Vector2(180, 200), "health": 2, "flash": 0.0})
	arena.enemies.items.append({"position": Vector2(140, 200), "health": 2, "flash": 0.0})
	arena.projectiles.items.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.4)
	check(arena.enemies.items[0]["health"] == 2 and arena.enemies.items[1]["health"] == 1, "A bullet must hit only the nearest enemy")
	arena._reset_run()
	for index in range(arena.waves.settings.max_enemies):
		arena._spawn_enemy()
	arena.waves.spawn_cooldown = 0.0
	arena._physics_process(0.016)
	check(arena.enemies.items.size() == arena.waves.settings.max_enemies, "Automatic spawning must respect enemy cap")
	arena._reset_run()
	check(arena.run.elapsed == 0.0 and arena.player.hurt_cooldown == 0.0 and arena.player.fire_cooldown == 0.0 and arena.waves.spawn_cooldown == 0.8, "Restart must reset timers")
	arena.run.health = 3
	arena.waves.remaining = 0
	arena._update_waves(0.016)
	check(arena.waves.break_time == arena.waves.settings.break_duration and arena.run.health == 4, "Cleared wave must start break and heal once")
	arena._update_waves(1.0)
	check(arena.waves.number == 1 and arena.run.health == 4, "Break must delay next wave and not repeat healing")
	arena._update_waves(2.0)
	check(arena.waves.number == 2 and arena.waves.remaining == 7, "Next wave must increase enemy budget")
	arena._try_dash(Vector2.UP)
	check(arena.player.dash_direction == Vector2.UP and arena.player.dash_time > 0.0, "Dash must follow movement")
	arena.enemies.items.append({"position": arena.player.player_position, "health": 2, "flash": 0.0})
	arena._check_contact()
	check(arena.run.health == 4, "Dash must protect against contact")
	arena._try_dash(Vector2.DOWN)
	check(arena.player.dash_direction == Vector2.UP, "Cooldown must prevent a second dash")
	arena._physics_process(0.2)
	check(arena.ARENA.has_point(arena.player.player_position) and arena.player.dash_time == 0.0, "Dash must end and stay inside arena")
	arena._reset_run()
	check(arena.waves.number == 1 and arena.waves.remaining == 5 and arena.waves.break_time == 0.0 and arena.player.dash_cooldown == 0.0, "Restart must clear wave and dash state")
	arena._try_dash(Vector2.ZERO)
	check(arena.player.dash_direction == arena.player.aim, "Stationary dash must follow aim")
	arena._reset_run()
	arena.enemies.items.append({"position": Vector2(150, 200), "health": 2, "flash": 0.0})
	arena.projectiles.items.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.2)
	arena._update_enemies(0.05)
	check(arena.enemies.items[0]["position"].x > 150.0 and arena.particles.size() > 0, "Hit must produce knockback and particles")
	arena._update_effects(1.0)
	check(arena.particles.is_empty(), "Expired particles must be removed")
	arena.enemies.items.clear()
	for index in range(2):
		arena.enemies.items.append({"position": Vector2(200, 200), "health": 2, "flash": 0.0})
	arena._update_enemies(0.0)
	check(arena.enemies.items[0]["position"].distance_to(arena.enemies.items[1]["position"]) >= 17.9, "Coincident enemies must separate")
	arena._burst(Vector2.ZERO, Color.WHITE, 200)
	check(arena.particles.size() == 160, "Particle count must stay bounded")
	arena._set_paused(true)
	var paused_position: Vector2 = arena.enemies.items[0]["position"]
	arena._physics_process(1.0)
	check(arena.run.elapsed == 0.0 and arena.enemies.items[0]["position"] == paused_position and arena.particles.size() == 160, "Pause must freeze timers, enemies and effects")
	arena._try_dash(Vector2.UP)
	check(arena.player.dash_time == 0.0, "Pause must prevent dash")
	arena._set_paused(false)
	arena._physics_process(0.01)
	check(arena.run.elapsed > 0.0, "Resume must continue simulation")
	arena._set_paused(true)
	arena._reset_run()
	check(not (arena.run.phase == arena.RunState.Phase.PAUSED) and arena.particles.is_empty() and arena.player.muzzle_time == 0.0, "Restart must clear pause and effects")
	# Project bindings must survive scene creation without being overwritten.
	var expected_keys := {"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "move_up": KEY_UP, "move_down": KEY_DOWN, "pause_run": KEY_ESCAPE, "dash": KEY_SHIFT}
	for action in expected_keys:
		var event := InputEventKey.new()
		event.physical_keycode = expected_keys[action]
		check(InputMap.action_has_event(action, event), "Project must define binding for " + action)
	Input.action_press("fire")
	arena._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus_time: float = arena.run.elapsed
	arena._physics_process(0.1)
	check((arena.run.phase == arena.RunState.Phase.PAUSED) and arena.run.elapsed == focus_time, "Focus loss must pause and freeze combat")
	arena._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check((arena.run.phase == arena.RunState.Phase.PAUSED), "Focus gain must wait for explicit resume")
	arena._set_paused(false)
	arena._physics_process(0.01)
	check(arena.projectiles.items.is_empty(), "Held fire must not shoot when resuming")
	Input.action_release("fire")
	arena._physics_process(0.01)
	Input.action_press("fire")
	arena._physics_process(0.01)
	check(arena.projectiles.items.size() == 1, "Fresh fire press must shoot after resume")
	arena._reset_run()
	arena._physics_process(0.01)
	check(arena.projectiles.items.is_empty(), "Held fire must not shoot when restarting")
	Input.action_release("fire")
	arena._physics_process(0.01)
	arena._set_paused(true)
	check(arena.hud_view.status.visible and arena.hud_view.status.text.begins_with("PAUSED"), "HUD must present pause state")
	arena._reset_run()
	check(not arena.hud_view.status.visible and arena.hud_view.stats.text.contains("HP 5/5"), "HUD must refresh after restart")
	arena.run.health = 1
	arena.enemies.items.append({"position": arena.player.player_position, "health": 2, "flash": 0.0})
	arena._check_contact()
	arena._update_hud()
	check(arena.hud_view.status.visible and arena.hud_view.status.text.begins_with("YOU FELL") and not arena.hud_view.wave_status.visible, "HUD must present death and hide wave prompt")
	arena._reset_run()
	arena.run.health = 3
	arena.waves.remaining = 0
	arena.projectiles.items.append({"position": Vector2(100, 100), "direction": Vector2.RIGHT})
	arena._update_waves(0.01)
	check(arena.projectiles.items.is_empty(), "Wave clear event must remove projectiles")
	arena._set_paused(true)
	arena._physics_process(10.0)
	check(arena.waves.break_time == 3.0 and arena.run.health == 4, "Pause must freeze intermission without duplicate healing")
	arena._set_paused(false)
	arena._update_waves(3.0)
	check(arena.waves.number == 2 and arena.enemies.items.is_empty(), "Intermission must end before spawning next wave")
	arena._update_waves(0.3)
	check(arena.enemies.items.size() == 1 and arena.waves.remaining == 6, "Spawn event must create exactly one enemy and consume budget")
	arena._reset_run()
	for round_index in range(30):
		arena.waves.remaining = 0
		arena._update_waves(0.01)
		arena._update_waves(3.0)
	check(arena.waves.number == 31 and arena.waves.remaining == 40 and arena.run.health == arena.run.MAX_HEALTH, "Long runs must cap budget and healing")
	arena._update_waves(0.3)
	check(is_equal_approx(arena.waves.spawn_cooldown, 0.4), "Advanced waves must respect minimum spawn interval")
	arena._reset_run()
	check(arena.waves.number == 1 and arena.waves.remaining == 5 and arena.waves.spawn_cooldown == 0.8, "Director must reset after advanced rounds")
	var lifecycle = arena.RunState.new()
	var events := {"damage": 0, "kills": 0}
	lifecycle.damaged.connect(func(_hp): events["damage"] += 1)
	lifecycle.enemy_defeated.connect(func(_total): events["kills"] += 1)
	lifecycle.start_intermission()
	lifecycle.set_paused(true)
	lifecycle.set_paused(true)
	lifecycle.advance(10.0)
	lifecycle.take_damage()
	check(lifecycle.elapsed == 0.0 and lifecycle.health == 5, "Paused lifecycle must reject time and damage")
	lifecycle.set_paused(false)
	check(lifecycle.phase == lifecycle.Phase.INTERMISSION, "Repeated pause must preserve intermission resume state")
	lifecycle.start_combat(2)
	lifecycle.record_kill()
	for hit in range(8):
		lifecycle.take_damage()
	lifecycle.set_paused(true)
	lifecycle.set_paused(false)
	lifecycle.start_combat(3)
	lifecycle.start_intermission()
	lifecycle.record_kill()
	check(lifecycle.phase == lifecycle.Phase.DEAD and lifecycle.health == 0, "Death must reject pause, wave transitions and extra damage")
	check(events["damage"] == 5 and events["kills"] == 1, "Lifecycle events must count actual damage and kills only")
	lifecycle.reset()
	check(lifecycle.phase == lifecycle.Phase.COMBAT and lifecycle.health == 5 and lifecycle.kills == 0, "Reset must restore lifecycle from death")
	# Exercise player simulation without scene input or rendering.
	for rate in [30, 60, 144]:
		var simulation = arena.PlayerState.new()
		var start: Vector2 = simulation.player_position
		for frame in range(rate):
			simulation.advance(1.0 / rate, Vector2.RIGHT, Vector2(600, 200), false, false, arena.ARENA)
		check(absf(simulation.player_position.x - start.x - 120.0) < 0.01, "Movement distance must be stable at %d Hz" % rate)
		simulation.reset()
		start = simulation.player_position
		simulation.try_dash(Vector2.RIGHT)
		for frame in range(rate):
			simulation.advance(1.0 / rate, Vector2.ZERO, Vector2(600, 200), false, false, arena.ARENA)
		check(absf(simulation.player_position.x - start.x - 53.2) < 0.01, "Dash distance must be stable at %d Hz" % rate)
	var isolated = arena.PlayerState.new()
	var shots := {"count": 0}
	isolated.shot.connect(func(_origin, _direction): shots["count"] += 1)
	isolated.reset()
	isolated.advance(0.01, Vector2.ZERO, Vector2(600, 200), false, true, arena.ARENA)
	check(shots["count"] == 0, "Reset must require releasing fire in standalone player simulation")
	isolated.advance(0.01, Vector2.ZERO, Vector2(600, 200), false, false, arena.ARENA)
	isolated.advance(0.01, Vector2.ZERO, Vector2(600, 200), false, true, arena.ARENA)
	check(shots["count"] == 1, "Standalone player must resume firing after release")
	# Alternative tuning must affect simulation without changing shared defaults.
	var custom_shots = arena.ProjectileSystem.new()
	custom_shots.weapon = custom_shots.weapon.duplicate()
	custom_shots.weapon.damage = 3
	custom_shots.weapon.projectile_speed = 100.0
	var targets: Array[Dictionary] = [{"position": Vector2(150, 200), "health": 3, "flash": 0.0}]
	custom_shots.fire(Vector2(100, 200), Vector2.RIGHT)
	custom_shots.advance(0.1, targets, arena.ARENA)
	check(targets.size() == 1 and custom_shots.items[0]["position"] == Vector2(110, 200), "Projectile speed must come from weapon resource")
	custom_shots.advance(0.5, targets, arena.ARENA)
	check(targets.is_empty() and arena.projectiles.weapon.damage == 1, "Custom weapon damage must apply without mutating default resource")
	var custom_waves = arena.WaveDirector.new()
	custom_waves.settings = custom_waves.settings.duplicate()
	custom_waves.settings.initial_budget = 2
	custom_waves.settings.budget_growth = 3
	custom_waves.settings.max_budget = 4
	custom_waves.reset()
	check(custom_waves.remaining == 2, "Wave reset must use configured initial budget")
	custom_waves.remaining = 0
	custom_waves.advance(0.01, 0)
	custom_waves.advance(custom_waves.settings.break_duration, 0)
	check(custom_waves.remaining == 4, "Wave growth must obey configured budget cap")
	arena._reset_run()
	arena._spawn_enemy()
	var warning_point: Vector2 = arena.enemies.items[0]["position"]
	arena.player.player_position = warning_point
	arena._update_enemies(1.0)
	arena._check_contact()
	check(arena.run.health == 5 and arena.enemies.items[0]["spawn_time"] > 0.0, "Warning must postpone activation when player enters spawn point")
	arena.projectiles.fire(warning_point - Vector2(20, 0), Vector2.RIGHT)
	arena._update_bullets(0.1)
	check(arena.enemies.items[0]["health"] == 2, "Pending spawn must not receive projectile damage")
	arena._set_paused(true)
	var warning_time: float = arena.enemies.items[0]["spawn_time"]
	arena._physics_process(1.0)
	check(arena.enemies.items[0]["spawn_time"] == warning_time, "Pause must freeze spawn warning")
	arena._set_paused(false)
	arena.player.player_position = arena.ARENA.get_center()
	arena._update_enemies(0.1)
	check(arena.enemies.items[0]["spawn_time"] == 0.0, "Spawn must activate after player leaves warning")
	arena._reset_run()
	check(arena.enemies.items.is_empty(), "Reset must clear pending spawns")
	# Ranged attacks must announce, lock aim, and respect the shared damage rules.
	arena._reset_run()
	arena._spawn_enemy(&"ranged")
	var ranged: Dictionary = arena.enemies.items[0]
	ranged["position"] = Vector2(160, 200)
	ranged["spawn_time"] = 0.0
	ranged["attack_cooldown"] = 0.0
	arena._update_enemies(0.01)
	check(ranged["windup"] > 0.0 and arena.hostile_projectiles.items.is_empty(), "Ranged attack must warn before firing")
	var locked_direction: Vector2 = ranged["shot_direction"]
	arena.player.player_position = Vector2(320, 260)
	arena._update_enemies(0.2)
	check(ranged["shot_direction"] == locked_direction and arena.hostile_projectiles.items.is_empty(), "Warning must lock aim so player can dodge")
	arena._set_paused(true)
	var attack_time: float = ranged["windup"]
	arena._physics_process(1.0)
	check(ranged["windup"] == attack_time, "Pause must freeze ranged windup")
	arena._set_paused(false)
	arena._update_enemies(0.65)
	check(arena.hostile_projectiles.items.size() == 1 and arena.hostile_projectiles.items[0]["direction"] == locked_direction, "Completed warning must fire exactly one locked shot")
	arena._update_enemies(0.1)
	check(arena.hostile_projectiles.items.size() == 1, "Cooldown must prevent immediate repeated attacks")
	arena.hostile_projectiles.clear()
	arena.player.player_position = Vector2(320, 200)
	arena.hostile_projectiles.fire(Vector2(200, 200), Vector2.RIGHT, 360.0)
	arena.hostile_projectiles.advance(0.5, arena.player.player_position, arena.ARENA)
	check(arena.run.health == 4 and arena.hostile_projectiles.items.is_empty(), "Swept hostile shot must damage player and be consumed")
	arena.hostile_projectiles.fire(Vector2(300, 200), Vector2.RIGHT, 360.0)
	arena.hostile_projectiles.advance(0.1, arena.player.player_position, arena.ARENA)
	check(arena.run.health == 4, "Hostile shots must share contact invulnerability cooldown")
	arena.player.hurt_cooldown = 0.0
	arena._try_dash(Vector2.RIGHT)
	arena.hostile_projectiles.fire(Vector2(300, 200), Vector2.RIGHT, 360.0)
	arena.hostile_projectiles.advance(0.1, arena.player.player_position, arena.ARENA)
	check(arena.run.health == 4, "Dash must protect against hostile projectiles")
	for index in range(100):
		arena.hostile_projectiles.fire(Vector2(30, 100), Vector2.RIGHT, 130.0)
	check(arena.hostile_projectiles.items.size() == 64, "Hostile projectile count must be bounded")
	arena._on_wave_cleared()
	check(arena.hostile_projectiles.items.is_empty(), "Wave clear must remove hostile shots")
	arena.hostile_projectiles.fire(Vector2(30, 100), Vector2.RIGHT, 130.0)
	arena._reset_run()
	check(arena.hostile_projectiles.items.is_empty(), "Reset must remove hostile shots")
	var composition = arena.WaveDirector.new()
	var spawned: Array[StringName] = []
	composition.spawn_requested.connect(func(kind): spawned.append(kind))
	for index in range(5):
		composition.advance(2.0, 0)
	check(not spawned.has(&"ranged"), "Opening wave must contain only chasers")
	composition.number = 3
	composition.remaining = 9
	composition.spawn_count = 0
	spawned.clear()
	for index in range(9):
		composition.advance(2.0, 0)
	check(spawned.count(&"ranged") == 3 and spawned.count(&"chaser") == 6, "Wave three must introduce one ranged enemy per three spawns")
	arena._reset_run()
	arena._set_paused(true)
	check(arena.hud_view.menu.visible and arena.hud_view.resume_button.has_focus(), "Opening pause must focus Resume")
	Input.action_press("fire")
	arena.hud_view.resume_button.pressed.emit()
	arena._physics_process(0.01)
	check(arena.run.is_active() and not arena.hud_view.menu.visible and arena.projectiles.items.is_empty(), "Resume button must close menu and block held fire")
	arena._set_paused(true)
	arena.hud_view.restart_button.pressed.emit()
	arena._physics_process(0.01)
	check(arena.run.health == 5 and not arena.hud_view.menu.visible and arena.projectiles.items.is_empty(), "Restart button must reset run and block held fire")
	Input.action_release("fire")
	arena.run.health = 1
	arena.run.elapsed = 125.0
	arena.waves.number = 4
	arena.player.hurt_cooldown = 0.0
	arena._take_player_damage()
	arena._update_hud()
	check(arena.hud_view.status.text.contains("Wave 4") and arena.hud_view.status.text.contains("2:05"), "Defeat summary must show wave and formatted duration")
	check(not arena.hud_view.resume_button.visible and arena.hud_view.restart_button.has_focus(), "Defeat menu must focus Restart and hide Resume")
	arena.hud_view.restart_button.pressed.emit()
	check(arena.run.is_active() and arena.run.elapsed == 0.0, "Defeat restart must begin a fresh run")
	arena._reset_run()
	arena.enemies.items.append({"position": Vector2(150, 200), "health": 2, "flash": 0.0})
	arena.projectiles.fire(Vector2(150, 200), Vector2.RIGHT)
	arena._update_bullets(0.01)
	check(arena.enemies.items[0]["health"] == 1 and arena.projectiles.items.is_empty(), "Shot originating inside a hitbox must hit immediately")
	for index in range(200):
		arena.projectiles.fire(Vector2(40, 100), Vector2.ZERO)
	check(arena.projectiles.items.size() == 128, "Player projectile count must remain bounded")
	arena.enemies.clear()
	arena.projectiles.advance(6.0, arena.enemies.items, arena.ARENA)
	check(arena.projectiles.items.is_empty(), "Stationary player shots must expire")
	arena.hostile_projectiles.fire(Vector2(40, 100), Vector2.RIGHT, 100.0)
	arena.hostile_projectiles.items[0]["life"] = 0.1
	arena.player.player_position = Vector2(200, 100)
	arena.hostile_projectiles.advance(2.0, arena.player.player_position, arena.ARENA)
	check(arena.run.health == 5 and arena.hostile_projectiles.items.is_empty(), "Expired hostile shot must not hit beyond its remaining lifetime")
	var storage = arena.ArenaRecords.new("user://record_storage_test.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(storage.path + suffix)
	storage.load_records()
	check(storage.data["runs"] == 0, "Missing record file must load defaults")
	check(storage.record(3, 12, 80.0) == OK, "First record save must succeed")
	check(storage.record(2, 7, 60.0) == OK, "Record replacement must succeed")
	var reloaded = arena.ArenaRecords.new(storage.path)
	reloaded.load_records()
	check(reloaded.data["runs"] == 2 and reloaded.data["best_wave"] == 3 and reloaded.data["best_kills"] == 12, "Records must survive reload and preserve maxima")
	var broken := FileAccess.open(storage.path, FileAccess.WRITE)
	broken.store_string("broken save")
	broken.close()
	reloaded.load_records()
	check(reloaded.data["runs"] == 1 and reloaded.data["best_wave"] == 3, "Corrupt primary must recover previous backup")
	check(reloaded.record(4, 20, 100.0) == OK, "Recovered records must save successfully")
	arena._reset_run()
	var prior_runs: int = arena.records.data["runs"]
	arena.run.health = 1
	arena._take_player_damage()
	arena._on_run_phase_changed(arena.RunState.Phase.DEAD)
	check(arena.records.data["runs"] == prior_runs + 1, "Repeated death notifications must record a run only once")
	var future := FileAccess.open(storage.path, FileAccess.WRITE)
	future.store_string('{"version": 99, "runs": 900}')
	future.close()
	reloaded.load_records()
	check(reloaded.record(1, 1, 1.0) == ERR_UNAVAILABLE, "Newer record schema must not be overwritten")
	check(FileAccess.get_file_as_string(storage.path).contains('"version": 99'), "Unsupported record file must remain intact")
	for store in [storage, arena.records]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(store.path + suffix)
	arena._reset_run()
	arena.waves.number = 3
	arena.waves.remaining = 0
	arena._update_waves(0.01)
	arena._update_hud()
	check(arena.run.phase == arena.RunState.Phase.UPGRADE and arena.upgrades.offered.size() == 3, "Third wave clear must offer three temporary upgrades")
	var choice_time: float = arena.run.elapsed
	var choice_break: float = arena.waves.break_time
	arena._physics_process(10.0)
	check(arena.run.elapsed == choice_time and arena.waves.break_time == choice_break, "Upgrade choice must freeze run and wave countdown")
	arena._choose_upgrade(&"invalid")
	check(arena.run.phase == arena.RunState.Phase.UPGRADE, "Invalid upgrade must not advance the run")
	arena._set_paused(true)
	arena._set_paused(false)
	check(arena.run.phase == arena.RunState.Phase.UPGRADE and arena.hud_view.choice_buttons[0].has_focus(), "Pause must return to upgrade choice with keyboard focus")
	var selected: StringName = arena.upgrades.offered[0].id
	Input.action_press("fire")
	arena.hud_view.choice_buttons[0].pressed.emit()
	arena._choose_upgrade(selected)
	check(arena.upgrades.stacks[selected] == 1 and arena.run.phase == arena.RunState.Phase.INTERMISSION, "Upgrade must apply once and return to intermission")
	arena._physics_process(0.01)
	check(arena.projectiles.items.is_empty(), "Selecting an upgrade must block held fire")
	Input.action_release("fire")
	arena.upgrades.stacks = {&"swift": 2, &"rapid": 2, &"heavy": 1, &"force": 1, &"dash": 1}
	arena._apply_upgrades()
	check(absf(arena.player.move_speed - 145.2) < 0.01 and arena.projectiles.weapon.damage == 2, "Multiple upgrade types must combine from base values")
	var upgraded_speed: float = arena.player.move_speed
	arena._apply_upgrades()
	check(arena.player.move_speed == upgraded_speed and arena.projectiles.weapon.damage == 2, "Reapplying upgrades must not compound already modified stats")
	check(load("res://resources/default_weapon.tres").damage == 1, "Upgrades must leave shared default resources untouched")
	arena._reset_run()
	check(arena.upgrades.stacks.is_empty() and arena.player.move_speed == 120.0 and arena.projectiles.weapon.damage == 1, "Restart must remove all temporary upgrades")
	for definition in arena.upgrades.definitions:
		arena.upgrades.stacks[definition.id] = definition.max_stacks
	check(arena.upgrades.offer(arena.random).is_empty(), "Exhausted upgrade pool must return no choices")
	arena.waves.number = 3
	arena._on_wave_cleared()
	check(arena.run.phase == arena.RunState.Phase.INTERMISSION, "Exhausted pool must continue without trapping the run in a menu")
	arena._reset_run()
	arena._reset_run()
	arena._set_paused(true)
	arena.hud_view.flashes_toggle.button_pressed = true
	arena.hud_view.motion_toggle.button_pressed = true
	check(arena.preferences.reduced_flashes and arena.preferences.reduced_motion and arena.player_visual.reduced_motion, "Pause toggles must apply visual preferences")
	var loaded_preferences = arena.Preferences.new(arena.preferences.path)
	loaded_preferences.load_preferences()
	check(loaded_preferences.reduced_flashes and loaded_preferences.reduced_motion, "Visual preferences must survive reload")
	arena._burst(Vector2.ZERO, Color.WHITE, 10)
	check(arena.particles.is_empty(), "Reduced motion must suppress decorative particles")
	arena._reset_run()
	check(arena.preferences.reduced_motion and arena.player.move_speed == 120.0 and arena.projectiles.weapon.damage == 1, "Visual preferences must survive restart without changing combat stats")
	var invalid_preferences := FileAccess.open(arena.preferences.path, FileAccess.WRITE)
	invalid_preferences.store_string('{"version":1,"reduced_flashes":"yes","reduced_motion":false}')
	invalid_preferences.close()
	loaded_preferences.load_preferences()
	check(loaded_preferences.reduced_flashes and not loaded_preferences.reduced_motion, "Invalid preference types must recover backup values")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(arena.preferences.path + suffix)
	print("Combat checks complete: %d failures" % failures)
	arena.free()
	quit(0 if failures == 0 else 1)
