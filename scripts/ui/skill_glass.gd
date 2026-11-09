extends Control
## Decorative glass and prerequisite paths sit behind the interactive buttons.
const Skills = preload("res://scripts/data/skill_catalog.gd")
const HUB := Vector2(121, 82)
const LEAD := Color("16141b")
const GOLD := Color("f1c078")
const POSITIONS := {
	"michael_edge": Vector2(89, 53), "michael_reach": Vector2(38, 50),
	"gabriel_focus": Vector2(153, 53), "gabriel_precision": Vector2(204, 50),
	"raphael_vigor": Vector2(89, 111), "raphael_step": Vector2(38, 114),
	"joan_standard": Vector2(153, 111), "joan_stand": Vector2(204, 114),
	"michael_ember": Vector2(46, 73), "michael_pyre": Vector2(75, 74),
	"joan_break": Vector2(196, 145), "joan_counter": Vector2(166, 144),
	"gabriel_seal": Vector2(196, 73), "gabriel_verdict": Vector2(167, 74),
	"raphael_grace": Vector2(46, 145), "raphael_shelter": Vector2(76, 144),
	"holy_furnace": Vector2(121, 119),
}
var learned: Array = []
var selected: String = ""


static func patron_color(id: String) -> Color:
	for branch in Skills.BRANCHES:
		if branch.id == id:
			return branch.color
	return GOLD


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b14"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("94704d"), false)
	draw_rect(Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6), Color("47323e"), false)
	for x in [8.0, size.x - 8.0]:
		for y in [8.0, size.y - 8.0]:
			var corner := Vector2(x, y)
			draw_arc(corner, 3, 0, TAU, 12, GOLD.darkened(0.35), 1, true)
	for radius in [47.0, 63.0, 76.0]:
		draw_arc(HUB, radius, 0, TAU, 64, Color("2e2535"), 1, true)
	for y in range(15, 155, 13):
		draw_line(Vector2(8, y), Vector2(size.x - 8, y), Color("18141f"), 1)
	for branch in Skills.BRANCHES:
		_draw_glass(branch.center, branch.color, branch.id)
	for node in Skills.NODES:
		var start: Vector2 = HUB if node.requires == "" else POSITIONS[node.requires]
		var end: Vector2 = POSITIONS[node.id]
		var active: bool = node.id in learned
		var available := Skills.missing_requirements(node, learned).is_empty()
		var route := PackedVector2Array([start, end])
		if node.cost == 2:
			var bend := Vector2((start.x + end.x) / 2, start.y + 12)
			route = PackedVector2Array([start, bend, end])
		if node.id == "joan_standard":
			route = PackedVector2Array([start, Vector2(109, 64), Vector2(132, 71), Vector2(140, 96), end])
		_draw_route(route, active, available)
		if node.has("also_requires"):
			_draw_route(PackedVector2Array([POSITIONS[node.also_requires], end]), active, available)
	if POSITIONS.has(selected):
		var radius := 11 if Skills.node(selected).cost == 1 else 13
		draw_arc(POSITIONS[selected], radius, 0, TAU, 24, Color("fff0cd"), 1, true)
	draw_circle(HUB, 7, LEAD)
	draw_arc(HUB, 7, 0, TAU, 20, GOLD, 1, true)
	draw_colored_polygon(PackedVector2Array([HUB + Vector2(0, -4), HUB + Vector2(3, 0), HUB + Vector2(0, 4), HUB + Vector2(-3, 0)]), GOLD)


func _draw_route(route: PackedVector2Array, active: bool, available: bool) -> void:
	draw_polyline(route, LEAD, 5, true)
	if active:
		draw_polyline(route, Color("885237"), 4, true)
	draw_polyline(route, GOLD if active else Color("8b7771") if available else Color("564955"), 2 if active else 1, true)


func _draw_glass(center: Vector2, tint: Color, patron: String) -> void:
	draw_circle(center, 39, tint.darkened(0.72))
	draw_arc(center, 39, 0, TAU, 56, tint.darkened(0.36), 1, true)
	draw_circle(center, 36, tint.darkened(0.77))
	for index in range(12):
		var angle := index * TAU / 12
		var left := center + Vector2.from_angle(angle) * 35
		var right := center + Vector2.from_angle(angle + TAU / 12) * 35
		var tip := center + Vector2.from_angle(angle + TAU / 24) * 27
		var inner := center + Vector2.from_angle(angle + TAU / 24) * 12
		draw_colored_polygon(PackedVector2Array([left, tip, right, inner]), tint.darkened(0.43 + 0.09 * (index % 4)))
		draw_polyline(PackedVector2Array([left, tip, right, inner, left]), LEAD, 1.4, true)
		var highlight := tip.lerp(inner, 0.28)
		draw_line(tip, highlight, tint.lightened(0.23), 1, true)
		draw_circle(center + Vector2.from_angle(angle) * 34, 1.1, tint.lightened(0.16))
	draw_arc(center, 37, 0, TAU, 48, tint.darkened(0.27), 1, true)
	draw_arc(center, 31, 0, TAU, 48, tint.darkened(0.28), 1, true)
	draw_circle(center, 12, LEAD)
	draw_arc(center, 12, 0, TAU, 24, tint, 1, true)
	match patron:
		"michael":
			draw_line(center + Vector2(0, -8), center + Vector2(0, 8), tint, 2, true)
			draw_line(center + Vector2(-4, 3), center + Vector2(4, 3), tint, 2, true)
		"gabriel":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-8, 2), center + Vector2(7, -6), center + Vector2(7, 4)]), tint)
		"raphael":
			draw_line(center + Vector2(0, -3), center + Vector2(0, 8), tint, 2, true)
			draw_arc(center + Vector2(3, -4), 3, PI, TAU * 1.15, 12, tint, 1.5, true)
		"joan":
			draw_line(center + Vector2(-5, -8), center + Vector2(-5, 8), tint, 1.5, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-4, -7), center + Vector2(7, -5), center + Vector2(4, 2), center + Vector2(-4, 0)]), tint)
