extends Node2D
## Small initialization sandbox. Placeholder graphics use logical pixel coordinates.

const SPEED: float = 120.0
const BULLET_SPEED: float = 360.0
const FIRE_INTERVAL: float = 0.16
const ARENA := Rect2(24, 64, 592, 272)
var player_position := Vector2(320, 200)
var aim := Vector2.RIGHT
var fire_cooldown: float = 0.0
var bullets: Array[Dictionary] = []


func _ready() -> void:
	_register_input()
	var title := Label.new()
	title.text = "SWORD ABLAZE  /  INITIAL SANDBOX"
	title.position = Vector2(24, 12)
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	var instructions := Label.new()
	instructions.text = "WASD / Arrows: move   |   Mouse: aim   |   Left click / Space: fire   |   R: reset"
	instructions.position = Vector2(24, 38)
	instructions.add_theme_font_size_override("font_size", 12)
	add_child(instructions)


func _register_input() -> void:
	# Define physical keys at startup so the sandbox works on different layouts.
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"fire": [KEY_SPACE], "reset_sandbox": [KEY_R],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_sandbox"):
		player_position = Vector2(320, 200)
		bullets.clear()
		fire_cooldown = 0.0
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += movement * SPEED * delta
	player_position = player_position.clamp(ARENA.position + Vector2(8, 8), ARENA.end - Vector2(8, 8))
	var mouse_direction := get_global_mouse_position() - player_position
	if mouse_direction.length_squared() > 1.0:
		aim = mouse_direction.normalized()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if Input.is_action_pressed("fire") and fire_cooldown <= 0.0:
		bullets.append({"position": player_position + aim * 12.0, "direction": aim})
		fire_cooldown = FIRE_INTERVAL
	for index in range(bullets.size() - 1, -1, -1):
		bullets[index]["position"] += bullets[index]["direction"] * BULLET_SPEED * delta
		if not ARENA.has_point(bullets[index]["position"]):
			bullets.remove_at(index)
	queue_redraw()


func _draw() -> void:
	draw_rect(ARENA, Color("151c2c"))
	for x in range(24, 617, 16):
		draw_line(Vector2(x, 64), Vector2(x, 336), Color("1d2638"))
	for y in range(64, 337, 16):
		draw_line(Vector2(24, y), Vector2(616, y), Color("1d2638"))
	draw_rect(ARENA, Color("61758b"), false, 1.0)
	draw_rect(Rect2(player_position.round() - Vector2(6, 6), Vector2(12, 12)), Color("65dfc1"))
	draw_line(player_position.round(), (player_position + aim * 14.0).round(), Color("fff0b0"), 3.0)
	for bullet in bullets:
		draw_rect(Rect2(Vector2(bullet["position"]).round() - Vector2(2, 2), Vector2(4, 4)), Color("ffb454"))
