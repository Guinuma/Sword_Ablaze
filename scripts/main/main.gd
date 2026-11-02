extends Node2D
## First combat prototype. Placeholder graphics use logical pixel coordinates.

const RunState = preload("res://scripts/run/run_state.gd")
var run = RunState.new()

const WaveDirector = preload("res://scripts/run/wave_director.gd")
var waves = WaveDirector.new()

const ArenaHud = preload("res://scripts/ui/arena_hud.gd")
const ExileVisual = preload("res://scripts/player/exile_visual.gd")
const PlayerState = preload("res://scripts/player/player_state.gd")
var player = PlayerState.new()
var player_visual: Node2D
var overlay: Node2D

const ARENA := Rect2(24, 64, 592, 272)
const ProjectileSystem = preload("res://scripts/combat/projectile_system.gd")
var projectiles = ProjectileSystem.new()
const EnemySystem = preload("res://scripts/enemies/enemy_system.gd")
var enemies = EnemySystem.new()
var particles: Array[Dictionary] = []
var hud_view: CanvasLayer
var random := RandomNumberGenerator.new()


func _ready() -> void:
	player.shot.connect(projectiles.fire)
	projectiles.impacted.connect(_on_projectile_impact)
	projectiles.defeated.connect(_on_projectile_defeat)
	waves.wave_started.connect(run.start_combat)
	waves.spawn_requested.connect(_spawn_enemy)
	waves.wave_cleared.connect(_on_wave_cleared)
	random.randomize()
	hud_view = ArenaHud.new()
	add_child(hud_view)
	player_visual = ExileVisual.new()
	player_visual.z_index = 1
	add_child(player_visual)
	overlay = Node2D.new()
	overlay.z_index = 2
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	player_visual.present(player.player_position, player.aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and not (run.phase == RunState.Phase.DEAD):
		_set_paused(true)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_sandbox"):
		_reset_run()
	if Input.is_action_just_pressed("pause_run") and not (run.phase == RunState.Phase.DEAD):
		_set_paused(not (run.phase == RunState.Phase.PAUSED))
	if not Input.is_action_pressed("fire"):
		player.fire_requires_release = false
	if (run.phase == RunState.Phase.DEAD) or (run.phase == RunState.Phase.PAUSED):
		return
	_update_effects(delta)
	run.advance(delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.advance(delta, movement, get_global_mouse_position(), Input.is_action_just_pressed("dash"), Input.is_action_pressed("fire"), ARENA)
	_update_waves(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_contact()
	player_visual.present(player.player_position, player.aim, player.dash_direction if player.dash_time > 0.0 else movement, delta, player.dash_time > 0.0, player.hurt_cooldown > 0.0, player.muzzle_time > 0.0)
	_update_hud()
	queue_redraw()


func _set_paused(value: bool) -> void:
	run.set_paused(value)
	# Require a fresh trigger after any pause, including focus loss.
	player.fire_requires_release = true
	_update_hud()
	queue_redraw()


func _burst(point: Vector2, color: Color, count: int) -> void:
	for index in range(count):
		if particles.size() >= 160:
			break
		var direction := Vector2.RIGHT.rotated(random.randf_range(0.0, TAU))
		particles.append({"position": point, "velocity": direction * random.randf_range(30.0, 85.0), "life": 0.3, "color": color})


func _update_effects(delta: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		particles[index]["life"] -= delta
		if particles[index]["life"] <= 0.0:
			particles.remove_at(index)
		else:
			particles[index]["position"] += particles[index]["velocity"] * delta


func _try_dash(movement: Vector2) -> void:
	if run.is_active():
		player.try_dash(movement)


func _update_waves(delta: float) -> void:
	waves.advance(delta, enemies.items.size())


func _on_wave_cleared() -> void:
	projectiles.clear()
	run.start_intermission()



func _spawn_enemy() -> void:
	enemies.spawn(player.player_position, ARENA, random)


func _update_enemies(delta: float) -> void:
	enemies.advance(delta, player.player_position, waves.number, ARENA)


func _update_bullets(delta: float) -> void:
	projectiles.advance(delta, enemies.items, ARENA)


func _on_projectile_impact(point: Vector2) -> void:
	_burst(point, Color("ffb454"), 5)


func _on_projectile_defeat(point: Vector2) -> void:
	_burst(point, Color("e76170"), 10)
	run.record_kill()


func _check_contact() -> void:
	if player.hurt_cooldown > 0.0 or player.dash_time > 0.0 or (run.phase == RunState.Phase.DEAD):
		return
	if enemies.touches(player.player_position):
		run.take_damage()
		_burst(player.player_position, Color("65dfc1"), 10)
		player.hurt_cooldown = player.CONTACT_COOLDOWN


func _reset_run() -> void:
	player.reset()
	projectiles.clear()
	enemies.clear()
	run.reset()
	particles.clear()
	waves.reset()
	player_visual.reset_pose()
	player_visual.present(player.player_position, player.aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	if is_instance_valid(overlay):
		overlay.queue_redraw()
	hud_view.present(run.health, run.MAX_HEALTH, run.kills, run.elapsed, waves.number, waves.remaining + enemies.items.size(), waves.break_time, player.dash_cooldown, (run.phase == RunState.Phase.DEAD), (run.phase == RunState.Phase.PAUSED))


func _draw() -> void:
	draw_rect(ARENA, Color("151c2c"))
	for x in range(24, 617, 16):
		draw_line(Vector2(x, 64), Vector2(x, 336), Color("1d2638"))
	for y in range(64, 337, 16):
		draw_line(Vector2(24, y), Vector2(616, y), Color("1d2638"))
	draw_rect(ARENA, Color("61758b"), false, 1.0)
	for enemy in enemies.items:
		var point: Vector2 = Vector2(enemy["position"]).round()
		var color := Color("fff0b0") if enemy["flash"] > 0.0 else Color("e76170")
		draw_rect(Rect2(point - Vector2(8, 8), Vector2(16, 16)), color)
		draw_rect(Rect2(point + Vector2(-8, -12), Vector2(8 * enemy["health"], 2)), Color("ffb454"))
	if player.dash_time > 0.0:
		draw_line(player.player_position - player.dash_direction * 26.0, player.player_position, Color("388fba"), 10.0)
	if player.muzzle_time > 0.0:
		draw_circle((player.player_position + player.aim * 17.0).round(), 4.0, Color("fff0b0"))
	for particle in particles:
		var tint: Color = particle["color"]
		tint.a = clampf(particle["life"] / 0.3, 0.0, 1.0)
		draw_rect(Rect2(Vector2(particle["position"]).round(), Vector2(2, 2)), tint)
	for bullet in projectiles.items:
		draw_rect(Rect2(Vector2(bullet["position"]).round() - Vector2(2, 2), Vector2(4, 4)), Color("ffb454"))


func _draw_overlay() -> void:
	if (run.phase == RunState.Phase.DEAD) or (run.phase == RunState.Phase.PAUSED):
		overlay.draw_rect(ARENA, Color(0.02, 0.02, 0.04, 0.86))
