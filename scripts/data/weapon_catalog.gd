extends RefCounted

const Skills = preload("res://scripts/data/skill_catalog.gd")
const STARTER_RANGED := &"dawn_bow"
const STARTER_MELEE := &"sword_ablaze"
const WEAPONS := {
	&"sword_ablaze": {"name": "Sword Ablaze", "slot": &"melee", "node": "", "role": "Wide, fast flame sweep", "color": Color("ff8744"), "stats": preload("res://resources/sword_ablaze.tres")},
	&"dawn_bow": {"name": "Dawn Bow", "slot": &"ranged", "node": "", "role": "Quick, precise arrows", "color": Color("ffe39c"), "stats": preload("res://resources/dawn_bow.tres")},
	&"seraph_halberd": {"name": "Seraph Halberd", "slot": &"melee", "node": "michael_edge", "role": "Long, narrow sweep and strong push", "color": Color("ffcb65"), "stats": preload("res://resources/seraph_halberd.tres")},
	&"judgment_lance": {"name": "Judgment Lance", "slot": &"ranged", "node": "michael_reach", "role": "Heavy, fast bolt with a long recovery", "color": Color("ffc07e"), "stats": preload("res://resources/judgment_lance.tres")},
}


static func unlocked(id: StringName, skills: Array) -> bool:
	var entry: Dictionary = WEAPONS.get(id, {})
	return not entry.is_empty() and (entry.node == "" or entry.node in skills)


static func resolve(id: StringName, slot: StringName, skills: Array) -> StringName:
	if unlocked(id, skills) and WEAPONS[id].slot == slot:
		return id
	return STARTER_MELEE if slot == &"melee" else STARTER_RANGED
