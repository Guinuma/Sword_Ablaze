extends "res://scripts/ui/main_menu.gd"
## A safe walkable home; menus reuse the existing scene/reward/preferences boundary.
const Layout = preload("res://scripts/hub/sanctuary_layout.gd")
const Furnishing = preload("res://scripts/hub/sanctuary_art.gd")
const ExileVisual = preload("res://scripts/player/exile_visual.gd")
const PlayerState = preload("res://scripts/player/player_state.gd")
const FLOOR = preload("res://assets/art/arena/courtyard-floor-02.svg")
var player = PlayerState.new()
var geometry = Layout.geometry()
var world: Node2D
var player_visual: Node2D
var shade: Node2D
var prompt: Button
var nearby: Dictionary = {}
var facing := Vector2.DOWN
var profile_caption: Label
var movement_caption: Label
var pause_on_focus_loss := true

func _ready() -> void:
	super._ready()
	for child in home.get_children():
		home.remove_child(child)
		child.queue_free()
	for child in get_children():
		if child is Label:
			child.queue_free()
	home.z_index = 5
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.z_index = 10
	_label(home, "SANCTUARY", Vector2(30, 12), 12, GOLD)
	_label(home, "HOME OF THE EXILE", Vector2(30, 31), 8, MUTED)
	profile_caption = _label(home, "", Vector2(298, 16), 8, IVORY)
	_refresh_profile()
	var menu := _button(home, "MENU [ESC]", _show_hub_menu)
	menu.position = Vector2(510, 12)
	menu.custom_minimum_size = Vector2(100, 27)
	menu.size = Vector2(100, 27)
	menu.focus_mode = Control.FOCUS_NONE
	prompt = _button(home, "Walk closer to Gabriel, the arsenal or the door", _interact_nearest)
	prompt.position = Vector2(164, 328)
	prompt.custom_minimum_size = Vector2(446, 24)
	prompt.focus_mode = Control.FOCUS_NONE
	play_button = prompt
	movement_caption = _label(home, "", Vector2(30, 335), 8, GOLD)
	movement_caption.size = Vector2(124, 18)
	movement_caption.clip_text = true
	movement_caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	for item in Layout.FURNITURE:
		var prop := Furnishing.new()
		prop.kind = item.kind
		prop.position = item.base.get_center()
		world.add_child(prop)
	player.geometry = geometry
	player.player_position = Layout.START
	player_visual = ExileVisual.new()
	world.add_child(player_visual)
	_present_player(0.0, Vector2.ZERO)
	shade = Node2D.new()
	shade.z_index = 8
	shade.draw.connect(func():
		if detail.visible:
			shade.draw_rect(Rect2(0, 0, 640, 360), Color(0.015, 0.025, 0.045, 0.72)))
	add_child(shade)
	var sign_positions := {&"gabriel": Vector2(486, 163), &"arsenal": Vector2(97, 176), &"door": Vector2(282, 294)}
	for station in Layout.STATIONS:
		var sign := Panel.new()
		sign.position = sign_positions[station.id]
		sign.size = Vector2(78, 18)
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign.add_theme_stylebox_override("panel", _style(Color("182631"), Color("79694e")))
		home.add_child(sign)
		_label(sign, station.label, Vector2(6, 1), 8, GOLD)
	_update_prompt()

func _build_hub_overview() -> void:
	pass

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(shade):
		shade.queue_redraw()

func _physics_process(delta: float) -> void:
	if detail.visible or starting:
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	advance_walk(delta, movement)

func advance_walk(delta: float, movement: Vector2) -> void:
	if detail.visible or starting:
		return
	movement = movement.limit_length(1.0)
	if movement.length_squared() > 0.01:
		facing = movement.normalized()
	player.advance(delta, movement, player.player_position + facing * 100, false, false, Layout.BOUNDS, false)
	_present_player(delta, movement)
	_update_prompt()

func _present_player(delta: float, movement: Vector2) -> void:
	player_visual.reduced_motion = preferences.reduced_motion
	player_visual.reduced_flashes = preferences.reduced_flashes
	player_visual.present(player.player_position, facing, movement, delta, false, false, false)

func _update_prompt() -> void:
	nearby = Layout.nearest(player.player_position, geometry)
	prompt.disabled = nearby.is_empty()
	prompt.text = "Walk closer to Gabriel, the arsenal or the door" if nearby.is_empty() else "ENTER / SPACE - " + nearby.action
	movement_caption.text = "/".join([ControlNames.key_name(&"move_up"), ControlNames.key_name(&"move_left"), ControlNames.key_name(&"move_down"), ControlNames.key_name(&"move_right")])

func _interact_nearest() -> void:
	if detail.visible or starting:
		return
	_update_prompt()
	if nearby.is_empty():
		return
	match nearby.id:
		&"gabriel": _show_gabriel()
		&"arsenal": _show_loadout()
		&"door": _show_departure()

func _unhandled_input(event: InputEvent) -> void:
	if detail.visible:
		super._unhandled_input(event)
	elif event.is_action_pressed("ui_cancel"):
		_show_hub_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		_interact_nearest()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and pause_on_focus_loss and not detail.visible and not starting:
		_show_hub_menu()

func _back() -> void:
	if not detail_history.is_empty():
		super._back()
		return
	binding_action = &""
	detail_title = ""
	detail.hide()
	home.show()
	get_viewport().gui_release_focus()
	_refresh_profile()
	_update_prompt()
	_present_player(0.0, Vector2.ZERO)
	shade.queue_redraw()

func _refresh_profile() -> void:
	var profile = GlobalProfile.for_tree(get_tree())
	profile.load_profile()
	profile_caption.text = "LEVEL %d   GLOBAL XP %d" % [GlobalProfile.level(profile.data.xp), profile.data.xp]
	if profile.last_error != OK:
		profile_caption.text = "GLOBAL XP UNAVAILABLE"
	elif profile.load_status in [&"recovered", &"reset"]:
		profile_caption.text += " (RECOVERED)"

func _show_gabriel() -> void:
	_open_detail("GABRIEL")
	_label(detail_body, "Knowledge is a light no exile can lose.", Vector2.ZERO, 13, IVORY, false)
	_label(detail_body, "Rest here. When you are ready, seek Michael's flame.", Vector2.ZERO, 12, MUTED, false)
	_button(detail_body, "SKILL TREE", _show_skill_tree)
	_button(detail_body, "GLOBAL PROGRESSION", _show_progression)
	_refresh_focus()
	detail_body.get_child(3).grab_focus()

var skill_buttons: Dictionary = {}
var skill_status: Label

func _show_skill_tree(message: String = "") -> void:
	_open_detail("GABRIEL'S KNOWLEDGE")
	detail_body.get_child(0).custom_minimum_size.y = 24
	detail_body.add_theme_constant_override("separation", 4)
	var profile = GlobalProfile.for_tree(get_tree())
	profile.load_profile()
	_label(detail_body, "MICHAEL / MAIN   -   POINTS: %d" % profile.skill_points(), Vector2.ZERO, 8, GOLD)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	detail_body.add_child(columns)
	skill_buttons.clear()
	for branch in GlobalProfile.Skills.BRANCHES:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 125
		column.add_theme_constant_override("separation", 4)
		columns.add_child(column)
		_label(column, branch.title + "\n" + branch.theme, Vector2.ZERO, 8, GOLD)
		for definition in GlobalProfile.Skills.NODES:
			if definition.branch != branch.id:
				continue
			var learned: bool = definition.id in profile.data.skills
			var ready: bool = definition.requires == "" or definition.requires in profile.data.skills
			var state := "LEARNED" if learned else "LOCKED" if not ready else "LEARN: %d PT" % definition.cost
			if not learned and ready and profile.skill_points() < definition.cost:
				state = "NEED %d PT" % definition.cost
			var description: String = definition.description
			for weapon in Preferences.Weapons.WEAPONS.values():
				if weapon.node == definition.id:
					description += "\n" + weapon.name
			var button := _button(column, state + "\n" + definition.name + "\n" + description, _buy_skill.bind(definition.id), branch.id == "michael")
			button.custom_minimum_size = Vector2(125, 40)
			button.disabled = learned or not ready or profile.skill_points() < definition.cost or profile.last_error != OK
			button.tooltip_text = description + (". Requires " + GlobalProfile.Skills.node(definition.requires).get("name", "") if definition.requires != "" else ". Root knowledge")
			skill_buttons[definition.id] = button
	skill_status = _label(detail_body, message if message != "" else "Michael unlocks weapons. Gabriel and Raphael gear is in development.", Vector2.ZERO, 11, MUTED, false)
	skill_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if profile.last_error != OK:
		skill_status.text = "Profile unavailable. Purchases are disabled."
	var reset := _button(detail_body, "RESET SKILLS (FREE)", _reset_skills)
	reset.custom_minimum_size.y = 24
	reset.disabled = profile.data.skills.is_empty() or profile.last_error != OK
	_refresh_focus()
	var controls: Array[Control] = []
	FocusNavigation.collect(detail, controls)
	controls[0].grab_focus()

func _buy_skill(id: String) -> void:
	var profile = GlobalProfile.for_tree(get_tree())
	var error: Error = profile.purchase_skill(id)
	_show_skill_tree("Knowledge saved." if error == OK else "Could not learn/save. Points unchanged.")
	_refresh_profile()

func _reset_skills() -> void:
	var profile = GlobalProfile.for_tree(get_tree())
	var error: Error = profile.reset_skills()
	_show_skill_tree("All skill points refunded. XP preserved." if error == OK else "Could not save reset. Skills unchanged.")
	_refresh_profile()

func _show_departure() -> void:
	_open_detail("LEAVE SANCTUARY")
	for entry in [["ARENAS", _show_modes], ["ROGUELITE", _show_work_in_progress.bind("ROGUELITE")], ["CAMPAIGN", _show_work_in_progress.bind("CAMPAIGN")], ["TITLE SCREEN", _return_to_title]]:
		_button(detail_body, entry[0], entry[1])
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _show_hub_menu() -> void:
	_open_detail("SANCTUARY MENU")
	detail_body.add_theme_constant_override("separation", 7)
	for entry in [["RESUME", _back], ["OPTIONS", _show_options], ["TITLE SCREEN", _return_to_title], ["QUIT", func(): Music.for_tree(get_tree()).quit_game()]]:
		_button(detail_body, entry[0], entry[1])
	_refresh_focus()
	detail_body.get_child(1).grab_focus()

func _show_work_in_progress(feature: String) -> void:
	super._show_work_in_progress(feature)
	detail_body.get_child(2).text = "This feature is still in development.\nReturn to the Sanctuary door to enter an Arena."

func _restore_detail(title: String) -> void:
	match title:
		"GABRIEL": _show_gabriel()
		"GABRIEL'S KNOWLEDGE": _show_skill_tree()
		"LEAVE SANCTUARY": _show_departure()
		"SANCTUARY MENU": _show_hub_menu()
		_: super._restore_detail(title)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("0b1422"))
	# Sheltered marble house, midnight outside; integer-grid furniture and warm trim.
	draw_rect(Rect2(38, 52, 564, 276), Color("252c38"))
	draw_rect(Rect2(48, 58, 544, 266), Color("655e54"))
	draw_rect(Rect2(60, 100, 520, 215), Color("43484b"))
	for row in range(7):
		for col in range(17):
			var point := Vector2(60 + col * 32, 100 + row * 32)
			var dimensions := Vector2(minf(32, 580 - point.x), minf(32, 315 - point.y))
			draw_texture_rect_region(FLOOR, Rect2(point, dimensions), Rect2(((col + row * 3) % 4) * 32, 0, dimensions.x, dimensions.y), Color(0.82, 0.84, 0.82))
	for row in range(3):
		for col in range(17):
			var x := 60 + col * 32
			draw_rect(Rect2(x, 58 + row * 13, minf(31, 580 - x), 12), Color("3a414b") if (col + row) % 2 else Color("414952"))
	draw_rect(Rect2(58, 96, 524, 4), GOLD)
	for x in [54, 580]:
		draw_rect(Rect2(x, 58, 6, 261), Color("a08d71"))
		draw_rect(Rect2(x + 1, 62, 2, 249), Color("c7b48a"))
	for x in [190, 415]:
		draw_rect(Rect2(x, 58, 42, 35), GOLD)
		draw_rect(Rect2(x + 3, 61, 36, 29), Color("172c40"))
		draw_rect(Rect2(x + 20, 61, 2, 29), Color("8ca8a5"))
		draw_rect(Rect2(x + 3, 74, 36, 2), Color("8ca8a5"))
		draw_rect(Rect2(x + 7, 65, 2, 2), IVORY)
	# Worn teal rug and stitched borders leave the walking lanes easy to read.
	draw_rect(Rect2(220, 208, 200, 83), Color("294b55"))
	for inset in [3, 8]:
		draw_rect(Rect2(220 + inset, 208 + inset, 200 - inset * 2, 83 - inset * 2), Color("a48b59"), false, 1)
	for x in range(226, 420, 8):
		draw_line(Vector2(x, 206), Vector2(x, 208), Color("b1a07c"))
		draw_line(Vector2(x, 291), Vector2(x, 293), Color("b1a07c"))
	for side in [-1, 1]:
		draw_line(Vector2(320, 223), Vector2(320 + side * 26, 249), GOLD)
		draw_line(Vector2(320 + side * 26, 249), Vector2(320, 275), GOLD)
	# Bottom wall opens onto a sheltered threshold; departure always requires interaction.
	draw_rect(Rect2(54, 315, 239, 12), Color("94816a"))
	draw_rect(Rect2(347, 315, 239, 12), Color("94816a"))
	draw_rect(Rect2(293, 307, 54, 20), Color("755c45"))
	for y in [309, 315, 321]:
		draw_line(Vector2(297, y), Vector2(343, y), GOLD)
	draw_rect(Rect2(0, 0, 640, 48), Color("0b1422"))
	draw_line(Vector2(28, 47), Vector2(612, 47), Color("756247"))
	draw_rect(Rect2(0, 328, 640, 32), Color("0b1422"))
