extends CanvasLayer
## Presentation only: combat owns all timers and run state.
signal resume_requested
signal restart_requested
signal quit_requested

var menu: HBoxContainer
var resume_button: Button
var restart_button: Button
var quit_button: Button
var record_label: Label
var record_save_failed: bool = false
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
	status = _label(Vector2(120, 128), 18)
	status.size = Vector2(400, 110)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu = HBoxContainer.new()
	menu.position = Vector2(130, 256)
	menu.size = Vector2(380, 32)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)
	resume_button = _button("Resume", func(): resume_requested.emit())
	restart_button = _button("Restart", func(): restart_requested.emit())
	quit_button = _button("Quit", func(): quit_requested.emit())
	menu.hide()
	record_label = _label(Vector2(100, 308), 11)
	record_label.size = Vector2(440, 20)
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_label.hide()


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
	var was_open := menu.visible
	var was_dead := not resume_button.visible
	record_label.visible = game_over
	status.visible = game_over or paused
	status.text = "YOU FELL\nWave %d  /  %d kills\nTime %d:%02d\nR to restart" % [wave, kills, int(elapsed) / 60, int(elapsed) % 60]
	if paused:
		status.text = "PAUSED\nEsc to resume  /  R to restart"
	menu.visible = game_over or paused
	resume_button.visible = paused and not game_over
	if menu.visible and (not was_open or was_dead != game_over):
		if resume_button.visible:
			resume_button.grab_focus()
		else:
			restart_button.grab_focus()
	elif not menu.visible and was_open:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(112, 32)
	button.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("1d2638")
	normal.border_color = Color("61758b")
	normal.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus.border_color = Color("ffb454")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(action)
	menu.add_child(button)
	return button


func present_records(records: Dictionary, save_failed: bool) -> void:
	record_save_failed = save_failed
	record_label.text = "BEST  Wave %d  |  %d kills  |  %d:%02d" % [records["best_wave"], records["best_kills"], int(records["best_seconds"]) / 60, int(records["best_seconds"]) % 60]
	if save_failed:
		record_label.text += "  |  Save failed"
