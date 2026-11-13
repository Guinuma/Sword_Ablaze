extends Node2D
## Art presentation only; grounded origin matches the simulation position.
const EnemySystem = preload("res://scripts/enemies/enemy_system.gd")
const WISP = preload("res://assets/art/enemies/corrupted-wisp-01-atlas.tres")
const SENTINEL = preload("res://assets/art/enemies/fractured-sentinel-01-atlas.tres")
const WALK = preload("res://assets/art/enemies/fractured-sentinel-walk-01-frames.tres")
const CAST = preload("res://assets/art/enemies/fractured-sentinel-cast-01-frames.tres")
const CHARGER = preload("res://assets/art/enemies/charger-02-frames.tres")
const GUARDIAN = preload("res://assets/art/enemies/guardian-02-frames.tres")
const WARDEN = preload("res://assets/art/enemies/warden-02-frames.tres")
const ELITE = preload("res://assets/art/enemies/elite-02-frames.tres")
var walk_clock: float = 0.0
var walk_frame: int = 0
var last_point := Vector2.ZERO
var last_time: float = 0.0
var state: Dictionary = {}
var elapsed: float = 0.0
var reduced_motion: bool = false
var reduced_flashes: bool = false
var moving: bool = false


func present(enemy: Dictionary, time: float, reduce_motion: bool, reduce_flashes: bool) -> void:
	var point: Vector2 = enemy["position"]
	var delta := maxf(0.0, time - last_time)
	if delta > 0.0:
		moving = last_point.distance_squared_to(point) > 0.0001
		if moving and enemy.get("windup", 0.0) <= 0.0:
			walk_clock += delta
			walk_frame = int(walk_clock * 6.0) % 4
		else:
			walk_clock = 0.0
			walk_frame = 0
	elif time < last_time:
		walk_clock = 0.0
		walk_frame = 0
		moving = false
	last_point = point
	last_time = time
	position = point.round()
	state = enemy
	elapsed = time
	reduced_motion = reduce_motion
	reduced_flashes = reduce_flashes
	queue_redraw()


func _draw() -> void:
	if state.is_empty():
		return
	var profile = state.get("profile")
	var ranged: bool = profile != null and profile.kind in ["ranged", "elite"]
	var warning: float = state.get("spawn_time", 0.0)
	if warning > 0.0:
		var duration: float = profile.spawn_warning if profile != null else 0.7
		var progress := clampf(1.0 - warning / duration, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 12.0, Color(0.5, 0.12, 0.3, 0.2))
		draw_arc(Vector2.ZERO, 13.0 if reduced_motion else 13.0 - progress * 3.0, 0.0, TAU, 24, Color("ffb454"), 1.0)
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color("ffe0a3"))
		draw_line(Vector2(0, -4), Vector2(0, 4), Color("ffe0a3"))
		return
	if profile != null and profile.kind == "boss":
		_draw_boss(profile)
		return
	if profile != null and profile.kind == "guardian":
		_draw_guardian(profile)
		return
	if profile != null and profile.kind == "charger":
		_draw_charger(profile)
		return
	# Ground shadow stays fixed while the wisp floats above it.
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0 if ranged else 7.0, Color(0.02, 0.03, 0.06, 0.55))
	draw_set_transform(Vector2.ZERO)
	var windup: float = state.get("windup", 0.0)
	if windup > 0.0:
		var direction: Vector2 = state["shot_direction"]
		if profile.kind == "elite":
			for index in range(8):
				var spoke := direction.rotated(index * TAU / 8)
				_draw_shot_warning(spoke, 14.0, profile.attack_range, windup / profile.attack_warning)
		else:
			_draw_shot_warning(direction, 11.0, profile.attack_range, windup / profile.attack_warning)
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("ed99eb"), 1.0)
	var bob: float = 0.0
	if not reduced_motion:
		bob = roundf(sin(elapsed * (12.0 if ranged else 5.0) + position.x * 0.04))
		if ranged and (not moving or windup > 0.0):
			bob = 0.0
	var tint := Color(1.3, 1.18, 1.05) if state["flash"] > 0.0 and not reduced_flashes else Color.WHITE
	if profile != null and profile.kind == "elite":
		var pose := 3 if windup > 0.0 else (1 + walk_frame % 2 if moving else 0)
		_draw_pose(ELITE, pose, 44.0)
	elif ranged:
		if windup > 0.0:
			var frame: int = clampi(int((1.0 - windup / profile.attack_warning) * 4.0), 0, 3)
			draw_texture_rect(CAST.get_frame_texture(&"cast", frame), Rect2(-18, -29, 36, 39), false, tint)
		else:
			var body = WALK.get_frame_texture(&"walk", walk_frame) if moving else SENTINEL
			draw_texture_rect(body, Rect2(-17, -29 + bob, 34, 39), false, tint)
	else:
		draw_texture_rect(WISP, Rect2(-10, -25 + bob, 20, 35), false, tint)
	if profile != null and profile.kind == "elite":
		draw_arc(Vector2.ZERO, 14, 0, TAU, 24, Color("c5a46c"), 2)

	var health: int = state["health"]
	var max_health: int = profile.health if profile != null else 2
	if health < max_health:
		draw_rect(Rect2(-9, -33, 18, 2), Color("101421"))
		draw_rect(Rect2(-9, -33, 18.0 * maxf(0.0, float(health) / max_health), 2), Color("ffb454"))


func _draw_charger(profile: Resource) -> void:
	var phase: String = state.get("charge_phase", "approach")
	var direction: Vector2 = state.get("charge_direction", Vector2.DOWN)
	if phase == "warning":
		var length: float = profile.charge_speed * profile.charge_duration
		var end := direction * length
		var side: Vector2 = direction.orthogonal() * profile.contact_radius
		draw_line(side, end + side, Color("ffb454"), 1.0)
		draw_line(-side, end - side, Color("ffb454"), 1.0)
		_draw_chevron(end, direction, profile.contact_radius, Color("ffe0a3"))
		var progress := _warning_progress(state.get("charge_timer", profile.attack_warning) / profile.attack_warning)
		_draw_chevron(direction * lerpf(24.0, length - 12.0, progress), direction, 6.0, Color("ffe0a3"))
	draw_circle(Vector2(0, 7), 11, Color(0.02, 0.03, 0.06, 0.6))
	var pose: int = {"approach": 0, "warning": 1, "charge": 2, "recovery": 3}.get(phase, 0)
	_draw_pose(CHARGER, pose, 28.0, direction.x < 0.0 if phase != "approach" else state.get("facing", Vector2.RIGHT).x < 0.0, 40.0)
	if phase == "charge":
		draw_line(-direction * 10, -direction * 23, Color("ffb454"), 3.0)
	if phase == "recovery":
		draw_arc(Vector2(0, -26), 5, 0, PI, 8, Color("ede3c9"), 1.0)
	if state["health"] < profile.health:
		draw_rect(Rect2(-10, -33, 20, 2), Color("101421"))
		draw_rect(Rect2(-10, -33, 20.0 * state["health"] / profile.health, 2), Color("ffb454"))


func _draw_guardian(profile: Resource) -> void:
	var facing: Vector2 = state.get("facing", Vector2.DOWN)
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 15, Color(0.02, 0.03, 0.06, 0.6))
	draw_set_transform(Vector2.ZERO)
	var pose := 0 if facing.y > 0.5 else 2 if facing.y < -0.5 else 1 if facing.x > 0.0 else 3
	_draw_pose(GUARDIAN, pose, 42.0)
	draw_arc(Vector2.ZERO, 17, facing.angle() - PI / 3, facing.angle() + PI / 3, 12, Color("101d2b"), 6)
	draw_arc(Vector2.ZERO, 17, facing.angle() - PI / 3, facing.angle() + PI / 3, 12, Color("c5a46c"), 3)
	# Rear crack marks the weak side without relying on color alone.
	var rear := -facing * 10
	draw_line(rear - Vector2(2, 4), rear + Vector2(2, 0), Color("ede3c9"), 2)
	draw_line(rear + Vector2(2, 0), rear - Vector2(2, -4), Color("ede3c9"), 2)
	if state["health"] < profile.health:
		draw_rect(Rect2(-13, -35, 26, 2), Color("101421"))
		draw_rect(Rect2(-13, -35, 26.0 * state["health"] / profile.health, 2), Color("ffb454"))


func _draw_boss(profile: Resource) -> void:
	var second: bool = state.get("boss_phase", 1) == 2
	var gold := Color("ed8c82") if second else Color("c5a46c")
	if state.get("windup", 0.0) > 0.0:
		for direction in EnemySystem.boss_directions(state):
			_draw_shot_warning(direction, 27.0, 600.0, state.windup / (0.8 if second else profile.attack_warning))
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 25, Color(0.02, 0.03, 0.06, 0.65))
	draw_set_transform(Vector2.ZERO)
	var pose := (2 if second else 0) + (1 if state.get("windup", 0.0) > 0.0 else 0)
	_draw_pose(WARDEN, pose, 65.0)
	draw_rect(Rect2(-25, -65, 50, 4), Color("101421"))
	draw_rect(Rect2(-25, -65, 50.0 * state.health / profile.health, 4), gold)


func _warning_progress(remaining: float) -> float:
	return 0.4 if reduced_motion else clampf(1.0 - remaining, 0.0, 1.0)


func _draw_shot_warning(direction: Vector2, start: float, length: float, remaining: float) -> void:
	draw_line(direction * start, direction * length, Color(0.95, 0.35, 0.8, 0.55), 1.0)
	var tip := direction * lerpf(start + 10.0, minf(length, start + 68.0), _warning_progress(remaining))
	_draw_chevron(tip, direction, 4.0, Color("f9c1f2"))


func _draw_chevron(tip: Vector2, direction: Vector2, width: float, color: Color) -> void:
	var base := tip - direction * width
	var side := direction.orthogonal() * width
	var points := PackedVector2Array([base + side, tip, base - side])
	draw_polyline(points, Color("101421"), 3.0)
	draw_polyline(points, color, 1.0)


func _draw_pose(frames: SpriteFrames, index: int, height: float, mirror: bool = false, max_width: float = 100.0) -> void:
	var maximum := Vector2.ZERO
	for frame in range(frames.get_frame_count(&"poses")):
		var dimensions := frames.get_frame_texture(&"poses", frame).get_size()
		maximum.x = maxf(maximum.x, dimensions.x)
		maximum.y = maxf(maximum.y, dimensions.y)
	var ratio := minf(height / maximum.y, max_width / maximum.x)
	var texture := frames.get_frame_texture(&"poses", index)
	var dimensions := (texture.get_size() * ratio).round()
	var tint := Color(1.3, 1.18, 1.05) if state.get("flash", 0.0) > 0.0 and not reduced_flashes else Color.WHITE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1) if mirror else Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-floor(dimensions.x / 2), 8 - dimensions.y), dimensions), false, tint)
	draw_set_transform(Vector2.ZERO)
