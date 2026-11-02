extends RefCounted
## Offers only eligible upgrades and consumes a choice exactly once.
const Definition = preload("res://scripts/data/upgrade_definition.gd")
var definitions: Array[Resource] = []
var stacks: Dictionary = {}
var offered: Array[Resource] = []


func _init() -> void:
	for id in ["swift", "rapid", "heavy", "force", "dash"]:
		definitions.append(load("res://resources/upgrades/%s.tres" % id))


func reset() -> void:
	stacks.clear()
	offered.clear()


func offer(random: RandomNumberGenerator) -> Array[Resource]:
	var eligible: Array[Resource] = []
	for definition in definitions:
		if stacks.get(definition.id, 0) < definition.max_stacks:
			eligible.append(definition)
	offered.clear()
	while offered.size() < 3 and not eligible.is_empty():
		var index := random.randi_range(0, eligible.size() - 1)
		offered.append(eligible[index])
		eligible.remove_at(index)
	return offered


func choose(id: StringName) -> bool:
	for definition in offered:
		if definition.id == id and stacks.get(id, 0) < definition.max_stacks:
			stacks[id] = stacks.get(id, 0) + 1
			offered.clear()
			return true
	return false


func value(attribute: String, base: float) -> float:
	var result := base
	for definition in definitions:
		if definition.attribute == attribute:
			for stack in range(stacks.get(definition.id, 0)):
				result = result * definition.multiplier + definition.addition
	return result
