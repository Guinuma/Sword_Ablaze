extends CanvasLayer
## Presentation only: combat owns all timers and run state.
signal reward_retry_requested
signal upgrade_selected(id: StringName)
signal preferences_changed(reduced_flashes: bool, reduced_motion: bool)
signal pause_requested
signal resume_requested
signal restart_requested
signal main_menu_requested
signal quit_requested

const FocusNavigation = preload("res://scripts/ui/focus_navigation.gd")
const BlessingBadge = preload("res://scripts/ui/blessing_badge.gd")
const PIXEL_FONT = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const INK := Color("0a111c")
const IVORY := Color("ede3c9")
const GOLD := Color("c5a46c")
const MUTED := Color("9aabb8")
const TEAL := Color("63b7b3")
var pixel_font: FontFile
var stats: Label
var wave_status: Label
var wave_heading: Label
var time_label: Label
var kill_label: Label
var health_bar: Control
var health_value: int = 100
var health_max: int = 100
var dash_panel: Panel
var dash_key: Label
var dash_label: Label
var dash_meter: ProgressBar
var dash_fill: StyleBoxFlat
var control_hint: Label
var pause_hint: Label
var blessing_tray: HBoxContainer
var badge_stacks: Dictionary = {}
var pause_button: Button
var menu_backdrop: Panel
var status: Label
var summary: Label
var menu_hint: Label
var menu: VBoxContainer
var resume_button: Button
var restart_button: Button
var quit_button: Button
var reward_label: Label
var reward_retry_button: Button
var record_label: Label
var record_save_failed: bool = false
var flashes_toggle: CheckButton
var motion_toggle: CheckButton
var preference_error: Label
var upgrade_backdrop: Panel
var upgrade_panel: VBoxContainer
var choice_buttons: Array[Button] = []
var shown_choices: Array[Resource] = []
var stack_total: int = 0


func _ready() -> void:
	layer = 3
	pixel_font = PIXEL_FONT.duplicate()
	pixel_font.antialiasing = 0
	_build_status_bar()
	_build_menus()
	_build_upgrades()


func _build_status_bar() -> void:
	_panel(Rect2(0, 0, 640, 62), INK, Color("6b573a"))
	var name_label := _label(Vector2(20, 8), Vector2(150, 14), 8, true, GOLD)
	name_label.text = "THE EXILE"
	health_bar = Control.new()
	health_bar.position = Vector2(24, 34)
	health_bar.size = Vector2(92, 14)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.draw.connect(_draw_health)
	add_child(health_bar)
	stats = _label(Vector2(120, 28), Vector2(86, 18), 8, true)
	var location := _label(Vector2(210, 8), Vector2(220, 14), 8, true, GOLD)
	location.text = "CELESTIAL COURTYARD"
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_heading = _label(Vector2(230, 24), Vector2(180, 26), 16, true)
	wave_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label = _label(Vector2(472, 7), Vector2(112, 25), 16, true)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kill_label = _label(Vector2(472, 34), Vector2(112, 14), 8, true, GOLD)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_button = _button("II", self, func(): pause_requested.emit())
	pause_button.position = Vector2(602, 15)
	pause_button.custom_minimum_size = Vector2(24, 28)
	pause_button.size = Vector2(24, 28)
	pause_button.tooltip_text = "Pause (Escape)"
	wave_status = _label(Vector2(232, 66), Vector2(176, 21), 8, true)
	wave_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_status.add_theme_stylebox_override("normal", _style(Color(0.04, 0.07, 0.11, 0.93), Color("6b573a")))
	dash_panel = _panel(Rect2(14, 330, 144, 23), Color(0.04, 0.07, 0.11, 0.95), Color("6b573a"))
	dash_key = _label(Vector2(20, 336), Vector2(36, 12), 8, true, GOLD)
	dash_key.text = "SHIFT"
	dash_label = _label(Vector2(63, 332), Vector2(89, 13), 8, true)
	dash_meter = ProgressBar.new()
	dash_meter.position = Vector2(63, 346)
	dash_meter.size = Vector2(85, 3)
	dash_meter.max_value = 1.0
	dash_meter.show_percentage = false
	dash_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_meter.add_theme_stylebox_override("background", _style(Color("26313d"), Color("26313d"), 0))
	dash_fill = _style(TEAL, TEAL, 0)
	dash_meter.add_theme_stylebox_override("fill", dash_fill)
	add_child(dash_meter)
	control_hint = _label(Vector2(176, 336), Vector2(310, 14), 8, true, IVORY)
	control_hint.text = "WASD MOVE   MOUSE AIM   CLICK FIRE"
	control_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blessing_tray = HBoxContainer.new()
	blessing_tray.position = Vector2(220, 329)
	blessing_tray.size = Vector2(200, 24)
	blessing_tray.alignment = BoxContainer.ALIGNMENT_CENTER
	blessing_tray.add_theme_constant_override("separation", 5)
	add_child(blessing_tray)
	pause_hint = _label(Vector2(514, 336), Vector2(112, 14), 8, true, IVORY)
	pause_hint.text = "ESC PAUSE"
	pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint.add_theme_stylebox_override("normal", _style(Color(0.04, 0.07, 0.11, 0.95), Color("6b573a")))


func _build_menus() -> void:
	menu_backdrop = _panel(Rect2(158, 96, 324, 238), Color("0c1521"), GOLD)
	status = _label(Vector2(180, 111), Vector2(280, 30), 16, true)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary = _label(Vector2(180, 146), Vector2(280, 54), 13, false, MUTED)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu = VBoxContainer.new()
	menu.position = Vector2(182, 176)
	menu.size = Vector2(276, 68)
	menu.add_theme_constant_override("separation", 8)
	add_child(menu)
	resume_button = _button("RESUME", menu, func(): resume_requested.emit(), true)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 8)
	menu.add_child(secondary)
	restart_button = _button("RESTART", secondary, func(): restart_requested.emit())
	quit_button = _button("MAIN MENU", secondary, func(): main_menu_requested.emit())
	flashes_toggle = _toggle("Reduce flashes", Vector2(182, 247))
	motion_toggle = _toggle("Reduce visual motion", Vector2(182, 274))
	menu_hint = _label(Vector2(182, 310), Vector2(276, 12), 8, true, MUTED)
	menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preference_error = _label(Vector2(182, 310), Vector2(276, 12), 10, false, Color("ed8c82"))
	preference_error.text = "Preferences could not be saved"
	preference_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label = _label(Vector2(182, 249), Vector2(276, 14), 8, true, GOLD)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_retry_button = _button("RETRY XP SAVE", self, func(): reward_retry_requested.emit())
	reward_retry_button.position = Vector2(182, 310)
	reward_retry_button.custom_minimum_size = Vector2(276, 20)
	reward_retry_button.size = Vector2(276, 20)
	reward_label.hide()
	reward_retry_button.hide()
	record_label = _label(Vector2(180, 267), Vector2(280, 42), 8, true, GOLD)
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.hide()
	menu_backdrop.hide()
	status.hide()
	summary.hide()
	flashes_toggle.hide()
	motion_toggle.hide()
	menu_hint.hide()
	preference_error.hide()
	record_label.hide()


func _build_upgrades() -> void:
	upgrade_backdrop = _panel(Rect2(80, 102, 480, 218), Color("0c1521"), GOLD)
	var heading := _label(Vector2(100, 114), Vector2(440, 26), 16, true)
	heading.text = "CHOOSE A BLESSING"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_backdrop.set_meta("heading", heading)
	var note := _label(Vector2(100, 141), Vector2(440, 18), 11, false, MUTED)
	note.text = "Choose one. Its power lasts for this run."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_backdrop.set_meta("note", note)
	upgrade_panel = VBoxContainer.new()
	upgrade_panel.position = Vector2(104, 166)
	upgrade_panel.size = Vector2(432, 144)
	upgrade_panel.add_theme_constant_override("separation", 8)
	add_child(upgrade_panel)
	for index in range(3):
		var button := _button("", upgrade_panel, _select_upgrade.bind(index))
		button.custom_minimum_size = Vector2(432, 42)
		button.add_theme_font_override("font", ThemeDB.fallback_font)
		button.add_theme_font_size_override("font_size", 11)
		choice_buttons.append(button)
	_set_upgrade_visible(false)


func _draw_health() -> void:
	var bounds := Rect2(-4, -6, 92, 12)
	health_bar.draw_rect(bounds, Color("26313d"))
	var ratio := clampf(float(health_value) / maxf(1.0, health_max), 0.0, 1.0)
	var tint := Color("ed8c82") if ratio <= 0.2 else TEAL
	health_bar.draw_rect(Rect2(-2, -4, floorf(88.0 * ratio), 8), tint)
	health_bar.draw_rect(bounds, GOLD, false, 1.0)


func present(health: int, max_health: int, kills: int, elapsed: float, wave: int, remaining: int, break_time: float, dash_cooldown: float, game_over: bool, paused: bool, dash_max: float = 1.2) -> void:
	health_value = health
	health_max = max_health
	health_bar.queue_redraw()
	stats.text = "HP %d/%d" % [health, max_health]
	stats.modulate = Color("ed8c82") if health <= max_health * 0.2 else IVORY
	wave_heading.text = "WAVE %02d" % wave
	time_label.text = "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	kill_label.text = "%d KILLS" % kills
	wave_status.visible = not game_over
	wave_status.text = "NEXT WAVE IN %d" % ceili(break_time) if break_time > 0.0 else "%d REMAINING" % remaining
	if upgrade_panel.visible:
		wave_status.text = "WAVE CLEARED"
	dash_label.text = "DASH READY" if dash_cooldown <= 0.0 else "DASH %.1fS" % dash_cooldown
	dash_meter.value = clampf(1.0 - dash_cooldown / maxf(0.01, dash_max), 0.0, 1.0)
	dash_fill.bg_color = TEAL if dash_cooldown <= 0.0 else GOLD
	var modal := game_over or paused or upgrade_panel.visible
	dash_panel.visible = not modal
	dash_label.visible = not modal
	dash_meter.visible = not modal
	dash_key.visible = not modal
	control_hint.visible = elapsed < 20.0 and stack_total == 0 and not modal
	blessing_tray.visible = stack_total > 0 and not modal
	pause_hint.visible = not modal
	pause_button.disabled = modal
	var was_open := menu.visible
	var was_dead := not resume_button.visible
	menu_backdrop.visible = game_over or paused
	status.visible = game_over or paused
	summary.visible = game_over or paused
	status.text = "PAUSED" if paused else "YOU FELL"
	summary.text = "Wave %d  /  %d kills\nSurvived %d:%02d" % [wave, kills, int(elapsed) / 60, int(elapsed) % 60] if game_over else "Wave %d   /   %d:%02d" % [wave, int(elapsed) / 60, int(elapsed) % 60]
	menu.position.y = 176 if paused else 218
	menu.visible = game_over or paused
	resume_button.visible = paused and not game_over
	record_label.visible = game_over
	flashes_toggle.visible = paused and not game_over
	motion_toggle.visible = paused and not game_over
	preference_error.visible = paused and preference_error.get_meta("failed", false)
	menu_hint.visible = paused and not preference_error.visible
	menu_hint.text = "ESC RESUME    R RESTART"
	if menu.visible:
		var controls: Array[Control] = []
		if resume_button.visible:
			controls.append(resume_button)
		controls.append_array([restart_button, quit_button])
		if flashes_toggle.visible:
			controls.append_array([flashes_toggle, motion_toggle])
		FocusNavigation.ring(controls)
	if menu.visible and (not was_open or was_dead != game_over):
		if resume_button.visible:
			resume_button.grab_focus()
		else:
			restart_button.grab_focus()
	elif not menu.visible and was_open:
		var focused := get_viewport().gui_get_focus_owner()
		if focused and menu.is_ancestor_of(focused):
			focused.release_focus()


func present_records(records: Dictionary, save_failed: bool) -> void:
	record_save_failed = save_failed
	record_label.text = "BEST WAVE %d    %d KILLS\nSURVIVAL %d:%02d" % [records["best_wave"], records["best_kills"], int(records["best_seconds"]) / 60, int(records["best_seconds"]) % 60]
	if save_failed:
		record_label.text += "\nCould not save records"


func present_upgrades(choices: Array[Resource], choosing: bool, stacks: Dictionary, definitions: Array[Resource] = []) -> void:
	_sync_badges(stacks, definitions)
	var was_visible := upgrade_panel.visible
	_set_upgrade_visible(choosing)
	shown_choices = choices.duplicate()
	stack_total = 0
	for count in stacks.values():
		stack_total += int(count)
	for index in range(choice_buttons.size()):
		var button: Button = choice_buttons[index]
		button.visible = index < choices.size()
		if button.visible:
			var definition = choices[index]
			button.text = "%s   /   RANK %d OF %d\n%s" % [definition.title.to_upper(), stacks.get(definition.id, 0) + 1, definition.max_stacks, definition.description]
	if choosing:
		var controls: Array[Control] = []
		for button in choice_buttons:
			if button.visible:
				controls.append(button)
		FocusNavigation.ring(controls)
	if choosing and not was_visible and not choices.is_empty():
		choice_buttons[0].grab_focus()


func _set_upgrade_visible(value: bool) -> void:
	upgrade_panel.visible = value
	upgrade_backdrop.visible = value
	upgrade_backdrop.get_meta("heading").visible = value
	upgrade_backdrop.get_meta("note").visible = value


func _select_upgrade(index: int) -> void:
	if upgrade_panel.visible and index < shown_choices.size():
		upgrade_selected.emit(shown_choices[index].id)


func present_preferences(reduced_flashes: bool, reduced_motion: bool, save_failed: bool) -> void:
	flashes_toggle.set_pressed_no_signal(reduced_flashes)
	motion_toggle.set_pressed_no_signal(reduced_motion)
	preference_error.set_meta("failed", save_failed)


func _style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	return style


func _panel(rect: Rect2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	add_child(panel)
	return panel


func _label(point: Vector2, dimensions: Vector2, font_size: int, pixel: bool = false, tint: Color = IVORY) -> Label:
	var label := Label.new()
	label.position = point
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	if pixel:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func _button(text: String, parent: Node, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(134, 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_color_override("font_color", INK if primary else IVORY)
	button.add_theme_color_override("font_hover_color", INK if primary else IVORY)
	button.add_theme_color_override("font_focus_color", INK if primary else IVORY)
	button.add_theme_color_override("font_pressed_color", INK if primary else IVORY)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("172332"), GOLD if primary else Color("66717a")))
	button.add_theme_stylebox_override("hover", _style(IVORY if primary else Color("293847"), IVORY))
	button.add_theme_stylebox_override("pressed", _style(Color("a78855") if primary else Color("354351"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), IVORY, 2))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _toggle(text: String, point: Vector2) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.position = point
	toggle.size = Vector2(276, 24)
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.add_theme_color_override("font_color", IVORY)
	toggle.add_theme_color_override("font_hover_color", GOLD)
	toggle.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), GOLD))
	toggle.toggled.connect(func(_pressed): preferences_changed.emit(flashes_toggle.button_pressed, motion_toggle.button_pressed))
	add_child(toggle)
	return toggle


func _sync_badges(stacks: Dictionary, definitions: Array[Resource]) -> void:
	if stacks == badge_stacks:
		return
	badge_stacks = stacks.duplicate()
	for child in blessing_tray.get_children():
		blessing_tray.remove_child(child)
		child.queue_free()
	for definition in definitions:
		var count: int = stacks.get(definition.id, 0)
		if count > 0:
			var badge = BlessingBadge.new()
			badge.configure(definition, count, pixel_font)
			blessing_tray.add_child(badge)


func blocks_fire() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and (hovered == pause_button or blessing_tray.is_ancestor_of(hovered))


func present_reward(terminal: bool, pending: bool, _received: bool, awarded: int, level: int, unavailable: bool) -> void:
	var shown := terminal and menu.visible
	reward_label.visible = shown
	var retry_had_focus := reward_retry_button.has_focus()
	reward_retry_button.visible = shown and pending
	if retry_had_focus and not reward_retry_button.visible and shown:
		restart_button.grab_focus()
	reward_label.text = "XP NOT SAVED - RETRY BELOW" if pending else ("GLOBAL XP UNAVAILABLE" if unavailable else "GLOBAL XP +%d   LEVEL %d" % [awarded, level])
	if shown:
		var controls: Array[Control] = [restart_button, quit_button]
		if reward_retry_button.visible:
			controls.append(reward_retry_button)
		FocusNavigation.ring(controls)
