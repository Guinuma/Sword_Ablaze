extends RefCounted
## Owns enemy spawning, pursuit, separation and contact queries.
const HEALTH: int = 2
const SPEED: float = 46.0
var items: Array[Dictionary] = []


func clear() -> void:
	items.clear()


func spawn(target: Vector2, bounds: Rect2, random: RandomNumberGenerator) -> void:
	var point: Vector2
	# Spawn on the opposite half of the perimeter, away from the player.
	if random.randf() < 0.5:
		var x := bounds.position.x + 10.0 if target.x > bounds.get_center().x else bounds.end.x - 10.0
		point = Vector2(x, random.randf_range(bounds.position.y + 10.0, bounds.end.y - 10.0))
	else:
		var y := bounds.position.y + 10.0 if target.y > bounds.get_center().y else bounds.end.y - 10.0
		point = Vector2(random.randf_range(bounds.position.x + 10.0, bounds.end.x - 10.0), y)
	items.append({"position": point, "health": HEALTH, "flash": 0.0})


func advance(delta: float, target: Vector2, wave: int, bounds: Rect2) -> void:
	for enemy in items:
		var point: Vector2 = enemy["position"]
		enemy["position"] = point.move_toward(target, minf(SPEED + (wave - 1) * 3.0, 90.0) * delta)
		var knockback: Vector2 = enemy.get("knockback", Vector2.ZERO)
		enemy["position"] += knockback * delta
		enemy["knockback"] = knockback.move_toward(Vector2.ZERO, 600.0 * delta)
		enemy["flash"] = maxf(0.0, enemy["flash"] - delta)
	# Resolve each pair once; a stable fallback separates coincident centers.
	for first in range(items.size()):
		for second in range(first + 1, items.size()):
			var offset: Vector2 = items[second]["position"] - items[first]["position"]
			var distance := offset.length()
			if distance < 18.0:
				var normal := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(first) * 2.4)
				var push := normal * (18.0 - distance) * 0.5
				items[first]["position"] -= push
				items[second]["position"] += push
	for enemy in items:
		enemy["position"] = Vector2(enemy["position"]).clamp(bounds.position + Vector2(8, 8), bounds.end - Vector2(8, 8))


func touches(point: Vector2) -> bool:
	for enemy in items:
		if point.distance_to(enemy["position"]) < 15.0:
			return true
	return false
