extends RefCounted
## One source of truth for furniture bases, movement and interaction positions.
const BOUNDS := Rect2(60, 100, 520, 215)
const START := Vector2(320, 250)
const RADIUS := 8.0
const REACH := 46.0
const FURNITURE := [
	{"kind": &"bed", "base": Rect2(88, 119, 76, 54)},
	{"kind": &"desk", "base": Rect2(242, 132, 68, 28)},
	{"kind": &"books", "base": Rect2(330, 100, 62, 18)},
	{"kind": &"hearth", "base": Rect2(486, 100, 54, 18)},
	{"kind": &"arsenal", "base": Rect2(100, 233, 66, 22)},
	{"kind": &"gabriel", "base": Rect2(439, 150, 22, 18)},
]
const STATIONS := [
	{"id": &"gabriel", "point": Vector2(450, 185), "label": "GABRIEL", "action": "Speak with Gabriel"},
	{"id": &"arsenal", "point": Vector2(133, 276), "label": "ARSENAL", "action": "Choose your weapon"},
	{"id": &"door", "point": Vector2(320, 294), "label": "DEPARTURE", "action": "Leave Sanctuary"},
]
static func geometry() -> RefCounted:
	var result = load("res://scripts/combat/arena_geometry.gd").new()
	result.obstacles.clear()
	for item in FURNITURE:
		result.obstacles.append(item.base)
	return result
static func nearest(point: Vector2, world: RefCounted) -> Dictionary:
	var best: Dictionary = {}
	var distance := REACH
	for station in STATIONS:
		var candidate: float = point.distance_to(station.point)
		if candidate <= distance and is_inf(world.segment_hit(point, station.point)):
			best = station
			distance = candidate
	return best
