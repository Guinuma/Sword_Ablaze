extends RefCounted
## Versioned local arena records. No XP or reward economy is implied.
const VERSION: int = 1
var path: String
var data: Dictionary = _defaults()
var last_error: Error = OK
var unsupported_version: bool = false


func _init(file_path: String = "user://arena_records.json") -> void:
	path = file_path


func load_records() -> void:
	unsupported_version = false
	data = _read(path)
	if data.is_empty():
		data = _read(path + ".bak")
	if data.is_empty():
		data = _defaults()


func record(wave: int, kills: int, elapsed: float) -> Error:
	data["runs"] += 1
	data["best_wave"] = maxi(data["best_wave"], wave)
	data["best_kills"] = maxi(data["best_kills"], kills)
	data["best_seconds"] = maxf(data["best_seconds"], elapsed)
	last_error = _save()
	return last_error


func _save() -> Error:
	if unsupported_version:
		return ERR_UNAVAILABLE
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK:
		return result
	# Only a validated primary may replace the recovery copy.
	if not _read(path).is_empty():
		result = DirAccess.copy_absolute(path, path + ".bak")
		if result != OK:
			return result
	return DirAccess.rename_absolute(temporary, path)


func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var parsed = json.data
	if parsed is Dictionary and (parsed.get("version") is int or parsed.get("version") is float) and parsed["version"] > VERSION:
		unsupported_version = true
	if not parsed is Dictionary or parsed.get("version") != VERSION:
		return {}
	var clean := _defaults()
	for field in ["runs", "best_wave", "best_kills", "best_seconds"]:
		var value = parsed.get(field)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0.0 or value > 1000000000.0:
			return {}
		if field != "best_seconds" and float(value) != floorf(float(value)):
			return {}
		clean[field] = float(value) if field == "best_seconds" else int(value)
	return clean


static func _defaults() -> Dictionary:
	return {"version": VERSION, "runs": 0, "best_wave": 0, "best_kills": 0, "best_seconds": 0.0}
