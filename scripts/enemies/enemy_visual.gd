extends Node2D
## Art presentation only; grounded origin matches the simulation position.
const EnemySystem = preload("res://scripts/enemies/enemy_system.gd")
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
	var ranged: bool = profile != null and profile.kind in ["ranged", "elite"]
	var warning: float = state.get("spawn_time", 0.0)
	if warning > 0.0:
		var duration: float = profile.spawn_warning if profile != null else 0.7
		var progress := clampf(1.0 - warning / duration, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 12.0, Color(0.5, 0.12, 0.3, 0.2))
		draw_arc(Vector2.ZERO, 13.0 - progress * 3.0, 0.0, TAU, 24, Color("ffb454"), 1.0)
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
				draw_line(spoke * 14, spoke * profile.attack_range, Color(0.95, 0.35, 0.8, 0.5), 1)
		else:
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
	if profile != null and profile.kind == "elite":
		draw_arc(Vector2.ZERO, 14, 0, TAU, 24, Color("c5a46c"), 2)
		var crown := PackedVector2Array([Vector2(-9, -34), Vector2(-9, -42), Vector2(-4, -38), Vector2(0, -45), Vector2(4, -38), Vector2(9, -42), Vector2(9, -34)])
		draw_colored_polygon(crown, Color("c5a46c"))
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
		draw_line(end + side, end, Color("ffe0a3"), 2.0)
		draw_line(end - side, end, Color("ffe0a3"), 2.0)
	var color := Color("ffb454") if phase == "warning" else Color("a96d55")
	if phase == "recovery":
		color = Color("666b86")
	if state["flash"] > 0.0 and not reduced_flashes:
		color = Color("ffe0a3")
	draw_circle(Vector2(0, 7), 10, Color(0.02, 0.03, 0.06, 0.6))
	# Angular armored ram silhouette is a code-native prototype visual.
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 2), Vector2(-9, -17), Vector2(-4, -12), Vector2(0, -25), Vector2(4, -12), Vector2(9, -17), Vector2(12, 2), Vector2(0, 8)]), color)
	draw_line(Vector2(-6, -6), Vector2(6, -6), Color("f7ddb0"), 2.0)
	if phase == "charge":
		draw_line(-direction * 10, -direction * 23, Color("ffb454"), 3.0)
	if phase == "recovery":
		draw_arc(Vector2(0, -26), 5, 0, PI, 8, Color("ede3c9"), 1.0)
	if state["health"] < profile.health:
		draw_rect(Rect2(-10, -33, 20, 2), Color("101421"))
		draw_rect(Rect2(-10, -33, 20.0 * state["health"] / profile.health, 2), Color("ffb454"))


func _draw_guardian(profile: Resource) -> void:
	var facing: Vector2 = state.get("facing", Vector2.DOWN)
	var tint := Color("728c9c")
	if state["flash"] > 0.0 and not reduced_flashes:
		tint = Color("ffe0a3")
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 15, Color(0.02, 0.03, 0.06, 0.6))
	draw_set_transform(Vector2.ZERO)
	# Broad stone armor and a directional shield, distinct from the pointed charger.
	draw_rect(Rect2(-13, -23, 26, 27), Color("293847"))
	draw_rect(Rect2(-11, -21, 22, 23), tint)
	draw_rect(Rect2(-6, -30, 12, 12), tint)
	draw_line(Vector2(-4, -25), Vector2(4, -25), Color("ffe0a3"), 2)
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
			draw_line(direction * 27, direction * 600, Color(0.95, 0.35, 0.8, 0.55), 1)
	draw_set_transform(Vector2(0, 12), 0.0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 25, Color(0.02, 0.03, 0.06, 0.65))
	draw_set_transform(Vector2.ZERO)
	var body := Color("304858")
	if state.flash > 0.0 and not reduced_flashes:
		body = Color("e0cc9d")
	draw_colored_polygon(PackedVector2Array([Vector2(-22, 7), Vector2(-24, -25), Vector2(-15, -39), Vector2(0, -46), Vector2(15, -39), Vector2(24, -25), Vector2(22, 7), Vector2(0, 17)]), body)
	draw_arc(Vector2(0, -17), 29, -PI * 0.9, -PI * 0.1, 24, gold, 3)
	if second:
		draw_arc(Vector2(0, -17), 33, PI * 0.1, PI * 0.9, 24, gold, 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -39), Vector2(-18, -52), Vector2(-7, -46), Vector2(0, -57), Vector2(7, -46), Vector2(18, -52), Vector2(15, -39)]), gold)
	draw_line(Vector2(-10, -23), Vector2(10, -23), gold, 3)
	draw_polyline(PackedVector2Array([Vector2(-2, -14), Vector2(4, -4), Vector2(-4, 4), Vector2(2, 13)]), gold, 2)
	draw_rect(Rect2(-25, -65, 50, 4), Color("101421"))
	draw_rect(Rect2(-25, -65, 50.0 * state.health / profile.health, 4), gold)
