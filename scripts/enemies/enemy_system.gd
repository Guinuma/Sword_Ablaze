extends RefCounted
## Owns enemy spawning, pursuit, separation and contact queries.
const EnemySettings = preload("res://scripts/data/enemy_settings.gd")
var settings: EnemySettings = load("res://resources/default_enemy.tres")
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
	items.append({"position": point, "health": settings.health, "flash": 0.0, "spawn_time": settings.spawn_warning})


func advance(delta: float, target: Vector2, wave: int, bounds: Rect2) -> void:
	for enemy in items:
		var point: Vector2 = enemy["position"]
		if enemy.get("spawn_time", 0.0) > 0.0:
			enemy["spawn_time"] = maxf(0.0, enemy["spawn_time"] - delta)
			# Never activate on top of a player who moved into the warning.
			if point.distance_to(target) < settings.spawn_safe_distance:
				enemy["spawn_time"] = maxf(0.001, enemy["spawn_time"])
			continue
		enemy["position"] = point.move_toward(target, minf(settings.speed + (wave - 1) * settings.speed_per_wave, settings.max_speed) * delta)
		var knockback: Vector2 = enemy.get("knockback", Vector2.ZERO)
		enemy["position"] += knockback * delta
		enemy["knockback"] = knockback.move_toward(Vector2.ZERO, 600.0 * delta)
		enemy["flash"] = maxf(0.0, enemy["flash"] - delta)
	# Resolve each pair once; a stable fallback separates coincident centers.
	for first in range(items.size()):
		if items[first].get("spawn_time", 0.0) > 0.0:
			continue
		for second in range(first + 1, items.size()):
			if items[second].get("spawn_time", 0.0) > 0.0:
				continue
			var offset: Vector2 = items[second]["position"] - items[first]["position"]
			var distance := offset.length()
			if distance < settings.separation_distance:
				var normal := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(first) * 2.4)
				var push := normal * (settings.separation_distance - distance) * 0.5
				items[first]["position"] -= push
				items[second]["position"] += push
	for enemy in items:
		enemy["position"] = Vector2(enemy["position"]).clamp(bounds.position + Vector2.ONE * settings.body_margin, bounds.end - Vector2.ONE * settings.body_margin)


func touches(point: Vector2) -> bool:
	for enemy in items:
		if enemy.get("spawn_time", 0.0) <= 0.0 and point.distance_to(enemy["position"]) < settings.contact_radius:
			return true
	return false
