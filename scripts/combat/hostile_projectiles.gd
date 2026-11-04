extends RefCounted
## Hostile shots are bounded and use swept collision against the player.
signal hit_player(damage: int)
const MAX_PROJECTILES: int = 64
var geometry: RefCounted
var items: Array[Dictionary] = []


func fire(origin: Vector2, direction: Vector2, speed: float, damage: int = 50) -> void:
	if items.size() < MAX_PROJECTILES:
		items.append({"position": origin, "direction": direction, "speed": speed, "life": 5.0, "damage": damage})


func clear() -> void:
	items.clear()


func advance(delta: float, player_position: Vector2, bounds: Rect2) -> void:
	for index in range(items.size() - 1, -1, -1):
		var bullet: Dictionary = items[index]
		var start: Vector2 = bullet["position"]
		var end: Vector2 = start + Vector2(bullet["direction"]) * bullet["speed"] * minf(delta, bullet["life"])
		bullet["life"] -= delta
		var wall_hit: float = geometry.segment_hit(start, end) if geometry != null else INF
		var player_hit: float = 0.0 if start.distance_to(player_position) <= 11.0 else Geometry2D.segment_intersects_circle(start, end, player_position, 11.0)
		if not is_inf(wall_hit) and (player_hit < 0.0 or wall_hit <= player_hit):
			items.remove_at(index)
		elif start.distance_to(player_position) <= 11.0 or Geometry2D.segment_intersects_circle(start, end, player_position, 11.0) >= 0.0:
			items.remove_at(index)
			hit_player.emit(bullet.get("damage", 50))
		elif bullet["life"] <= 0.0 or not bounds.has_point(end):
			items.remove_at(index)
		else:
			bullet["position"] = end
