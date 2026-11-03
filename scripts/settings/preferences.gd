extends RefCounted
## Local presentation, input and starting-loadout preferences.
var path: String
var reduced_flashes: bool = false
var reduced_motion: bool = false
const AUDIO_BUSES = ["Master", "Music", "SFX", "UI"]
var volumes: Dictionary = {"Master": 1.0, "Music": 1.0, "SFX": 1.0, "UI": 1.0}
const REMAPPABLE = [&"move_left", &"move_right", &"move_up", &"move_down", &"fire", &"dash", &"reset_sandbox"]
var bindings: Dictionary = {}
var selected_weapon: StringName = &"blade"
var last_error: Error = OK
var unsupported_version: bool = false


func _init(file_path: String = "user://preferences.json") -> void:
	path = file_path


func load_preferences() -> void:
	unsupported_version = false
	var data := _read(path)
	if data.is_empty():
		data = _read(path + ".bak")
	var weapon_id = data.get("selected_weapon", "blade")
	selected_weapon = StringName(weapon_id) if weapon_id is String and weapon_id in ["blade", "scatter"] else &"blade"
	reduced_flashes = data.get("reduced_flashes", false)
	reduced_motion = data.get("reduced_motion", false)
	var audio: Dictionary = data.get("volumes", {}) if data.get("volumes", {}) is Dictionary else {}
	for bus in AUDIO_BUSES:
		var value = audio.get(bus, 1.0)
		volumes[bus] = clampf(float(value), 0.0, 1.0) if (value is float or value is int) and is_finite(float(value)) else 1.0
	apply_audio()
	bindings.clear()
	var stored = data.get("bindings", {})
	if stored is Dictionary:
		for action in REMAPPABLE:
			var code = stored.get(String(action), 0)
			if (code is int or code is float) and is_finite(float(code)) and float(code) == floor(float(code)) and _valid_key(int(code)):
				bindings[action] = int(code)
	apply_bindings()


func save() -> Error:
	if unsupported_version:
		last_error = ERR_UNAVAILABLE
		return last_error
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify({"version": 1, "reduced_flashes": reduced_flashes, "reduced_motion": reduced_motion, "volumes": volumes, "bindings": bindings, "selected_weapon": selected_weapon}))
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error != OK:
		return last_error
	if not _read(path).is_empty():
		last_error = DirAccess.copy_absolute(path, path + ".bak")
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(path + ".tmp", path)
	return last_error


func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.data
	if not data is Dictionary:
		return {}
	if (data.get("version") is int or data.get("version") is float) and data["version"] > 1:
		unsupported_version = true
	if data.get("version") != 1 or not data.get("reduced_flashes") is bool or not data.get("reduced_motion") is bool:
		return {}
	return data


func set_volume(bus: String, value: float) -> void:
	if bus not in AUDIO_BUSES or not is_finite(value):
		return
	volumes[bus] = clampf(value, 0.0, 1.0)
	apply_audio()


func apply_audio() -> void:
	for bus in AUDIO_BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var value: float = volumes[bus]
			AudioServer.set_bus_mute(index, value <= 0.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


func _valid_key(code: int) -> bool:
	return code > 0 and code < (1 << 23) and code != KEY_ESCAPE and not OS.get_keycode_string(code).is_empty()

func set_binding(action: StringName, code: int) -> bool:
	if action not in REMAPPABLE or not _valid_key(code):
		return false
	# Reject conflicts with all other active keyboard bindings.
	for other in REMAPPABLE:
		if other == action:
			continue
		for event in InputMap.action_get_events(other):
			if event is InputEventKey and (event.physical_keycode == code or event.keycode == code):
				return false
	bindings[action] = code
	apply_bindings()
	return true

func apply_bindings() -> void:
	for action in REMAPPABLE:
		InputMap.action_erase_events(action)
		var defaults: Dictionary = ProjectSettings.get_setting("input/" + String(action), {})
		for event in defaults.get("events", []):
			if not (event is InputEventKey) or not bindings.has(action):
				InputMap.action_add_event(action, event)
		if bindings.has(action):
			var key := InputEventKey.new()
			key.physical_keycode = bindings[action]
			InputMap.action_add_event(action, key)

func reset_bindings() -> void:
	bindings.clear()
	apply_bindings()
