extends Node2D
const PROPS = preload("res://assets/art/arena/courtyard-props-02-frames.tres")
var footprint: Rect2
var variant: int = 0
func _draw() -> void:
	var texture := PROPS.get_frame_texture(&"props", variant)
	var width := footprint.size.x + 2
	var dimensions := Vector2(width, round(texture.get_height() * width / texture.get_width()))
	draw_texture_rect(texture, Rect2(Vector2(-width / 2, footprint.size.y / 2 - dimensions.y), dimensions), false)
