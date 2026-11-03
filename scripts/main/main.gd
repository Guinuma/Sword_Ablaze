extends Node2D
## Coordinates use logical pixels; simulation and art presentation are separate.

const RunState = preload("res://scripts/run/run_state.gd")
var run = RunState.new()
const HealingDrops = preload("res://scripts/run/healing_drops.gd")
var healing_drops = HealingDrops.new()
const ArenaRecords = preload("res://scripts/run/arena_records.gd")
var records = ArenaRecords.new()
const Preferences = preload("res://scripts/settings/preferences.gd")
var preferences = Preferences.new()
const SoundEffects = preload("res://scripts/audio/sound_effects.gd")
var sounds = SoundEffects.new()
const CombatTutorial = preload("res://scripts/ui/combat_tutorial.gd")
var tutorial = CombatTutorial.new()
const GlobalProfile = preload("res://scripts/run/global_profile.gd")
var profile
var active_run_id: int = 0
var reward_pending: bool = false
var reward_received: bool = false
var reward_awarded: int = 0
var finite_mode: bool = false
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
const CombatFeedback = preload("res://scripts/ui/combat_feedback.gd")
var feedback = CombatFeedback.new()
var hud_view: CanvasLayer
var random := RandomNumberGenerator.new()


func _ready() -> void:
	finite_mode = bool(get_tree().get_meta("finite_run", false))
	waves.final_wave = 10 if finite_mode else 0
	if finite_mode and records.path == "user://arena_records.json":
		records.path = "user://finite_records.json"
	profile = GlobalProfile.for_tree(get_tree())
	_begin_progression()
	preferences.load_preferences()
	add_child(sounds)
	player.shot.connect(func(_origin, _direction): sounds.play(&"shot"); tutorial.shot())
	player.dashed.connect(func(): sounds.play(&"dash"); tutorial.dashed(); feedback.add(&"dash", player.player_position))
	run.healed.connect(func(_amount): feedback.add(&"heal", player.player_position))
	enemies.activated.connect(func(point): feedback.add(&"spawn", point))
	run.damaged.connect(func(_health): sounds.play(&"damage"))
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
	waves.run_cleared.connect(_on_run_won)
	random.randomize()
	hud_view = ArenaHud.new()
	hud_view.reward_retry_requested.connect(_retry_reward)
	hud_view.pause_requested.connect(func(): _set_paused(true))
	hud_view.preferences_changed.connect(_change_preferences)
	hud_view.upgrade_selected.connect(_choose_upgrade)
	hud_view.resume_requested.connect(func(): _set_paused(false))
	hud_view.restart_requested.connect(_reset_run)
	hud_view.main_menu_requested.connect(_return_to_menu)
	hud_view.quit_requested.connect(func(): get_tree().quit())
	add_child(hud_view)
	sounds.watch_buttons(hud_view)
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
	player.fire_requires_release = true
	player_visual.present(player.player_position, player.aim, Vector2.ZERO, 0.0, false, false, false)
	_update_hud()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and run.phase not in [RunState.Phase.DEAD, RunState.Phase.WON]:
		_set_paused(true)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_sandbox"):
		_reset_run()
	if Input.is_action_just_pressed("pause_run") and run.phase not in [RunState.Phase.DEAD, RunState.Phase.WON]:
		_set_paused(not (run.phase == RunState.Phase.PAUSED))
	if not Input.is_action_pressed("fire"):
		player.fire_requires_release = false
	if not run.is_active():
		return
	if Input.is_action_pressed("fire") and hud_view.blocks_fire():
		player.fire_requires_release = true
	_update_effects(delta)
	run.advance(delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var old_aim: Vector2 = player.aim
	player.advance(delta, movement, get_global_mouse_position(), Input.is_action_just_pressed("dash"), Input.is_action_pressed("fire"), ARENA)
	tutorial.observe(delta, movement, old_aim.distance_squared_to(player.aim) > 0.0001)
	healing_drops.advance(delta, player.player_position, run)
	_update_waves(delta)
	if not run.is_active():
		_update_hud()
		queue_redraw()
		return
	_update_enemies(delta)
	_update_bullets(delta)
	_check_contact()
	hostile_projectiles.advance(delta, player.player_position, ARENA)
	player_visual.present(player.player_position, player.aim, player.dash_direction if player.dash_time > 0.0 else movement, delta, player.dash_time > 0.0, player.hurt_cooldown > 0.0, player.muzzle_time > 0.0)
	_update_hud()
	queue_redraw()


func _set_paused(value: bool) -> void:
	if value:
		sounds.stop_combat()
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
	feedback.advance(delta)
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
	run.record_wave_clear(waves.number)
	sounds.play(&"wave")
	feedback.add(&"wave", player.player_position)
	projectiles.clear()
	hostile_projectiles.clear()
	run.start_intermission()
	if waves.number % waves.settings.upgrade_every == 0 and not upgrades.offer(random).is_empty():
		run.start_upgrade()
		player.fire_requires_release = true



func _spawn_enemy(kind: StringName = &"chaser") -> void:
	enemies.spawn(player.player_position, ARENA, random, kind)
	if kind == &"boss":
		enemies.items.back()["position"] = ARENA.get_center() + Vector2(0, -85)


func _update_enemies(delta: float) -> void:
	enemies.advance(delta, player.player_position, waves.number, ARENA)


func _update_bullets(delta: float) -> void:
	projectiles.advance(delta, enemies.items, ARENA)


func _on_projectile_impact(point: Vector2) -> void:
	sounds.play(&"impact")
	_burst(point, Color("ffb454"), 5)


func _on_projectile_defeat(point: Vector2) -> void:
	sounds.play(&"defeat")
	_burst(point, Color("e76170"), 10)
	run.record_kill()
	if run.phase == RunState.Phase.COMBAT:
		healing_drops.roll(point, random)


func _check_contact() -> void:
	if enemies.touches(player.player_position):
		_take_player_damage()


func _take_player_damage(amount: int = RunState.HIT_DAMAGE) -> void:
	if player.hurt_cooldown > 0.0 or player.is_dash_protected() or run.phase != RunState.Phase.COMBAT:
		return
	run.take_damage(amount)
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
	var base = load("res://resources/scatter_weapon.tres" if preferences.selected_weapon == &"scatter" else "res://resources/default_weapon.tres")
	var weapon = base.duplicate()
	weapon.fire_interval = upgrades.value("fire_interval", base.fire_interval)
	weapon.damage = int(upgrades.value("damage", base.damage))
	weapon.knockback = upgrades.value("knockback", base.knockback)
	player.weapon = weapon
	projectiles.weapon = weapon
	player.move_speed = upgrades.value("move_speed", player.SPEED)
	run.set_max_health(int(upgrades.value("max_health", run.MAX_HEALTH)))
	player.dash_recharge = upgrades.value("dash_cooldown", player.DASH_COOLDOWN)
	if is_instance_valid(player_visual):
		player_visual.walk_rate = 8.0 * player.move_speed / player.SPEED


func _choose_upgrade(id: StringName) -> void:
	if run.phase != RunState.Phase.UPGRADE or not upgrades.choose(id):
		return
	_apply_upgrades()
	sounds.play(&"upgrade")
	feedback.add(&"upgrade", player.player_position)
	tutorial.chose_upgrade()
	player.fire_requires_release = true
	run.finish_upgrade()
	_update_hud()
	queue_redraw()


func _on_run_won() -> void:
	if finite_mode and waves.number == 10 and waves.remaining == 0 and enemies.items.is_empty():
		run.record_wave_clear(waves.number)
		run.win()


func _on_run_phase_changed(phase: RunState.Phase) -> void:
	if phase in [RunState.Phase.WON, RunState.Phase.DEAD] and not reward_received:
		_settle_reward()
	if phase == RunState.Phase.WON and not run_recorded:
		run_recorded = true
		projectiles.clear()
		hostile_projectiles.clear()
		healing_drops.clear()
		sounds.stop_combat()
		records.record(waves.number, run.kills, run.elapsed, true)
	if phase == RunState.Phase.DEAD and not run_recorded:
		run_recorded = true
		player_visual.begin_defeat()
		records.record(waves.number, run.kills, run.elapsed)


func _reset_run() -> void:
	if reward_pending and not _settle_reward():
		_update_hud()
		return
	_begin_progression()
	tutorial.reset()
	sounds.stop_combat()
	run_recorded = false
	upgrades.reset()
	run.reset()
	healing_drops.clear()
	player.reset()
	_apply_upgrades()
	projectiles.clear()
	hostile_projectiles.clear()
	enemies.clear()
	particles.clear()
	feedback.clear()
	waves.reset()
	player_visual.reset_pose()
	player.fire_requires_release = true
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
	hud_view.present_upgrades(upgrades.offered, run.phase == RunState.Phase.UPGRADE, upgrades.stacks, upgrades.definitions)
	hud_view.present_records(records.data, records.last_error != OK)
	hud_view.present(run.health, run.max_health, run.kills, run.elapsed, waves.number, waves.remaining + enemies.items.size(), waves.break_time, player.dash_cooldown, ((run.phase == RunState.Phase.DEAD and player_visual.defeat_done) or run.phase == RunState.Phase.WON), (run.phase == RunState.Phase.PAUSED), player.dash_recharge)

	if run.phase == RunState.Phase.WON:
		hud_view.status.text = "COURTYARD CLEARED"
		hud_view.summary.text = "Crown broken  /  %d kills\nCompleted in %d:%02d" % [run.kills, int(run.elapsed) / 60, int(run.elapsed) % 60]
	if finite_mode:
		for enemy in enemies.items:
			if enemy.get("profile") != null and enemy.profile.kind == "boss" and run.is_active():
				hud_view.wave_status.text = "WARDEN %d / %d  PHASE %d" % [enemy.health, enemy.profile.health, enemy.get("boss_phase", 1)]
		hud_view.wave_heading.text = "BOSS" if waves.number == 10 else "WAVE %02d / 09" % waves.number
		hud_view.record_label.text = "FINITE RUNS: %d  /  WINS: %d" % [records.data["runs"], records.data["wins"]]
		hud_view.record_label.text += "\nCould not save records" if records.last_error != OK else ""
	hud_view.present_reward(run.phase in [RunState.Phase.WON, RunState.Phase.DEAD], reward_pending, reward_received, reward_awarded, GlobalProfile.level(profile.data.xp), active_run_id == 0)
	hud_view.control_hint.text = tutorial.hint() if active_run_id > 0 else "GLOBAL XP UNAVAILABLE THIS RUN"
	hud_view.control_hint.visible = run.is_active() and (tutorial.step < 5 or active_run_id == 0)
	hud_view.dash_key.text = CombatTutorial.key_name(&"dash")
	hud_view.menu_hint.text = "ESC RESUME    %s RESTART" % CombatTutorial.key_name(&"reset_sandbox")
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
	for item in healing_drops.items:
		_draw_healing_drop(item)
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
	feedback.draw_on(overlay, preferences.reduced_motion, preferences.reduced_flashes)
	if run.phase == RunState.Phase.DEAD and not player_visual.defeat_done:
		return
	if not run.is_active():
		overlay.draw_rect(ARENA, Color(0.02, 0.02, 0.04, 0.86))


func _return_to_menu() -> void:
	if reward_pending and not _settle_reward():
		_update_hud()
		return
	# Leaving a live run abandons it; only terminal results settle progression.
	get_tree().change_scene_to_file("res://scenes/main/menu.tscn")


func _draw_healing_drop(item: Dictionary) -> void:
	var point: Vector2 = Vector2(item["position"]).round()
	var wings: bool = item["amount"] == 100
	draw_circle(point, 12.0 if wings else 8.0, Color(0.04, 0.1, 0.15, 0.85))
	for side in ([-1, 1] if wings else [1]):
		var feather := PackedVector2Array([point + Vector2(-2 * side, 5), point + Vector2(2 * side, -3), point + Vector2(9 * side, -8), point + Vector2(7 * side, 1), point + Vector2(2 * side, 6)])
		draw_colored_polygon(feather, Color("ede3c9"))
		draw_polyline(PackedVector2Array([point + Vector2(-1 * side, 5), point + Vector2(7 * side, -6)]), Color("c5a46c"), 1.0)
		for offset in [0, 3]:
			draw_line(point + Vector2((2 + offset) * side, 1 - offset), point + Vector2((5 + offset) * side, 2 - offset), Color("7c9da7"), 1.0)


func _begin_progression() -> void:
	profile.load_profile()
	active_run_id = profile.begin_run(&"courtyard" if finite_mode else &"endless")
	reward_pending = false
	reward_received = false
	reward_awarded = 0

func _settle_reward() -> bool:
	if reward_received:
		return true
	if active_run_id == 0 or run.phase not in [RunState.Phase.DEAD, RunState.Phase.WON]:
		return false
	var result: Dictionary = profile.settle(active_run_id, &"courtyard" if finite_mode else &"endless", &"victory" if run.phase == RunState.Phase.WON else &"defeat", run.kills, run.cleared_waves)
	reward_pending = not result.ok
	if result.ok:
		reward_received = true
		reward_awarded = result.awarded
	return result.ok

func _retry_reward() -> void:
	_settle_reward()
	_update_hud()
