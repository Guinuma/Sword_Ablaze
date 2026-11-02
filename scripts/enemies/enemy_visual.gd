extends Node2D
## Art presentation only; grounded origin matches the simulation position.
const WISP = preload("res://assets/art/enemies/corrupted-wisp-01-atlas.tres")
const SENTINEL = preload("res://assets/art/enemies/fractured-sentinel-01-atlas.tres")
const WALK = preload("res://assets/art/enemies/fractured-sentinel-walk-01-frames.tres")
const CAST = preload("res://assets/art/enemies/fractured-sentinel-cast-01-frames.tres")
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
	var ranged: bool = profile != null and profile.kind == "ranged"
	var warning: float = state.get("spawn_time", 0.0)
	if warning > 0.0:
		var duration: float = profile.spawn_warning if profile != null else 0.7
		var progress := clampf(1.0 - warning / duration, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 12.0, Color(0.5, 0.12, 0.3, 0.2))
		draw_arc(Vector2.ZERO, 13.0 - progress * 3.0, 0.0, TAU, 24, Color("ffb454"), 1.0)
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color("ffe0a3"))
		draw_line(Vector2(0, -4), Vector2(0, 4), Color("ffe0a3"))
		return
	# Ground shadow stays fixed while the wisp floats above it.
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0 if ranged else 7.0, Color(0.02, 0.03, 0.06, 0.55))
	draw_set_transform(Vector2.ZERO)
	var windup: float = state.get("windup", 0.0)
	if windup > 0.0:
		var direction: Vector2 = state["shot_direction"]
		draw_line(Vector2.ZERO, direction * profile.attack_range, Color(0.95, 0.35, 0.8, 0.65), 1.0)
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("ed99eb"), 1.0)
	var bob: float = 0.0
	if not reduced_motion:
		bob = roundf(sin(elapsed * (12.0 if ranged else 5.0) + position.x * 0.04))
		if ranged and (not moving or windup > 0.0):
			bob = 0.0
	var tint := Color(1.8, 1.5, 1.2) if state["flash"] > 0.0 and not reduced_flashes else Color.WHITE
	if ranged:
		if windup > 0.0:
			var frame: int = clampi(int((1.0 - windup / profile.attack_warning) * 4.0), 0, 3)
			draw_texture_rect(CAST.get_frame_texture(&"cast", frame), Rect2(-18, -29, 36, 39), false, tint)
		else:
			var body = WALK.get_frame_texture(&"walk", walk_frame) if moving else SENTINEL
			draw_texture_rect(body, Rect2(-17, -29 + bob, 34, 39), false, tint)
	else:
		draw_texture_rect(WISP, Rect2(-10, -25 + bob, 20, 35), false, tint)
	var health: int = state["health"]
	var max_health: int = profile.health if profile != null else 2
	if health < max_health:
		draw_rect(Rect2(-9, -33, 18, 2), Color("101421"))
		draw_rect(Rect2(-9, -33, 18.0 * maxf(0.0, float(health) / max_health), 2), Color("ffb454"))
