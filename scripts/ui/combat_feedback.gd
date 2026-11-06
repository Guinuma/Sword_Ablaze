extends RefCounted
## Bounded presentation cues; lifetimes advance only with active simulation.
const MAX_CUES := 32
const DURATION := 0.55
var items: Array[Dictionary] = []

func add(kind: StringName, point: Vector2, direction: Vector2 = Vector2.RIGHT) -> void:
	if kind not in [&"spawn", &"dash", &"upgrade", &"heal", &"wave", &"melee", &"critical"]:
		return
	if items.size() == MAX_CUES:
		items.pop_front()
	var duration: float = {&"melee": 0.16, &"critical": 0.24, &"spawn": 0.28, &"dash": 0.2, &"heal": 0.45, &"upgrade": 0.5, &"wave": DURATION}[kind]
	items.append({"kind": kind, "position": point, "life": duration, "duration": duration, "direction": direction})

func advance(delta: float) -> void:
	for index in range(items.size() - 1, -1, -1):
		items[index].life -= delta
		if items[index].life <= 0.0:
			items.remove_at(index)

func clear() -> void:
	items.clear()

func draw_on(canvas: Node2D, reduced_motion: bool, reduced_flashes: bool) -> void:
	for item in items:
		var progress: float = 1.0 - item.life / item.duration
		var point: Vector2 = item.position
		var radius := 14.0 if reduced_motion else lerpf(9.0, 19.0, progress)
		var tint := Color("63b7b3") if item.kind in [&"heal", &"dash"] else Color("c5a46c")
		tint.a = (1.0 - progress) * (0.35 if reduced_flashes else 0.65)
		match item.kind:
			&"melee":
				var direction: Vector2 = item.direction
				canvas.draw_arc(point, 32.0, direction.angle() - PI / 3, direction.angle() + PI / 3, 16, tint, 2)
			&"critical":
				var center := point + Vector2(0, -18)
				canvas.draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), tint, 2)
				canvas.draw_line(center + Vector2(-5, 5), center + Vector2(5, -5), tint, 2)
			&"heal":
				var center := point + Vector2(19, -24 if reduced_motion else -24 - progress * 10)
				canvas.draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), tint, 2)
				canvas.draw_line(center + Vector2(0, -5), center + Vector2(0, 5), tint, 2)
			&"dash":
				for side in [-1, 1]:
					var center := point + Vector2(side * radius, 0)
					canvas.draw_line(center + Vector2(-side * 4, -5), center, tint, 2)
					canvas.draw_line(center, center + Vector2(-side * 4, 5), tint, 2)
			&"upgrade":
				for index in range(6):
					var direction := Vector2.RIGHT.rotated(index * TAU / 6)
					canvas.draw_line(point + direction * radius, point + direction * (radius + 5), tint, 2)
			&"wave":
				canvas.draw_arc(point, radius, PI * 0.1, PI * 0.9, 16, tint, 2)
				canvas.draw_arc(point, radius + 5, PI * 0.1, PI * 0.9, 16, tint, 1)
			&"spawn":
				canvas.draw_arc(point, radius, 0, TAU, 24, tint, 1)
