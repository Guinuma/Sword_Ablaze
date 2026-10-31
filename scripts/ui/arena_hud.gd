extends CanvasLayer
## Presentation only: combat owns all timers and run state.
var stats: Label
var wave_status: Label
var status: Label


func _ready() -> void:
	layer = 3
	var title := _label(Vector2(24, 12), 16)
	title.text = "SWORD ABLAZE  /  ARENA"
	var instructions := _label(Vector2(24, 38), 12)
	instructions.text = "WASD: move | Click/Space: fire | Shift: dash | Esc: pause | R: restart"
	stats = _label(Vector2(348, 14), 12)
	wave_status = _label(Vector2(120, 72), 14)
	wave_status.size = Vector2(400, 30)
	wave_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status = _label(Vector2(120, 152), 20)
	status.size = Vector2(400, 72)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(point: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = point
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label


func present(health: int, max_health: int, kills: int, elapsed: float, wave: int, remaining: int, break_time: float, dash_cooldown: float, game_over: bool, paused: bool) -> void:
	stats.text = "HP %d/%d  |  KILLS %d  |  %ds" % [health, max_health, kills, int(elapsed)]
	wave_status.visible = not game_over
	wave_status.text = "WAVE %d CLEAR  |  Next in %d" % [wave, ceili(break_time)] if break_time > 0.0 else "WAVE %d  |  Remaining %d  |  DASH %s" % [wave, remaining, "READY" if dash_cooldown <= 0.0 else "%.1fs" % dash_cooldown]
	status.visible = game_over or paused
	status.text = "YOU FELL\n%d kills  /  %ds  /  R to restart" % [kills, int(elapsed)]
	if paused:
		status.text = "PAUSED\nEsc to resume  /  R to restart"
