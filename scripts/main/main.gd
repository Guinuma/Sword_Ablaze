extends Node2D
## Coordinates use logical pixels; simulation and art presentation are separate.

const RunState = preload("res://scripts/run/run_state.gd")
var run = RunState.new()
const ArenaRecords = preload("res://scripts/run/arena_records.gd")
var records = ArenaRecords.new()
const Preferences = preload("res://scripts/settings/preferences.gd")
var preferences = Preferences.new()
var run_recorded: bool = false
const UpgradeSystem = preload("res://scripts/run/upgrade_system.gd")
var upgrades = UpgradeSystem.new()

const WaveDirector = preload("res://scripts/run/wave_director.gd")
var waves = WaveDirector.new()

const ArenaHud = preload("res://scripts/ui/arena_hud.gd")
const ExileVisual = preload("res://scripts/player/exile_visual.gd")
const PlayerState = preload("res://scripts/player/player_state.gd")
var player = PlayerState.new()
var player_visual: Node2D
var overlay: Node2D
var world: Node2D
const EnemyVisual = preload("res://scripts/enemies/enemy_visual.gd")
var enemy_views: Array[Node2D] = []
const COURTYARD = preload("res://assets/art/arena/celestial-courtyard-01.png")

const ARENA := Rect2(34, 70, 572, 258)
const ProjectileSystem = preload("res://scripts/combat/projectile_system.gd")
var projectiles = ProjectileSystem.new()
const HostileProjectiles = preload("res://scripts/combat/hostile_projectiles.gd")
var hostile_projectiles = HostileProjectiles.new()
const EnemySystem = preload("res://scripts/enemies/enemy_system.gd")
var enemies = EnemySystem.new()
var particles: Array[Dictionary] = []
var hud_view: CanvasLayer
var random := RandomNumberGenerator.new()


func _ready() -> void:
	preferences.load_preferences()
	_apply_upgrades()
	records.load_records()
	run.phase_changed.connect(_on_run_phase_changed)
	enemies.shot.connect(hostile_projectiles.fire)
	hostile_projectiles.hit_player.connect(_take_player_damage)
	player.shot.connect(projectiles.fire)
	projectiles.impacted.connect(_on_projectile_impact)
	projectiles.defeated.connect(_on_projectile_defeat)
	waves.wave_started.connect(run.start_combat)
	waves.spawn_requested.connect(_spawn_enemy)
	waves.wave_cleared.connect(_on_wave_cleared)
	random.randomize()
	hud_view = ArenaHud.new()
	hud_view.preferences_changed.connect(_change_preferences)
	hud_view.upgrade_selected.connect(_choose_upgrade)
	hud_view.resume_requested.connect(func(): _set_paused(false))
	hud_view.restart_requested.connect(_reset_run)
	hud_view.quit_requested.connect(func(): get_tree().quit())
	add_child(hud_view)
	world = Node2D.new()
	world.y_sort_enabled = true
	world.z_index = 1
	add_child(world)
	player_visual = ExileVisual.new()
	player_visual.defeat_finished.connect(_update_hud)
	player_visual.reduced_flashes = preferences.reduced_flashes
	player_visual.reduced_motion = preferences.reduced_motion
	world.add_child(player_visual)
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
	if not run.is_active():
		return
	_update_effects(delta)
	run.advance(delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.advance(delta, movement, get_global_mouse_position(), Input.is_action_just_pressed("dash"), Input.is_action_pressed("fire"), ARENA)
	_update_waves(delta)
	_update_enemies(delta)
	_update_bullets(delta)
	_check_contact()
	hostile_projectiles.advance(delta, player.player_position, ARENA)
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
	if preferences.reduced_motion:
		return
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
	hostile_projectiles.clear()
	run.start_intermission()
	if waves.number % waves.settings.upgrade_every == 0 and not upgrades.offer(random).is_empty():
		run.start_upgrade()
		player.fire_requires_release = true



func _spawn_enemy(kind: StringName = &"chaser") -> void:
	enemies.spawn(player.player_position, ARENA, random, kind)


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
	if enemies.touches(player.player_position):
		_take_player_damage()


func _take_player_damage() -> void:
	if player.hurt_cooldown > 0.0 or player.dash_time > 0.0 or run.phase != RunState.Phase.COMBAT:
		return
	run.take_damage()
	_burst(player.player_position, Color("65dfc1"), 10)
	player.hurt_cooldown = player.CONTACT_COOLDOWN


func _change_preferences(reduced_flashes: bool, reduced_motion: bool) -> void:
	preferences.reduced_flashes = reduced_flashes
	preferences.reduced_motion = reduced_motion
	preferences.save()
	player_visual.reduced_flashes = reduced_flashes
	player_visual.reduced_motion = reduced_motion
	player_visual.queue_redraw()
	if reduced_motion:
		particles.clear()
	_update_hud()
	queue_redraw()


func _apply_upgrades() -> void:
	var base = load("res://resources/default_weapon.tres")
	var weapon = base.duplicate()
	weapon.fire_interval = upgrades.value("fire_interval", base.fire_interval)
	weapon.damage = int(upgrades.value("damage", base.damage))
	weapon.knockback = upgrades.value("knockback", base.knockback)
	player.weapon = weapon
	projectiles.weapon = weapon
	player.move_speed = upgrades.value("move_speed", player.SPEED)
	player.dash_recharge = upgrades.value("dash_cooldown", player.DASH_COOLDOWN)
	if is_instance_valid(player_visual):
		player_visual.walk_rate = 8.0 * player.move_speed / player.SPEED


func _choose_upgrade(id: StringName) -> void:
	if run.phase != RunState.Phase.UPGRADE or not upgrades.choose(id):
		return
	_apply_upgrades()
	player.fire_requires_release = true
	run.finish_upgrade()
	_update_hud()
	queue_redraw()


func _on_run_phase_changed(phase: RunState.Phase) -> void:
	if phase == RunState.Phase.DEAD and not run_recorded:
		run_recorded = true
		player_visual.begin_defeat()
		records.record(waves.number, run.kills, run.elapsed)


func _reset_run() -> void:
	run_recorded = false
	upgrades.reset()
	player.reset()
	_apply_upgrades()
	projectiles.clear()
	hostile_projectiles.clear()
	enemies.clear()
	run.reset()
	particles.clear()
	waves.reset()
	player_visual.reset_pose()
	player_visual.present(player.player_position, player.aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()
	queue_redraw()


func _present_enemies() -> void:
	while enemy_views.size() > enemies.items.size():
		var view = enemy_views.pop_back()
		view.hide()
		view.queue_free()
	while enemy_views.size() < enemies.items.size():
		var view = EnemyVisual.new()
		world.add_child(view)
		enemy_views.append(view)
	for index in range(enemy_views.size()):
		enemy_views[index].present(enemies.items[index], run.elapsed, preferences.reduced_motion, preferences.reduced_flashes)


func _update_hud() -> void:
	_present_enemies()
	if is_instance_valid(overlay):
		overlay.queue_redraw()
	hud_view.present_preferences(preferences.reduced_flashes, preferences.reduced_motion, preferences.last_error != OK)
	hud_view.present_upgrades(upgrades.offered, run.phase == RunState.Phase.UPGRADE, upgrades.stacks)
	hud_view.present_records(records.data, records.last_error != OK)
	hud_view.present(run.health, run.MAX_HEALTH, run.kills, run.elapsed, waves.number, waves.remaining + enemies.items.size(), waves.break_time, player.dash_cooldown, (run.phase == RunState.Phase.DEAD and player_visual.defeat_done), (run.phase == RunState.Phase.PAUSED))

	if run.phase == RunState.Phase.DEAD and not player_visual.defeat_done:
		hud_view.wave_status.hide()


func _draw() -> void:
	draw_texture_rect(COURTYARD, Rect2(0, 38, 640, 332), false)
	draw_rect(Rect2(0, 0, 640, 62), Color("080d16"))
	draw_line(Vector2(24, 61), Vector2(616, 61), Color("756247"), 1.0)
	if player.dash_time > 0.0 and not preferences.reduced_motion:
		draw_line(player.player_position - player.dash_direction * 26.0, player.player_position, Color("388fba"), 10.0)
	if player.muzzle_time > 0.0 and not preferences.reduced_flashes:
		draw_circle(player.muzzle_position().round(), 4.0, Color("fff0b0"))
	for particle in particles:
		var tint: Color = particle["color"]
		tint.a = clampf(particle["life"] / 0.3, 0.0, 1.0)
		draw_rect(Rect2(Vector2(particle["position"]).round(), Vector2(2, 2)), tint)
	for bullet in projectiles.items:
		draw_rect(Rect2(Vector2(bullet["position"]).round() - Vector2(2, 2), Vector2(4, 4)), Color("ffb454"))

	for bullet in hostile_projectiles.items:
		var point: Vector2 = Vector2(bullet["position"]).round()
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -4), point + Vector2(4, 0), point + Vector2(0, 4), point + Vector2(-4, 0)]), Color("ee8de8"))


func _draw_overlay() -> void:
	if run.phase == RunState.Phase.DEAD and not player_visual.defeat_done:
		return
	if not run.is_active():
		overlay.draw_rect(ARENA, Color(0.02, 0.02, 0.04, 0.86))
