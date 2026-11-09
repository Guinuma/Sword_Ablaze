extends RefCounted
## Patron regions and persistent skill definitions.
const BRANCHES := [
	{"id": "michael", "title": "MICHAEL", "color": Color("d87536"), "center": Vector2(62, 42)},
	{"id": "gabriel", "title": "GABRIEL", "color": Color("d5b479"), "center": Vector2(180, 42)},
	{"id": "raphael", "title": "RAPHAEL", "color": Color("4aa598"), "center": Vector2(62, 122)},
	{"id": "joan", "title": "JOAN OF ARC", "color": Color("bc5265"), "center": Vector2(180, 122)},
]
const NODES := [
	{"id": "michael_edge", "branch": "michael", "name": "EMBER EDGE", "cost": 1, "requires": "", "effect": "melee_damage", "amount": 1.0, "description": "+1 melee damage"},
	{"id": "michael_reach", "branch": "michael", "name": "FLAME REACH", "cost": 2, "requires": "michael_edge", "effect": "melee_reach", "amount": 6.0, "description": "+6 melee reach"},
	{"id": "gabriel_focus", "branch": "gabriel", "name": "CLEAR SIGHT", "cost": 1, "requires": "", "effect": "projectile_speed", "amount": 0.1, "description": "+10% shot speed"},
	{"id": "gabriel_precision", "branch": "gabriel", "name": "TRUE AIM", "cost": 2, "requires": "gabriel_focus", "effect": "critical_chance", "amount": 0.05, "description": "+5% critical chance"},
	{"id": "raphael_vigor", "branch": "raphael", "name": "LIVING LIGHT", "cost": 1, "requires": "", "effect": "max_health", "amount": 10.0, "description": "+10 maximum HP"},
	{"id": "raphael_step", "branch": "raphael", "name": "RENEWED STEP", "cost": 2, "requires": "raphael_vigor", "effect": "dash_cooldown", "amount": -0.1, "description": "-10% dash cooldown"},
	{"id": "joan_standard", "branch": "joan", "name": "RALLYING STANDARD", "cost": 1, "requires": "michael_edge", "effect": "move_speed", "amount": 0.05, "description": "+5% move speed"},
	{"id": "joan_stand", "branch": "joan", "name": "UNBROKEN STAND", "cost": 2, "requires": "joan_standard", "effect": "melee_knockback", "amount": 30.0, "description": "+30 melee knockback"},
	{"id": "michael_ember", "branch": "michael", "name": "LIVING EMBER", "cost": 1, "requires": "michael_edge", "effect": "fire", "amount": 1.0, "description": "FIRE: Two Sword Ablaze hits ignite an enemy."},
	{"id": "michael_pyre", "branch": "michael", "name": "PYRE", "cost": 1, "requires": "michael_ember", "effect": "pyre", "amount": 1.0, "description": "Burning enemies spread fire on defeat."},
	{"id": "joan_break", "branch": "joan", "name": "GUARD BREAK", "cost": 1, "requires": "joan_standard", "effect": "impact", "amount": 1.0, "description": "IMPACT: Heavy melee hits build stagger."},
	{"id": "joan_counter", "branch": "joan", "name": "COUNTERCHARGE", "cost": 1, "requires": "joan_break", "effect": "countercharge", "amount": 1.0, "description": "First heavy hit after a dash adds extra Impact."},
	{"id": "gabriel_seal", "branch": "gabriel", "name": "LUMINOUS SEAL", "cost": 1, "requires": "gabriel_precision", "effect": "light", "amount": 1.0, "description": "LIGHT: Three shots on one target mark it."},
	{"id": "gabriel_verdict", "branch": "gabriel", "name": "VERDICT", "cost": 1, "requires": "gabriel_seal", "effect": "verdict", "amount": 1.0, "description": "Melee consumes Light marks for +3 damage."},
	{"id": "raphael_grace", "branch": "raphael", "name": "GRACE", "cost": 1, "requires": "raphael_step", "effect": "vitality", "amount": 1.0, "description": "VITALITY: Healing pickups at full HP grant a shield."},
	{"id": "raphael_shelter", "branch": "raphael", "name": "SHELTER", "cost": 1, "requires": "raphael_grace", "effect": "shelter", "amount": 1.0, "description": "+30% attack knockback while shielded."},
	{"id": "holy_furnace", "branch": "hybrid", "name": "HOLY FURNACE", "cost": 3, "requires": "michael_pyre", "also_requires": "joan_counter", "effect": "furnace", "amount": 1.0, "description": "Stagger triggers remaining burn damage."},
]


static func requirements(definition: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in ["requires", "also_requires"]:
		var id: String = definition.get(key, "")
		if id != "":
			result.append(id)
	return result


static func missing_requirements(definition: Dictionary, skills: Array) -> Array[String]:
	var result: Array[String] = []
	for id in requirements(definition):
		if id not in skills:
			result.append(id)
	return result


static func node(id: String) -> Dictionary:
	for definition in NODES:
		if definition.id == id:
			return definition
	return {}
static func total_cost() -> int:
	var total := 0
	for definition in NODES:
		total += int(definition.cost)
	return total


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
