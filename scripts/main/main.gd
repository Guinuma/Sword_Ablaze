extends Node2D
## First combat prototype. Placeholder graphics use logical pixel coordinates.

const ArenaHud = preload("res://scripts/ui/arena_hud.gd")
const ExileVisual = preload("res://scripts/player/exile_visual.gd")
var player_visual: Node2D
var overlay: Node2D

const SPEED: float = 120.0
const BULLET_SPEED: float = 360.0
const FIRE_INTERVAL: float = 0.16
const ARENA := Rect2(24, 64, 592, 272)
var player_position := Vector2(320, 200)
var aim := Vector2.RIGHT
var fire_cooldown: float = 0.0
const MAX_HEALTH: int = 5
const ENEMY_HEALTH: int = 2
const ENEMY_SPEED: float = 46.0
const MAX_ENEMIES: int = 18
const SPAWN_INTERVAL: float = 1.6
const CONTACT_COOLDOWN: float = 0.85
const DASH_SPEED: float = 380.0
const DASH_DURATION: float = 0.14
const DASH_COOLDOWN: float = 1.2
const WAVE_BREAK: float = 3.0
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction := Vector2.RIGHT
var wave: int = 1
var wave_remaining: int = 5
var wave_break: float = 0.0
var bullets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var health: int = MAX_HEALTH
var kills: int = 0
var elapsed: float = 0.0
var spawn_cooldown: float = 0.8
var hurt_cooldown: float = 0.0
var paused: bool = false
var fire_requires_release: bool = false
var particles: Array[Dictionary] = []
var muzzle_time: float = 0.0
var game_over: bool = false
var hud_view: CanvasLayer
var random := RandomNumberGenerator.new()


func _ready() -> void:
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
	player_visual.present(player_position, aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and not game_over:
		_set_paused(true)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_sandbox"):
		_reset_run()
	if Input.is_action_just_pressed("pause_run") and not game_over:
		_set_paused(not paused)
	if not Input.is_action_pressed("fire"):
		fire_requires_release = false
	if game_over or paused:
		return
	_update_effects(delta)
	elapsed += delta
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if Input.is_action_just_pressed("dash"):
		_try_dash(movement)
	if dash_time > 0.0:
		player_position += dash_direction * DASH_SPEED * minf(delta, dash_time)
		dash_time = maxf(0.0, dash_time - delta)
	else:
		player_position += movement * SPEED * delta
	player_position = player_position.clamp(ARENA.position + Vector2(8, 8), ARENA.end - Vector2(8, 8))
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length_squared() > 1.0:
		aim = mouse_direction.normalized()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if Input.is_action_pressed("fire") and not fire_requires_release and fire_cooldown <= 0.0:
		bullets.append({"position": player_position + aim * 12.0, "direction": aim})
		fire_cooldown = FIRE_INTERVAL
		muzzle_time = 0.06
	_update_waves(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_contact()
	player_visual.present(player_position, aim, dash_direction if dash_time > 0.0 else movement, delta, dash_time > 0.0, hurt_cooldown > 0.0, muzzle_time > 0.0)
	_update_hud()
	queue_redraw()


func _set_paused(value: bool) -> void:
	paused = value
	# Require a fresh trigger after any pause, including focus loss.
	fire_requires_release = true
	_update_hud()
	queue_redraw()


func _burst(point: Vector2, color: Color, count: int) -> void:
	for index in range(count):
		if particles.size() >= 160:
			break
		var direction := Vector2.RIGHT.rotated(random.randf_range(0.0, TAU))
		particles.append({"position": point, "velocity": direction * random.randf_range(30.0, 85.0), "life": 0.3, "color": color})


func _update_effects(delta: float) -> void:
	muzzle_time = maxf(0.0, muzzle_time - delta)
	for index in range(particles.size() - 1, -1, -1):
		particles[index]["life"] -= delta
		if particles[index]["life"] <= 0.0:
			particles.remove_at(index)
		else:
			particles[index]["position"] += particles[index]["velocity"] * delta


func _try_dash(movement: Vector2) -> void:
	if dash_cooldown > 0.0 or game_over or paused:
		return
	dash_direction = movement.normalized() if movement.length_squared() > 0.0 else aim
	dash_time = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN


func _update_waves(delta: float) -> void:
	if wave_break > 0.0:
		wave_break = maxf(0.0, wave_break - delta)
		if wave_break == 0.0:
			wave += 1
			wave_remaining = mini(5 + (wave - 1) * 2, 40)
			spawn_cooldown = 0.3
		return
	if wave_remaining == 0 and enemies.is_empty():
		wave_break = WAVE_BREAK
		bullets.clear()
		health = mini(health + 1, MAX_HEALTH)
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0 and wave_remaining > 0 and enemies.size() < MAX_ENEMIES:
		_spawn_enemy()
		wave_remaining -= 1
		spawn_cooldown = maxf(0.4, SPAWN_INTERVAL - (wave - 1) * 0.1)


func _spawn_enemy() -> void:
	var point: Vector2
	# Spawn on the opposite half of the perimeter, away from the player.
	if random.randf() < 0.5:
		var x := ARENA.position.x + 10.0 if player_position.x > ARENA.get_center().x else ARENA.end.x - 10.0
		point = Vector2(x, random.randf_range(ARENA.position.y + 10.0, ARENA.end.y - 10.0))
	else:
		var y := ARENA.position.y + 10.0 if player_position.y > ARENA.get_center().y else ARENA.end.y - 10.0
		point = Vector2(random.randf_range(ARENA.position.x + 10.0, ARENA.end.x - 10.0), y)
	enemies.append({"position": point, "health": ENEMY_HEALTH, "flash": 0.0})


func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		var point: Vector2 = enemy["position"]
		enemy["position"] = point.move_toward(player_position, minf(ENEMY_SPEED + (wave - 1) * 3.0, 90.0) * delta)
		var knockback: Vector2 = enemy.get("knockback", Vector2.ZERO)
		enemy["position"] += knockback * delta
		enemy["knockback"] = knockback.move_toward(Vector2.ZERO, 600.0 * delta)
		enemy["flash"] = maxf(0.0, enemy["flash"] - delta)
	# Resolve each pair once; a stable fallback separates coincident centers.
	for first in range(enemies.size()):
		for second in range(first + 1, enemies.size()):
			var offset: Vector2 = enemies[second]["position"] - enemies[first]["position"]
			var distance := offset.length()
			if distance < 18.0:
				var normal := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(first) * 2.4)
				var push := normal * (18.0 - distance) * 0.5
				enemies[first]["position"] -= push
				enemies[second]["position"] += push
	for enemy in enemies:
		enemy["position"] = Vector2(enemy["position"]).clamp(ARENA.position + Vector2(8, 8), ARENA.end - Vector2(8, 8))


func _update_bullets(delta: float) -> void:
	for index in range(bullets.size() - 1, -1, -1):
		var start: Vector2 = bullets[index]["position"]
		var end: Vector2 = start + Vector2(bullets[index]["direction"]) * BULLET_SPEED * delta
		# Segment collision prevents fast bullets from skipping through enemies.
		var target: int = -1
		var nearest: float = INF
		for enemy_index in range(enemies.size()):
			var point: Vector2 = enemies[enemy_index]["position"]
			var hit := Geometry2D.segment_intersects_circle(start, end, point, 10.0)
			if hit >= 0.0 and hit < nearest:
				target = enemy_index
				nearest = hit
		if target >= 0:
			var impact: Vector2 = enemies[target]["position"]
			enemies[target]["knockback"] = Vector2(bullets[index]["direction"]) * 135.0
			_burst(impact, Color("ffb454"), 5)
			enemies[target]["health"] -= 1
			enemies[target]["flash"] = 0.12
			if enemies[target]["health"] <= 0:
				_burst(impact, Color("e76170"), 10)
				enemies.remove_at(target)
				kills += 1
			bullets.remove_at(index)
		elif not ARENA.has_point(end):
			bullets.remove_at(index)
		else:
			bullets[index]["position"] = end


func _check_contact() -> void:
	if hurt_cooldown > 0.0 or dash_time > 0.0 or game_over:
		return
	for enemy in enemies:
		if player_position.distance_to(enemy["position"]) < 15.0:
			health -= 1
			_burst(player_position, Color("65dfc1"), 10)
			hurt_cooldown = CONTACT_COOLDOWN
			if health <= 0:
				game_over = true
			break


func _reset_run() -> void:
	player_position = Vector2(320, 200)
	aim = Vector2.RIGHT
	bullets.clear()
	enemies.clear()
	health = MAX_HEALTH
	kills = 0
	elapsed = 0.0
	spawn_cooldown = 0.8
	hurt_cooldown = 0.0
	fire_cooldown = 0.0
	game_over = false
	paused = false
	fire_requires_release = true
	particles.clear()
	muzzle_time = 0.0
	dash_time = 0.0
	dash_cooldown = 0.0
	dash_direction = Vector2.RIGHT
	wave = 1
	wave_remaining = 5
	wave_break = 0.0
	player_visual.reset_pose()
	player_visual.present(player_position, aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	if is_instance_valid(overlay):
		overlay.queue_redraw()
	hud_view.present(health, MAX_HEALTH, kills, elapsed, wave, wave_remaining + enemies.size(), wave_break, dash_cooldown, game_over, paused)


func _draw() -> void:
	draw_rect(ARENA, Color("151c2c"))
	for x in range(24, 617, 16):
		draw_line(Vector2(x, 64), Vector2(x, 336), Color("1d2638"))
	for y in range(64, 337, 16):
		draw_line(Vector2(24, y), Vector2(616, y), Color("1d2638"))
	draw_rect(ARENA, Color("61758b"), false, 1.0)
	for enemy in enemies:
		var point: Vector2 = Vector2(enemy["position"]).round()
		var color := Color("fff0b0") if enemy["flash"] > 0.0 else Color("e76170")
		draw_rect(Rect2(point - Vector2(8, 8), Vector2(16, 16)), color)
		draw_rect(Rect2(point + Vector2(-8, -12), Vector2(8 * enemy["health"], 2)), Color("ffb454"))
	if dash_time > 0.0:
		draw_line(player_position - dash_direction * 26.0, player_position, Color("388fba"), 10.0)
	if muzzle_time > 0.0:
		draw_circle((player_position + aim * 17.0).round(), 4.0, Color("fff0b0"))
	for particle in particles:
		var tint: Color = particle["color"]
		tint.a = clampf(particle["life"] / 0.3, 0.0, 1.0)
		draw_rect(Rect2(Vector2(particle["position"]).round(), Vector2(2, 2)), tint)
	for bullet in bullets:
		draw_rect(Rect2(Vector2(bullet["position"]).round() - Vector2(2, 2), Vector2(4, 4)), Color("ffb454"))


func _draw_overlay() -> void:
	if game_over or paused:
		overlay.draw_rect(ARENA, Color(0.02, 0.02, 0.04, 0.86))
