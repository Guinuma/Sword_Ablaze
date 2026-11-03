extends Control
## Compact, non-activating HUD badge with an effect tooltip.
var definition: Resource
var rank: int = 0
var rank_label: Label
var hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())


func configure(profile: Resource, count: int, font: Font) -> void:
	definition = profile
	rank = count
	custom_minimum_size = Vector2(36, 24)
	size = custom_minimum_size
	rank_label = Label.new()
	rank_label.position = Vector2(25, 7)
	rank_label.size = Vector2(9, 12)
	rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_label.add_theme_font_override("font", font)
	rank_label.add_theme_font_size_override("font_size", 8)
	rank_label.add_theme_color_override("font_color", Color("ede3c9"))
	rank_label.text = str(rank)
	add_child(rank_label)
	tooltip_text = "%s  /  Rank %d of %d\n%s\nResets when this run ends." % [definition.title, rank, definition.max_stacks, _effect_text()]
	queue_redraw()


func _effect_text() -> String:
	if definition.attribute == "critical_chance":
		return "Critical chance: +%d%%; critical damage: x2" % int(round(definition.addition * rank * 100))
	if definition.addition != 0.0:
		return "%s: +%d" % ["Maximum HP" if definition.attribute == "max_health" else "Projectile damage", int(definition.addition * rank)]
	var names := {"move_speed": "Movement speed", "fire_interval": "Shot delay", "knockback": "Enemy knockback", "dash_cooldown": "Dash recharge"}
	var percent: float = (pow(definition.multiplier, rank) - 1.0) * 100.0
	return "%s: %+.1f%%" % [names.get(definition.attribute, definition.attribute), percent]


func _draw() -> void:
	var gold := Color("c5a46c")
	var ink := Color(0.04, 0.07, 0.11, 0.96)
	draw_rect(Rect2(Vector2.ZERO, size), ink)
	draw_rect(Rect2(Vector2.ZERO, size), Color("ede3c9") if hovered else gold, false, 1.0)
	var center := Vector2(12, 12)
	match definition.id:
		&"swift":
			for offset in [-3.0, 3.0]:
				draw_polyline(PackedVector2Array([center + Vector2(offset - 2, -5), center + Vector2(offset + 3, 0), center + Vector2(offset - 2, 5)]), gold, 1.0)
		&"rapid":
			for index in range(3):
				draw_line(Vector2(6 + index * 5, 9 - index * 2), Vector2(6 + index * 5, 17 - index * 2), gold, 2.0)
		&"heavy":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(4, -3), center + Vector2(4, 5), center + Vector2(-4, 5), center + Vector2(-4, -3)]), gold)
			draw_line(center + Vector2(-4, 2), center + Vector2(4, 2), ink)
		&"force":
			for index in range(4):
				var direction := Vector2.RIGHT.rotated(index * PI * 0.5)
				draw_line(center + direction * 2.0, center + direction * 7.0, gold)
				draw_line(center + direction * 7.0, center + direction * 4.0 + direction.orthogonal() * 2.0, gold)
				draw_line(center + direction * 7.0, center + direction * 4.0 - direction.orthogonal() * 2.0, gold)
		&"critical":
			draw_line(center + Vector2(-6, -6), center + Vector2(6, 6), gold, 2)
			draw_line(center + Vector2(-6, 6), center + Vector2(6, -6), gold, 2)
			draw_circle(center, 3, gold)
		&"vitality":
			draw_rect(Rect2(9, 5, 5, 14), gold)
			draw_rect(Rect2(5, 9, 13, 5), gold)
		&"dash":
			draw_colored_polygon(PackedVector2Array([center + Vector2(2, -8), center + Vector2(-5, 1), center + Vector2(0, 1), center + Vector2(-2, 8), center + Vector2(6, -2), center + Vector2(1, -2)]), gold)


func _make_custom_tooltip(text: String) -> Object:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0c1521")
	style.border_color = Color("c5a46c")
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(250, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("ede3c9"))
	panel.add_child(label)
	return panel
