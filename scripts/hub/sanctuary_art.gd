extends Node2D
## Original code-authored pixel furnishings and Gabriel; shared actor ground pivots.
var kind: StringName = &"bed"
const GABRIEL = preload("res://assets/art/hub/gabriel-01-frames.tres")
const GOLD := Color("bfa16c")
const LIGHT := Color("e5dfc9")
const WOOD := Color("5f4539")
const DARK := Color("282d37")
func block(x: float, y: float, w: float, h: float, tint: Color) -> void:
	draw_rect(Rect2(x, y, w, h), tint)
func _draw() -> void:
	match kind:
		&"bed":
			block(-40, -30, 80, 58, Color(0, 0, 0, 0.24))
			block(-38, -45, 76, 68, WOOD)
			block(-34, -42, 68, 57, Color("b6a48b"))
			block(-31, -35, 27, 16, LIGHT)
			block(2, -35, 27, 16, LIGHT)
			block(-33, -16, 66, 31, Color("3c7478"))
			block(-29, -12, 58, 3, Color("76a6a0"))
			block(-33, 10, 66, 4, GOLD)
			for x in [-38, 34]:
				block(x, -48, 4, 73, Color("8c6d4d"))
				block(x, -49, 4, 3, GOLD)
		&"desk":
			block(-36, -17, 72, 39, Color(0, 0, 0, 0.22))
			block(-34, -30, 68, 36, WOOD)
			block(-34, -30, 68, 4, Color("a07d54"))
			block(-29, 6, 6, 10, DARK)
			block(23, 6, 6, 10, DARK)
			block(-22, -23, 32, 20, LIGHT)
			block(-8, -23, 2, 20, Color("9e947b"))
			for y in [-18, -14, -10]:
				block(-19, y, 8, 1, Color("8a806b"))
				block(-3, y, 9, 1, Color("8a806b"))
			block(22, -23, 6, 12, GOLD)
			block(24, -32, 2, 10, LIGHT)
			block(24, -35, 2, 3, Color("f6bb67"))
		&"books":
			block(-31, -48, 62, 55, WOOD)
			for y in [-43, -23]:
				block(-27, y, 54, 16, DARK)
				for i in range(10):
					var tint: Color = [Color("6c8d8a"), Color("ae9565"), Color("995f59")][i % 3]
					block(-25 + i * 5, y + (i % 3), 4, 14 - (i % 3), tint)
				block(-30, y + 16, 60, 3, Color("ae875a"))
		&"hearth":
			block(-27, -55, 54, 62, Color("777064"))
			block(-23, -49, 46, 46, Color("45454a"))
			block(-17, -40, 34, 36, Color("181e2a"))
			block(-30, -55, 60, 6, GOLD)
			block(-30, 1, 60, 8, Color("a08d71"))
			block(-14, -8, 28, 4, WOOD)
			for i in range(5):
				block(-12 + i * 5, -14 - (i % 2) * 7, 4, 16 + (i % 2) * 7, Color("bb683d"))
				block(-11 + i * 5, -8 - (i % 2) * 4, 2, 8, Color("eabd6c"))
		&"arsenal":
			block(-33, -48, 66, 56, WOOD)
			block(-29, -44, 58, 45, DARK)
			for x in [-25, 21]:
				block(x, -48, 4, 58, GOLD)
			for x in [-15, 9]:
				block(x, -39, 4, 24, LIGHT)
				block(x - 4, -15, 12, 3, GOLD)
				block(x + 1, -12, 2, 10, Color("72908e"))
			block(-22, -2, 44, 4, GOLD)
		&"gabriel":
			draw_set_transform(Vector2(0, 7), 0, Vector2(1, 0.35))
			draw_circle(Vector2.ZERO, 14, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO)
			var sprite: Texture2D = GABRIEL.get_frame_texture(&"idle", 0)
			var size := Vector2(round(sprite.get_width() * 42.0 / sprite.get_height()), 42)
			draw_texture_rect(sprite, Rect2(Vector2(-size.x / 2, 7 - size.y).round(), size), false)
