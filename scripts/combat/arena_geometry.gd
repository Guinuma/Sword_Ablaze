extends RefCounted
## Shared authored collision footprints and visibility-graph navigation.
const DEFAULT_OBSTACLES: Array[Rect2] = [Rect2(138, 132, 24, 18), Rect2(476, 248, 24, 18), Rect2(124, 260, 40, 14), Rect2(476, 132, 40, 14)]
var obstacles: Array[Rect2] = DEFAULT_OBSTACLES.duplicate()
var graphs: Dictionary = {}

func segment_hit(start: Vector2, end: Vector2, radius: float = 0.0) -> float:
	var nearest := INF
	for footprint in obstacles:
		var box := footprint.grow(radius)
		var low := 0.0
		var high := 1.0
		var delta := end - start
		var possible := true
		for axis in range(2):
			if absf(delta[axis]) < 0.00001:
				if start[axis] < box.position[axis] or start[axis] > box.end[axis]:
					possible = false
			else:
				var first: float = (box.position[axis] - start[axis]) / delta[axis]
				var last: float = (box.end[axis] - start[axis]) / delta[axis]
				low = maxf(low, minf(first, last))
				high = minf(high, maxf(first, last))
		if possible and low <= high and high >= 0.0 and low <= 1.0:
			nearest = minf(nearest, maxf(0.0, low))
	return nearest

func clear_point(point: Vector2, radius: float) -> Vector2:
	var result := point
	for footprint in obstacles:
		var box := footprint.grow(radius + 0.05)
		if box.has_point(result):
			var candidates := [Vector2(box.position.x, result.y), Vector2(box.end.x, result.y), Vector2(result.x, box.position.y), Vector2(result.x, box.end.y)]
			var best := INF
			for candidate in candidates:
				var distance: float = result.distance_squared_to(candidate)
				if distance < best:
					best = distance
					point = candidate
			result = point
	return result

func _clip(start: Vector2, end: Vector2, radius: float) -> Vector2:
	var fraction := segment_hit(start, end, radius)
	return end if is_inf(fraction) else start.lerp(end, maxf(0.0, fraction - 0.001 / maxf(1.0, start.distance_to(end))))

func move_actor(start: Vector2, end: Vector2, radius: float, slide: bool = true) -> Vector2:
	start = clear_point(start, radius)
	var result := _clip(start, end, radius)
	if slide and not result.is_equal_approx(end):
		result = _clip(result, Vector2(end.x, result.y), radius)
		result = _clip(result, Vector2(result.x, end.y), radius)
	return result

func waypoint(start: Vector2, target: Vector2, radius: float) -> Vector2:
	if is_inf(segment_hit(start, target, radius)):
		return target
	var key := int(ceil(radius))
	if not graphs.has(key):
		var graph := AStar2D.new()
		var corners: Array[Vector2] = []
		for footprint in obstacles:
			var box := footprint.grow(key + 1.0)
			corners.append_array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])
		for index in range(corners.size()):
			graph.add_point(index, corners[index])
		for first in range(corners.size()):
			for second in range(first + 1, corners.size()):
				if is_inf(segment_hit(corners[first], corners[second], key)):
					graph.connect_points(first, second)
		graphs[key] = graph
	var graph: AStar2D = graphs[key]
	start = clear_point(start, key)
	target = clear_point(target, key)
	graph.add_point(1000, start)
	graph.add_point(1001, target)
	for index in range(obstacles.size() * 4):
		var corner := graph.get_point_position(index)
		if is_inf(segment_hit(start, corner, key)):
			graph.connect_points(1000, index)
		if is_inf(segment_hit(target, corner, key)):
			graph.connect_points(1001, index)
	var path := graph.get_point_path(1000, 1001)
	graph.remove_point(1000)
	graph.remove_point(1001)
	return path[1] if path.size() > 1 else start
