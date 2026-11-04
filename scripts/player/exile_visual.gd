extends Node2D
## Native-grid Exile sprites, pixel cape and independently aimed ember blade.
signal defeat_finished
const NATIVE = preload("res://assets/art/player/exile-native.svg")
const WALK = preload("res://assets/art/player/exile-native-walk.tres")
const DEFEAT_DURATION: float = 0.64
var defeated: bool = false
var defeat_done: bool = false
var defeat_time: float = 0.0
const PlayerState = preload("res://scripts/player/player_state.gd")
var melee_time: float = 0.0
var dash_clock: float = 0.0
var hurt_clock: float = 0.0
var body_direction: StringName = &"side"
var walk_clock: float = 0.0
var walk_frame: int = 0
var walk_rate: float = 8.0
var facing := Vector2.RIGHT
var travel := Vector2.ZERO
var clock: float = 0.0
var dashing: bool = false
var hurt: bool = false
var firing: bool = false
var reduced_flashes: bool = false
var reduced_motion: bool = false
var cape_tip := Vector2(-10, 3)

func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	advance_defeat(delta)


func begin_defeat() -> void:
	defeated = true
	defeat_done = false
	defeat_time = 0.0
	set_process(true)
	queue_redraw()


func advance_defeat(delta: float) -> void:
	if not defeated or defeat_done:
		return
	defeat_time = minf(DEFEAT_DURATION, defeat_time + delta)
	queue_redraw()
	if defeat_time >= DEFEAT_DURATION:
		defeat_done = true
		set_process(false)
		defeat_finished.emit()


func present(point: Vector2, aim: Vector2, movement: Vector2, delta: float, dash: bool, damaged: bool, shot: bool, melee: float = 0.0) -> void:
	position = point.round()
	facing = aim
	# A small threshold gap avoids flickering between views near diagonals.
	var vertical_threshold: float = 1.25 if body_direction == &"side" else 1.05
	if absf(aim.y) > absf(aim.x) * vertical_threshold:
		body_direction = &"back" if aim.y < 0.0 else &"front"
	elif absf(aim.x) > absf(aim.y) * 1.05:
		body_direction = &"side"
	travel = movement
	dash_clock = dash_clock + delta if dash and dashing else 0.0
	hurt_clock = hurt_clock + delta if damaged and hurt else 0.0
	dashing = dash
	hurt = damaged
	firing = shot
	melee_time = melee
	clock += delta
	if movement.length_squared() > 0.01 and not dash:
		walk_clock += delta * (-1.0 if movement.dot(aim) < -0.1 else 1.0)
		walk_frame = posmod(int(floor(walk_clock * walk_rate)), 4)
	else:
		walk_clock = 0.0
		walk_frame = 0
	var trailing := -movement.normalized() if movement.length_squared() > 0.01 else Vector2(-signf(aim.x) if absf(aim.x) > 0.1 else -1.0, 0.2)
	var length := 16.0 if dash and not reduced_motion else 10.0
	var target := trailing * length + Vector2(0, 1 + (0.0 if reduced_motion else sin(clock * 9.0)))
	target.y = minf(target.y, 12.0 if dash else 8.0)
	cape_tip = target if reduced_motion else cape_tip.lerp(target, 1.0 - exp(-14.0 * delta))
	queue_redraw()

func reset_pose() -> void:
	melee_time = 0.0
	dash_clock = 0.0
	hurt_clock = 0.0
	dashing = false
	hurt = false
	firing = false
	defeated = false
	defeat_done = false
	defeat_time = 0.0
	set_process(false)
	clock = 0.0
	body_direction = &"side"
	walk_clock = 0.0
	walk_frame = 0
	cape_tip = Vector2(-10, 3)
	travel = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if defeated:
		_draw_defeat()
		return
	draw_ellipse_shadow()
	var bob := -1.0 if travel.length_squared() > 0.01 and walk_frame in [1, 3] and not reduced_motion else 0.0
	var neck := Vector2(0, -9 + bob)
	_draw_pixel_cape(neck, cape_tip.round())
	if facing.y < -0.6:
		_draw_weapon(bob)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if body_direction == &"side" and facing.x < 0.0 else 1.0, 1.0))
	var row := 0 if body_direction == &"front" else 1 if body_direction == &"back" else 2
	draw_texture_rect_region(NATIVE, Rect2(-12, -20, 24, 32), Rect2(sprite_frame() * 24, row * 32, 24, 32))
	draw_set_transform(Vector2.ZERO)
	if facing.y >= -0.6:
		_draw_weapon(bob)


func sprite_frame() -> int:
	if dashing:
		return 5 + mini(1, int(dash_clock / 0.07))
	if hurt and hurt_clock < 0.18:
		return 7 + mini(1, int(hurt_clock / 0.09))
	return 1 + walk_frame if travel.length_squared() > 0.01 else 0


func _draw_pixel_cape(neck: Vector2, tip: Vector2) -> void:
	var polygon := cape_polygon(neck, tip)
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	for y in range(int(floor(bounds.position.y)), int(ceil(bounds.end.y)) + 1):
		var start := 100
		var end := -100
		for x in range(int(floor(bounds.position.x)), int(ceil(bounds.end.x)) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				start = mini(start, x)
				end = maxi(end, x)
		if end >= start:
			draw_rect(Rect2(start, y, end - start + 1, 1), Color("176578"))
			draw_rect(Rect2(start, y, mini(2, end - start + 1), 1), Color("23858d"))


func _draw_weapon(bob: float) -> void:
	# Upward aim places the weapon behind the body at the right-hand grip.
	var grip := PlayerState.weapon_grip(facing) + Vector2(0, bob)
	var recoil := -2.0 if firing and not reduced_motion else 0.0
	var angle := facing.angle()
	if melee_time > 0.0 and not reduced_motion:
		angle += lerpf(-0.65, 0.65, 1.0 - melee_time / 0.16)
	var mount := (grip + facing * recoil).round()
	var side := -1.0 if facing.x < 0.0 else 1.0
	var trigger_hand := (mount + Vector2(5, 2).rotated(angle)).round()
	var support_hand := (mount + Vector2(10, 1).rotated(angle)).round()
	draw_line(Vector2(side * 5, -8 + bob), trigger_hand, Color("176578"), 3)
	draw_line(Vector2(-side * 4, -7 + bob), support_hand, Color("23858d"), 2)
	draw_set_transform(mount, angle)
	draw_rect(Rect2(3, -2, 12, 4), Color("263747"))
	draw_rect(Rect2(5, -2, 7, 1), Color("b88d4d"))
	draw_line(Vector2(13, 1), Vector2(21, 1), Color("fff3da"), 2.0)
	draw_line(Vector2(15, 2), Vector2(21, 1), Color("ed874b"), 1.0)
	draw_rect(Rect2(4, 1, 2, 2), Color("eee5cb"))
	draw_rect(Rect2(9, 0, 2, 2), Color("eee5cb"))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow() -> void:
	# Stepped silhouette stays on the same one-logical-pixel grid as the boots.
	draw_rect(Rect2(-7, 6, 14, 3), Color(0.06, 0.11, 0.16, 0.5))
	draw_rect(Rect2(-10, 7, 20, 1), Color(0.06, 0.11, 0.16, 0.5))


func _draw_defeat() -> void:
	draw_ellipse_shadow()
	var frame := mini(3, int(defeat_time * 8.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if facing.x < 0.0 else 1.0, 1.0))
	draw_texture_rect_region(NATIVE, Rect2(-12, -20, 24, 32), Rect2(frame * 24, 96, 24, 32))
	draw_set_transform(Vector2.ZERO)


static func cape_polygon(neck: Vector2, tip: Vector2) -> PackedVector2Array:
	# A convex strip cannot fold over itself when the cape crosses the shoulders.
	if neck.distance_squared_to(tip) < 4.0:
		tip = neck + Vector2(0, 3)
	var side := neck.direction_to(tip).orthogonal()
	return PackedVector2Array([neck + side * 4, neck - side * 4, tip - side * 3, tip + side * 3])
