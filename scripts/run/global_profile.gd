extends RefCounted
## Transactional local progression store; combat integration is a separate layer.
const VERSION := 1
const XP_CAP := 1900
const SEQUENCE_LIMIT := 1000000000
var path: String
var data: Dictionary = defaults()
var last_error: Error = OK
var unsupported_version := false
var load_status: StringName = &"new"

func _init(file_path: String = "user://profile.json") -> void:
	path = file_path

static func defaults() -> Dictionary:
	return {"version": VERSION, "xp": 0, "next_run_id": 1, "last_settled_run_id": 0, "active_run": {"id": 0, "mode": ""}, "skills": [], "unlocks": []}

static func level(xp: int) -> int:
	return 1 + clampi(xp, 0, XP_CAP) / 100

static func reward(kills: int, cleared_waves: int, victory: bool) -> int:
	return clampi(kills, 0, 100) + 10 * clampi(cleared_waves, 0, 10) + (100 if victory else 0)

func load_profile() -> void:
	unsupported_version = false
	last_error = OK
	data = _read(path)
	load_status = &"loaded"
	if data.is_empty():
		data = _read(path + ".bak")
		load_status = &"recovered"
	if data.is_empty():
		data = defaults()
		load_status = &"reset" if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") else &"new"
	if unsupported_version:
		load_status = &"future_version"
		last_error = ERR_UNAVAILABLE
	elif load_status == &"new":
		_commit(data)

func begin_run(mode: StringName) -> int:
	if mode not in [&"courtyard", &"endless"] or data.next_run_id >= SEQUENCE_LIMIT:
		last_error = ERR_INVALID_PARAMETER
		return 0
	var candidate := data.duplicate(true)
	var id: int = candidate.next_run_id
	candidate.next_run_id += 1
	candidate.active_run = {"id": id, "mode": String(mode)}
	return id if _commit(candidate) == OK else 0

func settle(id: int, mode: StringName, outcome: StringName, kills: int, cleared_waves: int) -> Dictionary:
	if id <= 0 or id != data.active_run.id or id <= data.last_settled_run_id or String(mode) != data.active_run.mode:
		last_error = ERR_INVALID_PARAMETER
		return {"ok": false, "awarded": 0, "error": last_error}
	if outcome not in [&"victory", &"defeat"] or (outcome == &"victory" and (mode != &"courtyard" or cleared_waves != 10)) or kills < 0 or cleared_waves < 0:
		last_error = ERR_INVALID_PARAMETER
		return {"ok": false, "awarded": 0, "error": last_error}
	var candidate := data.duplicate(true)
	var awarded := mini(XP_CAP - int(candidate.xp), reward(kills, cleared_waves, outcome == &"victory"))
	candidate.xp += awarded
	candidate.last_settled_run_id = id
	candidate.active_run = {"id": 0, "mode": ""}
	var error := _commit(candidate)
	return {"ok": error == OK, "awarded": awarded if error == OK else 0, "error": error}

func _commit(candidate: Dictionary) -> Error:
	if unsupported_version:
		last_error = ERR_UNAVAILABLE
		return last_error
	var clean := _clean(candidate)
	if clean.is_empty():
		last_error = ERR_INVALID_DATA
		return last_error
	var primary := _read(path)
	if unsupported_version:
		last_error = ERR_UNAVAILABLE
		return last_error
	var output := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if output == null:
		last_error = FileAccess.get_open_error()
		return last_error
	output.store_string(JSON.stringify(clean))
	output.flush()
	last_error = output.get_error()
	output.close()
	if last_error != OK:
		return last_error
	if _read(path + ".tmp").is_empty():
		last_error = ERR_FILE_CORRUPT
		return last_error
	if not primary.is_empty():
		last_error = DirAccess.copy_absolute(path, path + ".bak")
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(path + ".tmp", path)
	if last_error == OK:
		data = clean
	return last_error

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var input := FileAccess.open(file_path, FileAccess.READ)
	if input == null or input.get_length() > 65536:
		return {}
	var json := JSON.new()
	if json.parse(input.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	var parsed: Dictionary = json.data
	if (parsed.get("version") is int or parsed.get("version") is float) and parsed.version > VERSION:
		unsupported_version = true
	return _clean(parsed)

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and float(value) == floorf(float(value))

static func _clean(parsed: Dictionary) -> Dictionary:
	if not _integer(parsed.get("version"), VERSION, VERSION) or not _integer(parsed.get("xp"), 0, XP_CAP) or not _integer(parsed.get("next_run_id"), 1, SEQUENCE_LIMIT) or not _integer(parsed.get("last_settled_run_id"), 0, SEQUENCE_LIMIT - 1):
		return {}
	var active = parsed.get("active_run")
	if not active is Dictionary or not _integer(active.get("id"), 0, SEQUENCE_LIMIT - 1):
		return {}
	if parsed.next_run_id <= parsed.last_settled_run_id or active.id >= parsed.next_run_id:
		return {}
	if (active.id == 0 and active.get("mode") != "") or (active.id > 0 and (active.id <= parsed.last_settled_run_id or active.get("mode") not in ["courtyard", "endless"])):
		return {}
	# No purchasable definitions exist yet; reserved ID lists must remain empty.
	for field in ["skills", "unlocks"]:
		if not parsed.get(field) is Array or not parsed[field].is_empty():
			return {}
	return {"version": VERSION, "xp": int(parsed.xp), "next_run_id": int(parsed.next_run_id), "last_settled_run_id": int(parsed.last_settled_run_id), "active_run": {"id": int(active.id), "mode": String(active.mode)}, "skills": [], "unlocks": []}


static func for_tree(tree: SceneTree):
	return load("res://scripts/run/global_profile.gd").new(String(tree.get_meta("profile_path", "user://profile.json")))
