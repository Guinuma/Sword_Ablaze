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
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.enemies.append({"position": Vector2(150, 200), "health": 2, "flash": 0.0})
	arena.bullets.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.3)
	check(arena.enemies[0]["health"] == 1, "Swept bullet must hit enemy even across a long frame")
	check(arena.bullets.is_empty(), "A bullet must be consumed by one hit")
	arena.bullets.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.3)
	check(arena.enemies.is_empty() and arena.kills == 1, "Second hit must kill and count once")
	arena.enemies.append({"position": arena.player_position, "health": 2, "flash": 0.0})
	arena.enemies.append({"position": arena.player_position, "health": 2, "flash": 0.0})
	arena._check_contact()
	arena._check_contact()
	check(arena.health == 4, "Overlapping enemies must respect contact invulnerability")
	for index in range(4):
		arena.hurt_cooldown = 0.0
		arena._check_contact()
	check(arena.health == 0 and arena.game_over, "Contact damage must trigger death at zero HP")
	var before: Vector2 = arena.player_position
	var time_before: float = arena.elapsed
	arena._physics_process(1.0)
	check(arena.player_position == before and arena.elapsed == time_before, "Death must freeze the simulation")
	arena._reset_run()
	check(arena.health == 5 and not arena.game_over, "Restart must restore health and alive state")
	check(arena.enemies.is_empty() and arena.bullets.is_empty() and arena.kills == 0, "Restart must clear combat state")
	for index in range(100):
		arena._spawn_enemy()
		var point: Vector2 = arena.enemies.back()["position"]
		check(arena.ARENA.has_point(point) and point.distance_to(arena.player_position) > 100, "Spawns must be inside arena and away from player")
	arena._reset_run()
	arena.bullets.append({"position": Vector2(610, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(1.0)
	check(arena.bullets.is_empty(), "Offscreen bullets must be removed")
	arena.spawn_cooldown = 0.0
	arena._physics_process(0.016)
	check(arena.enemies.size() == 1, "The run must spawn enemies automatically")
	var distance_before: float = arena.enemies[0]["position"].distance_to(arena.player_position)
	arena._update_enemies(0.1)
	check(arena.enemies[0]["position"].distance_to(arena.player_position) < distance_before, "Enemies must pursue player")
	arena._reset_run()
	arena.enemies.append({"position": Vector2(180, 200), "health": 2, "flash": 0.0})
	arena.enemies.append({"position": Vector2(140, 200), "health": 2, "flash": 0.0})
	arena.bullets.append({"position": Vector2(100, 200), "direction": Vector2.RIGHT})
	arena._update_bullets(0.4)
	check(arena.enemies[0]["health"] == 2 and arena.enemies[1]["health"] == 1, "A bullet must hit only the nearest enemy")
	arena._reset_run()
	for index in range(arena.MAX_ENEMIES):
		arena._spawn_enemy()
	arena.spawn_cooldown = 0.0
	arena._physics_process(0.016)
	check(arena.enemies.size() == arena.MAX_ENEMIES, "Automatic spawning must respect enemy cap")
	arena._reset_run()
	check(arena.elapsed == 0.0 and arena.hurt_cooldown == 0.0 and arena.fire_cooldown == 0.0 and arena.spawn_cooldown == 0.8, "Restart must reset timers")
	arena.health = 3
	arena.wave_remaining = 0
	arena._update_waves(0.016)
	check(arena.wave_break == arena.WAVE_BREAK and arena.health == 4, "Cleared wave must start break and heal once")
	arena._update_waves(1.0)
	check(arena.wave == 1 and arena.health == 4, "Break must delay next wave and not repeat healing")
	arena._update_waves(2.0)
	check(arena.wave == 2 and arena.wave_remaining == 7, "Next wave must increase enemy budget")
	arena._try_dash(Vector2.UP)
	check(arena.dash_direction == Vector2.UP and arena.dash_time > 0.0, "Dash must follow movement")
	arena.enemies.append({"position": arena.player_position, "health": 2, "flash": 0.0})
	arena._check_contact()
	check(arena.health == 4, "Dash must protect against contact")
	arena._try_dash(Vector2.DOWN)
	check(arena.dash_direction == Vector2.UP, "Cooldown must prevent a second dash")
	arena._physics_process(0.2)
	check(arena.ARENA.has_point(arena.player_position) and arena.dash_time == 0.0, "Dash must end and stay inside arena")
	arena._reset_run()
	check(arena.wave == 1 and arena.wave_remaining == 5 and arena.wave_break == 0.0 and arena.dash_cooldown == 0.0, "Restart must clear wave and dash state")
	arena._try_dash(Vector2.ZERO)
	check(arena.dash_direction == arena.aim, "Stationary dash must follow aim")
	print("Combat checks complete: %d failures" % failures)
	arena.free()
	quit(0 if failures == 0 else 1)
