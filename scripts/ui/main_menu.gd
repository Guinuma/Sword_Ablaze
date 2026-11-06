extends Control
const GameIcons = preload("res://scripts/ui/game_icons.gd")
## Title and sanctuary presentation; combat is instantiated only after mode selection.
@export var is_hub: bool = false
const ControlNames = preload("res://scripts/ui/combat_tutorial.gd")
const FocusNavigation = preload("res://scripts/ui/focus_navigation.gd")
const GlobalProfile = preload("res://scripts/run/global_profile.gd")
const Preferences = preload("res://scripts/settings/preferences.gd")
const ArenaRecords = preload("res://scripts/run/arena_records.gd")
const COURTYARD = preload("res://assets/art/arena/celestial-courtyard-01.png")
const FONT = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const GOLD = Color("c5a46c")
const IVORY = Color("ede3c9")
const MUTED = Color("9aabb8")
const SoundEffects = preload("res://scripts/audio/sound_effects.gd")
var sounds = SoundEffects.new()
const Music = preload("res://scripts/audio/music.gd")
var preferences = Preferences.new()
var records = ArenaRecords.new()
var home: Control
var detail: Control
var detail_body: VBoxContainer
var play_button: Button
var loadout_button: Button
var back_button: Button
var return_focus: Button
var save_error: Label
var clock: float = 0.0
var binding_action: StringName = &""
var binding_button: Button
var binding_status: Label
var starting: bool = false
var pixel_font: Font
var detail_title := ""
var detail_history: Array[Dictionary] = []
var restoring_page := false

func _ready() -> void:
	preferences.load_preferences()
	add_child(sounds)
	var music = Music.for_tree(get_tree())
	music.ducked = false
	music.bind_scene(self, &"sanctuary")
	records.load_records()
	pixel_font = FONT.duplicate()
	pixel_font.antialiasing = 0
	home = Control.new()
	add_child(home)
	_label(home, "REST. PREPARE. RETURN TO THE LIGHT." if is_hub else "A FALLEN HEAVEN. AN UNBROKEN WILL.", Vector2(36, 37), 8, GOLD)
	_label(home, "THE" if is_hub else "SWORD", Vector2(32, 57), 32, IVORY)
	_label(home, "SANCTUARY" if is_hub else "ABLAZE", Vector2(32, 91), 24 if is_hub else 40, GOLD)
	_label(home, "Your strength endures between journeys." if is_hub else "Enter the courtyard. Survive the fallen.", Vector2(36, 143), 12, MUTED, false)
	var actions := VBoxContainer.new()
	actions.position = Vector2(36, 176)
	actions.custom_minimum_size.x = 224
	actions.add_theme_constant_override("separation", 4)
	home.add_child(actions)
	play_button = _button(actions, "CHOOSE ARENA" if is_hub else "PLAY", _show_modes if is_hub else _show_play, true)
	if is_hub:
		_button(actions, "PROGRESSION", _show_progression)
	_button(actions, "OPTIONS", _show_options)
	if is_hub:
		loadout_button = _button(actions, "WEAPON LOADOUT", _show_loadout)
	_button(actions, "TITLE SCREEN" if is_hub else "QUIT", _return_to_title if is_hub else func(): Music.for_tree(get_tree()).quit_game())
	for button in actions.get_children():
		button.custom_minimum_size.y = 26
	var data: Dictionary = records.data
	_label(home, "PERSONAL BEST", Vector2(358, 281), 8, GOLD)
	_label(home, "WAVE %02d   /   %d KILLS" % [data["best_wave"], data["best_kills"]], Vector2(358, 299), 8, IVORY)
	_label(home, "SURVIVAL %02d:%02d" % [int(data["best_seconds"]) / 60, int(data["best_seconds"]) % 60], Vector2(358, 315), 8, MUTED)
	_label(self, "ARROWS / TAB + ENTER    |    MOUSE", Vector2(36, 342), 8, MUTED)
	_label(self, "ARENA PROTOTYPE", Vector2(482, 342), 8, MUTED)
	detail = Control.new()
	detail.hide()
	add_child(detail)
	var panel := Panel.new()
	panel.position = Vector2(100, 36)
	panel.size = Vector2(440, 288)
	panel.add_theme_stylebox_override("panel", _style(Color("0c1521"), GOLD))
	detail.add_child(panel)
	detail_body = VBoxContainer.new()
	detail_body.position = Vector2(124, 54)
	detail_body.size = Vector2(392, 216)
	detail_body.add_theme_constant_override("separation", 12)
	detail.add_child(detail_body)
	back_button = _button(detail, "BACK", _back)
	back_button.position = Vector2(124, 280)
	back_button.size = Vector2(392, 28)
	if is_hub:
		_build_hub_overview()
	_refresh_focus()
	play_button.grab_focus()

func _process(delta: float) -> void:
	if not preferences.reduced_motion:
		clock += delta
		queue_redraw()

func _input(event: InputEvent) -> void:
	if binding_action == &"" or not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		binding_action = &""
		_show_bindings()
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not preferences.set_binding(binding_action, code):
		binding_status.text = "Key unavailable. Try another; Escape cancels."
		return
	binding_action = &""
	preferences.save()
	_show_bindings()
	if preferences.last_error != OK:
		binding_status.text = "Applied, but could not save preferences."

func _unhandled_input(event: InputEvent) -> void:
	if detail.visible and event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()

func _start_game(finite: bool = false) -> void:
	if starting:
		return
	starting = true
	get_tree().set_meta("finite_run", finite)
	get_tree().set_meta("return_to_hub", is_hub)
	var error := get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	if error != OK:
		starting = false
		push_error("Could not open arena: %s" % error_string(error))

func _open_detail(title: String) -> void:
	if not restoring_page:
		if detail.visible and title != detail_title:
			var controls: Array[Control] = []
			FocusNavigation.collect(detail, controls)
			detail_history.append({"title": detail_title, "focus": controls.find(get_viewport().gui_get_focus_owner())})
		elif home.visible:
			detail_history.clear()
			return_focus = get_viewport().gui_get_focus_owner() as Button
	detail_title = title
	detail_body.add_theme_constant_override("separation", 12)
	for child in detail_body.get_children():
		detail_body.remove_child(child)
		child.queue_free()
	home.hide()
	detail.show()
	var heading := _label(detail_body, title, Vector2.ZERO, 16, GOLD)
	heading.custom_minimum_size.y = 30

func _show_controls() -> void:
	_open_detail("HOW TO PLAY")
	detail_body.add_theme_constant_override("separation", 6)
	var movement := "/".join([ControlNames.key_name(&"move_up"), ControlNames.key_name(&"move_left"), ControlNames.key_name(&"move_down"), ControlNames.key_name(&"move_right")])
	for text in [movement + "     Move", "Mouse                 Aim", "Left click / " + ControlNames.key_name(&"fire") + "   Fire", ControlNames.key_name(&"dash") + "                    Dash", "Right click / " + ControlNames.key_name(&"melee") + "   Melee", "Escape                 Pause / resume", ControlNames.key_name(&"reset_sandbox") + "                         Restart the run", "Clear waves. Choose blessings every third wave."]:
		_label(detail_body, text, Vector2.ZERO, 12, IVORY, false)
	_refresh_focus()
	back_button.grab_focus()

func _show_options() -> void:
	_open_detail("OPTIONS")
	detail_body.add_theme_constant_override("separation", 4)
	for entry in [["Reduce flashes", preferences.reduced_flashes], ["Reduce visual motion", preferences.reduced_motion]]:
		var toggle := CheckButton.new()
		toggle.text = entry[0]
		toggle.button_pressed = entry[1]
		toggle.custom_minimum_size.y = 34
		toggle.add_theme_color_override("font_color", IVORY)
		toggle.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
		detail_body.add_child(toggle)
		if entry[0] == "Reduce flashes":
			toggle.toggled.connect(func(value): preferences.reduced_flashes = value; _save_preferences())
		else:
			toggle.toggled.connect(func(value): preferences.reduced_motion = value; _save_preferences(); queue_redraw())
	var shortcuts := GridContainer.new()
	shortcuts.columns = 2
	shortcuts.add_theme_constant_override("h_separation", 8)
	shortcuts.add_theme_constant_override("v_separation", 4)
	detail_body.add_child(shortcuts)
	for entry in [["COMBAT FEEDBACK", _show_feedback_options], ["AUDIO VOLUMES", _show_audio], ["KEYBOARD BINDINGS", _show_bindings], ["HOW TO PLAY", _show_controls], ["WEAPON LOADOUT", _show_loadout]]:
		var shortcut := _button(shortcuts, entry[0], entry[1])
		shortcut.custom_minimum_size = Vector2(192, 24)
		if entry[0] == "WEAPON LOADOUT":
			loadout_button = shortcut
	save_error = _label(detail_body, "", Vector2.ZERO, 12, Color("ed8c82"), false)
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _save_preferences() -> void:
	preferences.save()
	save_error.text = "Could not save preferences." if preferences.last_error != OK else ""

func _back() -> void:
	binding_action = &""
	if not detail_history.is_empty():
		var previous: Dictionary = detail_history.pop_back()
		restoring_page = true
		_restore_detail(previous.title)
		restoring_page = false
		var controls: Array[Control] = []
		FocusNavigation.collect(detail, controls)
		if previous.focus >= 0 and previous.focus < controls.size():
			controls[previous.focus].grab_focus()
		return
	detail_title = ""
	detail.hide()
	home.show()
	_refresh_focus()
	if is_instance_valid(return_focus):
		return_focus.grab_focus()
	else:
		play_button.grab_focus()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	return style

func _button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(224, 30)
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 8)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color("0a111c") if primary else IVORY)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("101d2b"), GOLD if primary else Color("4d626f")))
	button.add_theme_stylebox_override("hover", _style(IVORY if primary else Color("293847"), IVORY))
	button.add_theme_stylebox_override("pressed", _style(GOLD if primary else Color("354351"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, IVORY))
	button.pressed.connect(func(): sounds.play(&"ui"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _label(parent: Node, text: String, point: Vector2, font_size: int, color: Color, pixel: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if pixel:
		label.add_theme_font_override("font", pixel_font)
	parent.add_child(label)
	return label

func _draw() -> void:
	draw_texture_rect(COURTYARD, Rect2(0, 0, 640, 360), false)
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.04, 0.07, 0.67))
	draw_rect(Rect2(0, 0, 296, 360), Color(0.02, 0.04, 0.07, 0.84))
	draw_line(Vector2(296, 25), Vector2(296, 329), Color("6b573a"))
	draw_line(Vector2(36, 163), Vector2(260, 163), GOLD)
	draw_line(Vector2(36, 332), Vector2(604, 332), Color("6b573a"))
	# Code-native pixel sword and rising embers; no new external art.
	if is_hub:
		return
	var center := Vector2(461, 161)
	draw_arc(center, 83, 0, TAU, 64, Color("5c5542"), 1.0)
	draw_arc(center, 89, -PI * 0.8, PI * 0.15, 40, GOLD, 1.0)
	for index in range(26):
		var progress := fmod(clock * 0.15 + float(index) / 26.0, 1.0)
		var x := 461.0 + sin(index * 7.3) * (10.0 + progress * 38.0)
		var y := 228.0 - progress * 167.0
		var tint := Color("ed9956")
		tint.a = (1.0 - progress) * 0.65
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 3)), tint)
	for index in range(11):
		var y := 85.0 + index * 13.0
		var sway := sin(clock * 2.0 + index * 1.8) * 3.0
		var width := 9.0 + sin(index * 2.3 + clock) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(461, y + 23), Vector2(461 - width, y + 10), Vector2(450 + sway, y - 16), Vector2(461, y), Vector2(472 + sway, y - 10), Vector2(461 + width, y + 10)]), Color("ac512f"))
	draw_colored_polygon(PackedVector2Array([Vector2(461, 65), Vector2(468, 91), Vector2(467, 226), Vector2(455, 226), Vector2(454, 91)]), IVORY)
	draw_colored_polygon(PackedVector2Array([Vector2(461, 65), Vector2(461, 226), Vector2(455, 226), Vector2(454, 91)]), Color("92c6c5"))
	draw_rect(Rect2(438, 225, 46, 5), GOLD)
	draw_rect(Rect2(457, 230, 8, 23), Color("4b6670"))
	for y in [233, 240, 247]:
		draw_line(Vector2(457, y), Vector2(465, y), GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(461, 251), Vector2(467, 257), Vector2(461, 263), Vector2(455, 257)]), GOLD)


func _show_audio() -> void:
	_open_detail("AUDIO")
	detail_body.add_theme_constant_override("separation", 6)
	var first_slider: HSlider
	for bus in Preferences.AUDIO_BUSES:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 28
		detail_body.add_child(row)
		var caption := _label(row, bus.to_upper(), Vector2.ZERO, 8, IVORY)
		caption.custom_minimum_size.x = 74
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(228, 24)
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 5.0
		slider.value = preferences.volumes[bus] * 100.0
		slider.tooltip_text = "%s volume. Left / right to adjust; zero mutes." % bus
		slider.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
		row.add_child(slider)
		var amount := _label(row, "%d%%" % slider.value, Vector2.ZERO, 8, GOLD)
		amount.custom_minimum_size.x = 54
		slider.value_changed.connect(func(value):
			preferences.set_volume(bus, value / 100.0)
			amount.text = "%d%%" % value
			_save_preferences())
		if first_slider == null:
			first_slider = slider
	save_error = _label(detail_body, "", Vector2.ZERO, 12, Color("ed8c82"), false)
	_refresh_focus()
	first_slider.grab_focus()


func _show_bindings() -> void:
	_open_detail("KEYBOARD")
	detail_body.add_theme_constant_override("separation", 2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	detail_body.add_child(grid)
	var names := ["LEFT", "RIGHT", "UP", "DOWN", "FIRE", "MELEE", "DASH", "RESTART"]
	var first: Button
	for index in range(Preferences.REMAPPABLE.size()):
		var action: StringName = Preferences.REMAPPABLE[index]
		var keys := PackedStringArray()
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode))
		var button := _button(grid, names[index] + ": " + "/".join(keys), func(): _capture_binding(action))
		button.custom_minimum_size = Vector2(190, 26)
		if first == null:
			first = button
	var reset := _button(grid, "RESTORE DEFAULTS", func():
		preferences.reset_bindings()
		preferences.save()
		_show_bindings()
		if preferences.last_error != OK:
			binding_status.text = "Applied, but could not save preferences.")
	reset.custom_minimum_size = Vector2(190, 26)
	binding_status = _label(detail_body, "Choose an action, then press a key. Escape cancels.", Vector2.ZERO, 12, MUTED, false)
	_label(detail_body, "Mouse fire and Escape pause stay available.", Vector2.ZERO, 12, MUTED, false)
	_refresh_focus()
	first.grab_focus()

func _capture_binding(action: StringName) -> void:
	binding_action = action
	binding_status.text = "Press a key for %s. Escape cancels." % String(action).trim_prefix("move_").to_upper()


func _refresh_focus() -> void:
	var controls: Array[Control] = []
	FocusNavigation.collect(detail if detail.visible else home, controls)
	FocusNavigation.ring(controls)


func _show_loadout() -> void:
	_open_detail("WEAPON LOADOUT")
	detail_body.add_theme_constant_override("separation", 7)
	for entry in [[&"blade", "BLADE RIFLE", "Precise single shots. Fast fire; reliable at range."], [&"scatter", "EMBER FAN", "Five-shot spread. Slow fire; strongest up close."]]:
		var id: StringName = entry[0]
		var button := _button(detail_body, ("SELECTED: " if preferences.selected_weapon == id else "EQUIP: ") + entry[1], _equip_weapon.bind(id))
		button.icon = GameIcons.get_icon(id)
		button.add_theme_constant_override("icon_max_width", 16)
		button.custom_minimum_size = Vector2(392, 30)
		_label(detail_body, entry[2], Vector2.ZERO, 12, MUTED, false)
	_label(detail_body, "Choose before entering. Blessings reset each run.", Vector2.ZERO, 12, MUTED, false)
	save_error = _label(detail_body, "", Vector2.ZERO, 12, Color("ed8c82"), false)
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _equip_weapon(id: StringName) -> void:
	if id not in [&"blade", &"scatter"]:
		return
	preferences.selected_weapon = id
	preferences.save()
	_show_loadout()
	save_error.text = "Could not save weapon choice." if preferences.last_error != OK else ""


func _show_modes() -> void:
	_open_detail("CHOOSE ARENA")
	detail_body.add_theme_constant_override("separation", 8)
	var finite := _button(detail_body, "COURTYARD RUN", _start_game.bind(true))
	finite.custom_minimum_size.x = 392
	_label(detail_body, "Nine waves, three blessings, then the Warden.", Vector2.ZERO, 12, MUTED, false)
	var endless := _button(detail_body, "ENDLESS ARENA", _start_game.bind(false))
	endless.custom_minimum_size.x = 392
	_label(detail_body, "Survive repeating encounters. Chase your records.", Vector2.ZERO, 12, MUTED, false)
	var finite_records = ArenaRecords.new("user://finite_records.json")
	finite_records.load_records()
	_label(detail_body, "COURTYARD VICTORIES: %d" % finite_records.data["wins"], Vector2.ZERO, 8, GOLD)
	var profile = GlobalProfile.for_tree(get_tree())
	profile.load_profile()
	_label(detail_body, "GLOBAL XP %d / 1900   LEVEL %d" % [profile.data.xp, GlobalProfile.level(profile.data.xp)], Vector2.ZERO, 8, GOLD)
	if profile.last_error != OK:
		_label(detail_body, "Progression unavailable: profile cannot be saved.", Vector2.ZERO, 12, MUTED, false)
	elif profile.load_status in [&"recovered", &"reset"]:
		_label(detail_body, "Profile recovered from backup or reset after corruption.", Vector2.ZERO, 11, MUTED, false)
	_refresh_focus()
	finite.grab_focus()


func _enter_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/main/hub.tscn")

func _return_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/main/menu.tscn")

func _build_hub_overview() -> void:
	var profile = GlobalProfile.for_tree(get_tree())
	profile.load_profile()
	var panel := Panel.new()
	panel.position = Vector2(326, 62)
	panel.size = Vector2(280, 194)
	panel.add_theme_stylebox_override("panel", _style(Color("0c1521"), GOLD))
	home.add_child(panel)
	_label(panel, "THE EXILE'S PATH", Vector2(16, 15), 12, GOLD)
	_label(panel, "LEVEL %d" % GlobalProfile.level(profile.data.xp), Vector2(16, 45), 16, IVORY)
	_label(panel, "GLOBAL XP %d / 1900" % profile.data.xp, Vector2(16, 76), 8, GOLD)
	_label(panel, "SKILL POINTS %d" % (GlobalProfile.level(profile.data.xp) - 1), Vector2(16, 96), 8, IVORY)
	var caption := "XP endures. Blessings reset each run."
	if profile.last_error != OK:
		caption = "Progression unavailable. Check your save."
	elif profile.load_status in [&"recovered", &"reset"]:
		caption = "Profile recovered after a save problem."
	_label(panel, caption, Vector2(16, 127), 12, MUTED, false)
	_label(panel, "Prepare a weapon. Choose your arena.", Vector2(16, 151), 12, MUTED, false)

func _show_progression() -> void:
	_open_detail("GLOBAL PROGRESSION")
	detail_body.add_theme_constant_override("separation", 9)
	var profile = GlobalProfile.for_tree(get_tree())
	profile.load_profile()
	var level_label := _label(detail_body, "LEVEL %d   /   GLOBAL XP %d" % [GlobalProfile.level(profile.data.xp), profile.data.xp], Vector2.ZERO, 12, GOLD)
	var xp_icon := TextureRect.new()
	xp_icon.texture = GameIcons.get_icon(&"xp")
	xp_icon.position = Vector2(370, 0)
	xp_icon.size = Vector2(16, 16)
	xp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_child(xp_icon)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(392, 20)
	bar.max_value = 100
	bar.value = 100 if profile.data.xp == 1900 else profile.data.xp % 100
	bar.add_theme_stylebox_override("background", _style(Color("101d2b"), GOLD))
	bar.add_theme_stylebox_override("fill", _style(Color("63b7b3"), GOLD))
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_body.add_child(bar)
	_label(detail_body, "MAXIMUM LEVEL" if profile.data.xp == 1900 else "%d / 100 XP TO NEXT LEVEL" % (profile.data.xp % 100), Vector2.ZERO, 8, IVORY)
	_label(detail_body, "SKILL POINTS AVAILABLE: %d" % (GlobalProfile.level(profile.data.xp) - 1), Vector2.ZERO, 8, GOLD)
	_label(detail_body, "Victories and defeats earn global XP in both arenas.", Vector2.ZERO, 12, MUTED, false)
	_label(detail_body, "Blessings last one run. Global XP lasts between runs.", Vector2.ZERO, 12, MUTED, false)
	if profile.last_error != OK:
		_label(detail_body, "Profile cannot be saved. XP is unavailable.", Vector2.ZERO, 12, Color("ed8c82"), false)
	_refresh_focus()
	back_button.grab_focus()

func _show_feedback_options() -> void:
	_open_detail("COMBAT FEEDBACK")
	for entry in [["Hit-stop", "hit_stop"], ["Screen shake", "screen_shake"]]:
		var toggle := CheckButton.new()
		var key: String = entry[1]
		toggle.text = entry[0]
		toggle.button_pressed = preferences.get(key)
		toggle.custom_minimum_size.y = 34
		toggle.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
		detail_body.add_child(toggle)
		toggle.toggled.connect(func(value): preferences.set(key, value); _save_preferences())
	_label(detail_body, "Reduce visual motion also disables both effects.", Vector2.ZERO, 12, MUTED, false)
	save_error = _label(detail_body, "", Vector2.ZERO, 12, Color("ed8c82"), false)
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _show_play() -> void:
	_open_detail("PLAY")
	detail_body.add_theme_constant_override("separation", 4)
	for entry in [["SANCTUARY", _enter_hub], ["ARENAS", _show_modes], ["ROGUELITE", _show_work_in_progress.bind("ROGUELITE")], ["CAMPAIGN", _show_work_in_progress.bind("CAMPAIGN")], ["SOUNDTRACK", _show_work_in_progress.bind("SOUNDTRACK")], ["QUIT", func(): Music.for_tree(get_tree()).quit_game()]]:
		var button := _button(detail_body, entry[0], entry[1])
		button.custom_minimum_size = Vector2(392, 24)
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _show_work_in_progress(feature: String) -> void:
	_open_detail(feature)
	_label(detail_body, "WORK IN PROGRESS", Vector2.ZERO, 16, GOLD)
	var caption := _label(detail_body, "This feature is still in development.\nReturn to Play to visit Sanctuary or enter an Arena.", Vector2.ZERO, 12, MUTED, false)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_focus()
	back_button.grab_focus()

func _restore_detail(title: String) -> void:
	var pages := {
		"PLAY": _show_play, "CHOOSE ARENA": _show_modes,
		"OPTIONS": _show_options, "HOW TO PLAY": _show_controls,
		"AUDIO": _show_audio, "KEYBOARD": _show_bindings,
		"WEAPON LOADOUT": _show_loadout, "GLOBAL PROGRESSION": _show_progression,
		"COMBAT FEEDBACK": _show_feedback_options,
	}
	if pages.has(title):
		pages[title].call()
	else:
		_show_work_in_progress(title)
