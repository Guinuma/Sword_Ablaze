extends RefCounted
## Small prototype tree: six bounded knowledge nodes, three distinct patrons.
const BRANCHES := [
	{"id": "michael", "title": "MICHAEL", "theme": "SWORD ABLAZE / MAIN"},
	{"id": "gabriel", "title": "GABRIEL", "theme": "PRECISION"},
	{"id": "raphael", "title": "RAPHAEL", "theme": "RESTORATION"},
]
const NODES := [
	{"id": "michael_edge", "branch": "michael", "name": "EMBER EDGE", "cost": 1, "requires": "", "effect": "melee_damage", "amount": 1.0, "description": "+1 melee damage"},
	{"id": "michael_reach", "branch": "michael", "name": "FLAME REACH", "cost": 2, "requires": "michael_edge", "effect": "melee_reach", "amount": 6.0, "description": "+6 melee reach"},
	{"id": "gabriel_focus", "branch": "gabriel", "name": "CLEAR SIGHT", "cost": 1, "requires": "", "effect": "projectile_speed", "amount": 0.1, "description": "+10% shot speed"},
	{"id": "gabriel_precision", "branch": "gabriel", "name": "TRUE AIM", "cost": 2, "requires": "gabriel_focus", "effect": "critical_chance", "amount": 0.05, "description": "+5% critical chance"},
	{"id": "raphael_vigor", "branch": "raphael", "name": "LIVING LIGHT", "cost": 1, "requires": "", "effect": "max_health", "amount": 10.0, "description": "+10 maximum HP"},
	{"id": "raphael_step", "branch": "raphael", "name": "RENEWED STEP", "cost": 2, "requires": "raphael_vigor", "effect": "dash_cooldown", "amount": -0.1, "description": "-10% dash cooldown"},
]
static func node(id: String) -> Dictionary:
	for definition in NODES:
		if definition.id == id:
			return definition
	return {}
static func spent(skills: Array) -> int:
	var total := 0
	for id in skills:
		total += int(node(id).get("cost", 0))
	return total
static func bonus(skills: Array, effect: String) -> float:
	var total := 0.0
	for id in skills:
		var definition := node(id)
		if definition.get("effect") == effect:
			total += float(definition.amount)
	return total
