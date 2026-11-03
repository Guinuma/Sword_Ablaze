extends RefCounted
## One exclusive roll per kill; bounded pickups, collected only when useful.
const MAX_ITEMS: int = 64
var feather_chance: float = 0.15
var wings_chance: float = 0.01
var items: Array[Dictionary] = []


func roll(point: Vector2, random: RandomNumberGenerator) -> void:
	var chance := random.randf()
	if chance < wings_chance:
		spawn(point, 100)
	elif chance < wings_chance + feather_chance:
		spawn(point, 10)


func spawn(point: Vector2, amount: int) -> void:
	if items.size() < MAX_ITEMS:
		items.append({"position": point, "amount": amount, "life": 30.0})


func advance(delta: float, point: Vector2, run: RefCounted) -> void:
	if not run.is_active():
		return
	for index in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[index]
		item["life"] -= delta
		if item["life"] <= 0.0:
			items.remove_at(index)
		elif point.distance_to(item["position"]) <= 16.0 and run.heal(item["amount"]) > 0:
			items.remove_at(index)


func clear() -> void:
	items.clear()
