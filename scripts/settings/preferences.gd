extends RefCounted
## Local visual preferences; never modifies combat stats or timing.
var path: String
var reduced_flashes: bool = false
var reduced_motion: bool = false
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


func save() -> Error:
	if unsupported_version:
		last_error = ERR_UNAVAILABLE
		return last_error
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify({"version": 1, "reduced_flashes": reduced_flashes, "reduced_motion": reduced_motion}))
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
