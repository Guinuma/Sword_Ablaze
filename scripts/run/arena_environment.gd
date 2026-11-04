extends RefCounted
const FLOOR = preload("res://assets/art/arena/courtyard-floor-02.svg")
const EDGE = preload("res://assets/art/arena/courtyard-edge-02.svg")
const RuinVisual = preload("res://scripts/enemies/ruin_visual.gd")
static func populate(world: Node2D, obstacles: Array[Rect2]) -> void:
	for index in range(obstacles.size()):
		var footprint := obstacles[index]
		var ruin := RuinVisual.new()
		ruin.footprint = footprint
		ruin.variant = [0, 2, 1, 3][index % 4]
		ruin.position = footprint.get_center()
		world.add_child(ruin)
static func draw_floor(canvas: Node2D, bounds: Rect2, obstacles: Array[Rect2]) -> void:
	# Repair patches blend reusable masonry into the retained illustrated courtyard.
	for index in range(obstacles.size()):
		var center := obstacles[index].get_center()
		var origin := (center / 32.0).floor() * 32 - Vector2(32, 32)
		for y in range(2):
			for x in range(2):
				canvas.draw_texture_rect_region(FLOOR, Rect2(origin + Vector2(x, y) * 32, Vector2(32, 32)), Rect2(((index + x + y) % 4) * 32, 0, 32, 32), Color(1, 1, 1, 0.25))
	# Identical edge profiles tile without gaps, including fractional last tiles.
	for pair in [[bounds.position, 0.0, bounds.size.x], [Vector2(bounds.end.x, bounds.position.y), PI / 2, bounds.size.y], [bounds.end, PI, bounds.size.x], [Vector2(bounds.position.x, bounds.end.y), -PI / 2, bounds.size.y]]:
		canvas.draw_set_transform(pair[0], pair[1])
		var length: float = pair[2]
		for step in range(int(ceil(length / 32.0))):
			var width := minf(32.0, length - step * 32.0)
			canvas.draw_texture_rect_region(EDGE, Rect2(step * 32, 0, width, 8), Rect2(0, 0, width, 8))
	canvas.draw_set_transform(Vector2.ZERO)
