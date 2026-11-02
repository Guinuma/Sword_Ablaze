extends Node2D
## Layered prototype: generated body, responsive cape and independently aimed weapon.
const BODY = preload("res://assets/art/player/exile-body-01.png")
const WALK = preload("res://assets/art/player/exile-walk-01-frames.tres")
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
var cape_tip := Vector2(-12, 5)

func present(point: Vector2, aim: Vector2, movement: Vector2, delta: float, dash: bool, damaged: bool, shot: bool) -> void:
	position = point.round()
	facing = aim
	travel = movement
	dashing = dash
	hurt = damaged
	firing = shot
	clock += delta
	if movement.length_squared() > 0.01 and not dash:
		walk_clock += delta
		walk_frame = int(walk_clock * walk_rate) % 4
	else:
		walk_clock = 0.0
		walk_frame = 0
	var trailing := -movement.normalized() if movement.length_squared() > 0.01 else Vector2(-signf(aim.x) if absf(aim.x) > 0.1 else -1.0, 0.2)
	var length := 20.0 if dash and not reduced_motion else 12.0
	var target := trailing * length + Vector2(0, 4 + (0.0 if reduced_motion else sin(clock * 9.0) * 1.5))
	cape_tip = target if reduced_motion else cape_tip.lerp(target, 1.0 - exp(-14.0 * delta))
	queue_redraw()

func reset_pose() -> void:
	clock = 0.0
	walk_clock = 0.0
	walk_frame = 0
	cape_tip = Vector2(-12, 5)
	travel = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	draw_ellipse_shadow()
	var bob := roundf(sin(clock * 16.0)) if travel.length_squared() > 0.01 and not reduced_motion else 0.0
	var neck := Vector2(0, -5 + bob)
	var tip := cape_tip.round()
	draw_colored_polygon(PackedVector2Array([neck + Vector2(-4, 0), neck + Vector2(4, 0), tip + Vector2(4, 3), tip + Vector2(0, 1), tip + Vector2(-4, 4)]), Color("176578"))
	draw_line(neck, tip + Vector2(0, 2), Color("2ca6ad"), 3.0)
	var tint := Color("fff0b0") if (hurt or dashing) and not reduced_flashes else Color.WHITE
	var body_rect := Rect2(Vector2(-18, -23 + bob), Vector2(36, 36))
	# Mirror around the shared origin; negative Rect2 sizes shift the image.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if facing.x < 0.0 else 1.0, 1.0))
	if travel.length_squared() > 0.01 and not dashing:
		draw_texture_rect(WALK.get_frame_texture(&"walk", walk_frame), Rect2(-12, -24 + bob, 24, 35), false, tint)
	else:
		draw_texture_rect(BODY, body_rect, false, tint)
	draw_set_transform(Vector2.ZERO)
	# Rotate only the weapon, preserving the body's upright silhouette.
	var grip := Vector2(0, -2 + bob)
	var recoil := -2.0 if firing and not reduced_motion else 0.0
	draw_set_transform(grip + facing * recoil, facing.angle())
	draw_rect(Rect2(3, -2, 12, 4), Color("28313b"))
	draw_rect(Rect2(5, -2, 7, 1), Color("b88d4d"))
	draw_line(Vector2(13, 1), Vector2(21, 1), Color("ffe3a3"), 2.0)
	draw_line(Vector2(15, 2), Vector2(21, 1), Color("ff7b38"), 1.0)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.03, 0.06, 0.45))
	draw_set_transform(Vector2.ZERO)
