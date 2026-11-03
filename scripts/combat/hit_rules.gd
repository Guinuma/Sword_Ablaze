extends RefCounted
## Shared armor/critical order for bullets and melee.
static func damage(enemy: Dictionary, profile: Resource, base: int, critical: bool, multiplier: float, direction: Vector2) -> int:
	var result := maxi(1, int(round(base * multiplier))) if critical else base
	if profile.kind == "guardian":
		var facing: Vector2 = enemy.get("facing", Vector2.DOWN)
		var frontal := facing.dot(-direction.normalized()) >= 0.5
		result = maxi(1, int(ceil(result * 0.5))) if frontal else result * 2
	return result
