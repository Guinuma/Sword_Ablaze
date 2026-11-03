extends RefCounted
## Local visual and audio preferences; never modifies combat stats or timing.
var path: String
var reduced_flashes: bool = false
var reduced_motion: bool = false
const AUDIO_BUSES = ["Master", "Music", "SFX", "UI"]
var volumes: Dictionary = {"Master": 1.0, "Music": 1.0, "SFX": 1.0, "UI": 1.0}
var last_error: Error = OK
var unsupported_version: bool = false


func _init(file_path: String = "user://preferences.json") -> void:
	path = file_path


func load_preferences() -> void:
	unsupported_version = false
	var data := _read(path)
	if data.is_empty():
		data = _read(path + ".bak")
	reduced_flashes = data.get("reduced_flashes", false)
	reduced_motion = data.get("reduced_motion", false)
	var audio: Dictionary = data.get("volumes", {}) if data.get("volumes", {}) is Dictionary else {}
	for bus in AUDIO_BUSES:
		var value = audio.get(bus, 1.0)
		volumes[bus] = clampf(float(value), 0.0, 1.0) if (value is float or value is int) and is_finite(float(value)) else 1.0
	apply_audio()


func save() -> Error:
	if unsupported_version:
		last_error = ERR_UNAVAILABLE
		return last_error
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify({"version": 1, "reduced_flashes": reduced_flashes, "reduced_motion": reduced_motion, "volumes": volumes}))
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
