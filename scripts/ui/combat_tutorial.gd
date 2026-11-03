extends RefCounted
## Action-driven hints use simulation events, so pause cannot advance them.
var step := 0
var moved := 0.0
var aimed := 0.0

func observe(delta: float, movement: Vector2, aim_changed: bool) -> void:
	if step == 0 and movement.length_squared() > 0.0:
		moved += delta
		if moved >= 0.5:
			step = 1
	elif step == 1 and aim_changed:
		aimed += delta
		if aimed >= 0.08:
			step = 2

func shot() -> void:
	if step == 2:
		step = 3

func dashed() -> void:
	if step == 3:
		step = 4

func chose_upgrade() -> void:
	if step == 4:
		step = 5

func reset() -> void:
	step = 0
	moved = 0.0
	aimed = 0.0

func hint() -> String:
	match step:
		0: return "MOVE: " + key_name(&"move_up") + "/" + key_name(&"move_left") + "/" + key_name(&"move_down") + "/" + key_name(&"move_right")
		1: return "AIM: MOVE THE MOUSE"
		2: return "FIRE: CLICK / " + key_name(&"fire")
		3: return "DASH: " + key_name(&"dash") + " + DIRECTION"
		4: return "WAVE 3: PICK WITH CLICK / ENTER"
	return ""

static func key_name(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode).to_upper()
	return "?"
