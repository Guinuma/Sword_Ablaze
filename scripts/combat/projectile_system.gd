extends RefCounted
## Simulation advances only when the arena supplies active combat time.
signal impacted(point: Vector2)
signal defeated(point: Vector2)

const WeaponSettings = preload("res://scripts/data/weapon_settings.gd")
var weapon: WeaponSettings = load("res://resources/default_weapon.tres")
const EnemySettings = preload("res://scripts/data/enemy_settings.gd")
var enemy_settings: EnemySettings = load("res://resources/default_enemy.tres")
var items: Array[Dictionary] = []


func fire(origin: Vector2, direction: Vector2) -> void:
	items.append({"position": origin, "direction": direction})


func clear() -> void:
	items.clear()


func advance(delta: float, enemies: Array[Dictionary], bounds: Rect2) -> void:
	for index in range(items.size() - 1, -1, -1):
		var start: Vector2 = items[index]["position"]
		var end: Vector2 = start + Vector2(items[index]["direction"]) * weapon.projectile_speed * delta
		# Segment collision prevents fast bullets from skipping through enemies.
		var target: int = -1
		var nearest: float = INF
		for enemy_index in range(enemies.size()):
			if enemies[enemy_index].get("spawn_time", 0.0) > 0.0:
				continue
			var point: Vector2 = enemies[enemy_index]["position"]
			var hit := Geometry2D.segment_intersects_circle(start, end, point, enemy_settings.hit_radius)
			if hit >= 0.0 and hit < nearest:
				target = enemy_index
				nearest = hit
		if target >= 0:
			var impact: Vector2 = enemies[target]["position"]
			enemies[target]["knockback"] = Vector2(items[index]["direction"]) * weapon.knockback
			impacted.emit(impact)
			enemies[target]["health"] -= weapon.damage
			enemies[target]["flash"] = 0.12
			if enemies[target]["health"] <= 0:
				enemies.remove_at(target)
				defeated.emit(impact)
			items.remove_at(index)
		elif not bounds.has_point(end):
			items.remove_at(index)
		else:
			items[index]["position"] = end
