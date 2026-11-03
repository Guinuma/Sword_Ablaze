extends RefCounted
## Owns enemy spawning, pursuit, separation and contact queries.
signal shot(origin: Vector2, direction: Vector2, speed: float, damage: int)

const EnemySettings = preload("res://scripts/data/enemy_settings.gd")
var settings: EnemySettings = load("res://resources/default_enemy.tres")
var ranged_settings: EnemySettings = load("res://resources/default_ranged.tres")
var items: Array[Dictionary] = []


func clear() -> void:
	items.clear()


func spawn(target: Vector2, bounds: Rect2, random: RandomNumberGenerator, kind: StringName = &"chaser") -> void:
	var point: Vector2
	# Spawn on the opposite half of the perimeter, away from the player.
	if random.randf() < 0.5:
		var x := bounds.position.x + 10.0 if target.x > bounds.get_center().x else bounds.end.x - 10.0
		point = Vector2(x, random.randf_range(bounds.position.y + 10.0, bounds.end.y - 10.0))
	else:
		var y := bounds.position.y + 10.0 if target.y > bounds.get_center().y else bounds.end.y - 10.0
		point = Vector2(random.randf_range(bounds.position.x + 10.0, bounds.end.x - 10.0), y)
	var profile: EnemySettings = ranged_settings if kind == &"ranged" else settings
	items.append({"position": point, "health": profile.health, "flash": 0.0, "spawn_time": profile.spawn_warning, "profile": profile, "attack_cooldown": profile.attack_cooldown, "windup": 0.0})


func advance(delta: float, target: Vector2, wave: int, bounds: Rect2) -> void:
	for enemy in items:
		var profile: EnemySettings = enemy.get("profile", settings)
		var point: Vector2 = enemy["position"]
		if enemy.get("spawn_time", 0.0) > 0.0:
			enemy["spawn_time"] = maxf(0.0, enemy["spawn_time"] - delta)
			# Never activate on top of a player who moved into the warning.
			if point.distance_to(target) < profile.spawn_safe_distance:
				enemy["spawn_time"] = maxf(0.001, enemy["spawn_time"])
			continue
		var speed: float = minf(profile.speed + (wave - 1) * profile.speed_per_wave, profile.max_speed)
		if profile.kind == "ranged":
			_advance_ranged(enemy, target, delta, speed, profile)
		else:
			enemy["position"] = point.move_toward(target, speed * delta)
		var knockback: Vector2 = enemy.get("knockback", Vector2.ZERO)
		enemy["position"] += knockback * delta
		enemy["knockback"] = knockback.move_toward(Vector2.ZERO, 600.0 * delta)
		enemy["flash"] = maxf(0.0, enemy["flash"] - delta)
	for enemy in items:
		enemy["position"] = _clamp_enemy(enemy, enemy["position"], bounds)
	# A few bounded passes reduce crowd overlap without an unbounded solver.
	for pass_index in range(6):
		if _resolve_separation(bounds) < 0.05:
			break


func _clamp_enemy(enemy: Dictionary, point: Vector2, bounds: Rect2) -> Vector2:
	var profile: EnemySettings = enemy.get("profile", settings)
	var margin := Vector2.ONE * profile.body_margin
	return point.clamp(bounds.position + margin, bounds.end - margin)


func _resolve_separation(bounds: Rect2) -> float:
	var maximum_overlap: float = 0.0
	for first in range(items.size()):
		if items[first].get("spawn_time", 0.0) > 0.0:
			continue
		for second in range(first + 1, items.size()):
			if items[second].get("spawn_time", 0.0) > 0.0:
				continue
			var first_profile: EnemySettings = items[first].get("profile", settings)
			var second_profile: EnemySettings = items[second].get("profile", settings)
			var separation: float = (first_profile.separation_distance + second_profile.separation_distance) * 0.5
			var offset: Vector2 = items[second]["position"] - items[first]["position"]
			var distance := offset.length()
			if distance >= separation:
				continue
			maximum_overlap = maxf(maximum_overlap, separation - distance)
			var normal := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(first) * 2.4)
			var push := normal * (separation - distance) * 0.5
			var a := _clamp_enemy(items[first], items[first]["position"] - push, bounds)
			var b := _clamp_enemy(items[second], items[second]["position"] + push, bounds)
			# Give the movable enemy the displacement blocked by a wall.
			var remaining := maxf(0.0, separation - (b - a).dot(normal))
			b = _clamp_enemy(items[second], b + normal * remaining, bounds)
			remaining = maxf(0.0, separation - (b - a).dot(normal))
			a = _clamp_enemy(items[first], a - normal * remaining, bounds)
			items[first]["position"] = a
			items[second]["position"] = b
	return maximum_overlap



func touches(point: Vector2) -> bool:
	for enemy in items:
		var profile: EnemySettings = enemy.get("profile", settings)
		if enemy.get("spawn_time", 0.0) <= 0.0 and point.distance_to(enemy["position"]) < profile.contact_radius:
			return true
	return false


func _advance_ranged(enemy: Dictionary, target: Vector2, delta: float, speed: float, profile: EnemySettings) -> void:
	var point: Vector2 = enemy["position"]
	if enemy.get("windup", 0.0) > 0.0:
		enemy["windup"] = maxf(0.0, enemy["windup"] - delta)
		if enemy["windup"] == 0.0:
			var direction: Vector2 = enemy["shot_direction"]
			shot.emit(point + direction * 14.0, direction, profile.projectile_speed, profile.projectile_damage)
			enemy["attack_cooldown"] = profile.attack_cooldown
		return
	var distance := point.distance_to(target)
	if distance > profile.preferred_distance + 15.0:
		enemy["position"] = point.move_toward(target, speed * delta)
	elif distance < profile.preferred_distance - 15.0:
		enemy["position"] = point + (point - target).normalized() * speed * delta
	enemy["attack_cooldown"] = maxf(0.0, enemy.get("attack_cooldown", profile.attack_cooldown) - delta)
	if enemy["attack_cooldown"] == 0.0 and distance <= profile.attack_range:
		enemy["shot_direction"] = point.direction_to(target)
		enemy["windup"] = profile.attack_warning
