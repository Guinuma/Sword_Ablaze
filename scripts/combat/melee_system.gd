extends RefCounted
signal impacted(point: Vector2)
signal defeated(point: Vector2)
signal critical_hit(point: Vector2)
const HitRules = preload("res://scripts/combat/hit_rules.gd")
var settings = load("res://resources/default_melee.tres")
var weapon = load("res://resources/default_weapon.tres")
var fallback_profile = load("res://resources/default_enemy.tres")
var random := RandomNumberGenerator.new()
func _init() -> void:
	random.randomize()
func swing(origin: Vector2, direction: Vector2, enemies: Array[Dictionary]) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		if enemy.get("spawn_time", 0.0) > 0.0:
			continue
		var profile = enemy.get("profile", fallback_profile)
		var offset: Vector2 = enemy.position - origin
		if offset.length() > settings.reach + profile.hit_radius:
			continue
		if offset.length_squared() > 0.001 and direction.normalized().dot(offset.normalized()) < cos(settings.half_angle):
			continue
		var critical: bool = random.randf() < weapon.critical_chance
		var hit_direction := offset.normalized() if offset.length_squared() > 0.001 else direction
		enemy.health -= HitRules.damage(enemy, profile, settings.damage, critical, weapon.critical_multiplier, hit_direction)
		enemy["knockback"] = hit_direction * settings.knockback * profile.knockback_multiplier
		enemy.flash = 0.12
		impacted.emit(enemy.position)
		if critical:
			critical_hit.emit(enemy.position)
		if enemy.health <= 0:
			enemies.remove_at(index)
			defeated.emit(enemy.position)
