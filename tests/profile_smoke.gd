extends SceneTree
const Profile = preload("res://scripts/run/global_profile.gd")
const PATH := "user://profile_smoke.json"
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(PATH + suffix)
func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()
func _run() -> void:
	cleanup()
	check(Profile.reward(999, 99, false) == 200 and Profile.reward(999, 99, true) == 300, "Reward caps must apply equally before finite bonus")
	check(Profile.reward(-1, -1, false) == 0, "Negative reward inputs must never remove XP")
	check(Profile.level(0) == 1 and Profile.level(99) == 1 and Profile.level(100) == 2 and Profile.level(9999) == Profile.max_level(), "Level boundaries must derive from capped XP")
	check(Profile.max_level(400) == 240 and Profile.max_level(23) == 13 and Profile.max_level(0) == 1, "Level cap must floor 60% of total node cost")
	var profile = Profile.new(PATH)
	profile.load_profile()
	check(profile.load_status == &"new" and FileAccess.file_exists(PATH) and profile.data == Profile.defaults(), "Missing profile must create validated initial save")
	var first: int = profile.begin_run(&"courtyard")
	check(first == 1 and profile.data.active_run.id == first and profile.data.next_run_id == 2, "Run ID allocation must persist before reward")
	check(not profile.settle(first, &"endless", &"defeat", 1, 1).ok, "Mode mismatch must reject reward")
	check(not profile.settle(first, &"courtyard", &"victory", 1, 9).ok, "Incomplete finite victory must reject reward")
	var before: Dictionary = profile.data.duplicate(true)
	profile.path = PATH + "/blocked.json"
	check(not profile.settle(first, &"courtyard", &"victory", 115, 10).ok and profile.data == before, "Failed write must preserve XP and pending identity")
	profile.path = PATH
	var result: Dictionary = profile.settle(first, &"courtyard", &"victory", 115, 10)
	check(result.ok and result.awarded == 300 and profile.data.xp == 300, "Successful retry must apply exactly one reward")
	check(not profile.settle(first, &"courtyard", &"victory", 115, 10).ok and profile.data.xp == 300, "Duplicate callback must not add XP")
	var loaded = Profile.new(PATH)
	loaded.load_profile()
	check(loaded.data.xp == 300 and not loaded.settle(first, &"courtyard", &"victory", 115, 10).ok, "Reload must preserve settled identity")
	var abandoned: int = loaded.begin_run(&"endless")
	var next: int = loaded.begin_run(&"endless")
	check(next > abandoned and not loaded.settle(abandoned, &"endless", &"defeat", 100, 10).ok, "New run must supersede unfinished ID without reward")
	check(not loaded.settle(next, &"endless", &"victory", 100, 10).ok, "Endless must not grant victory bonus")
	check(loaded.settle(next, &"endless", &"defeat", 150, 25).awarded == 200, "Endless defeat must use shared capped formula")
	var capped: Dictionary = loaded.data.duplicate(true)
	capped.xp = Profile.xp_cap() - 1
	check(loaded._commit(capped) == OK, "Cap fixture must save")
	var final_id: int = loaded.begin_run(&"courtyard")
	check(loaded.settle(final_id, &"courtyard", &"victory", 115, 10).awarded == 1 and loaded.data.xp == Profile.xp_cap(), "Award must report only remaining XP to cap")
	# Corrupt primary must recover a valid backup; a bad primary must not overwrite it.
	var backup: String = FileAccess.get_file_as_string(PATH + ".bak")
	write_json(PATH, {"version": 1, "xp": "bad"})
	loaded.load_profile()
	check(loaded.load_status == &"recovered" and loaded.data.xp == Profile.xp_cap() - 1, "Malformed/incomplete primary must recover backup")
	check(loaded._commit(loaded.data) == OK and FileAccess.get_file_as_string(PATH + ".bak") == backup, "Recovery must preserve valid backup when primary is corrupt")
	var invalid: Dictionary = Profile.defaults()
	invalid.active_run = {"id": 5, "mode": "endless"}
	check(Profile._clean(invalid).is_empty(), "Active run must precede next sequence")
	invalid = Profile.defaults()
	invalid.skills = ["invented"]
	check(Profile._clean(invalid).is_empty(), "Unknown reserved skill IDs must reject profile")
	invalid = Profile.defaults()
	invalid.xp = 1.5
	check(Profile._clean(invalid).is_empty(), "Fractional XP must reject profile")
	write_json(PATH, {"version": 99, "xp": 0})
	var future: String = FileAccess.get_file_as_string(PATH)
	loaded.load_profile()
	check(loaded.unsupported_version and loaded.begin_run(&"endless") == 0 and FileAccess.get_file_as_string(PATH) == future, "Future primary must block writes even when backup loads")
	cleanup()
	write_json(PATH, {"version": 1})
	loaded.load_profile()
	check(loaded.load_status == &"reset" and loaded.data == Profile.defaults(), "Invalid primary without backup must expose initial recovery state")
	cleanup()
	# A partial temporary file must never be promoted on startup.
	write_json(PATH + ".tmp", {"version": 1, "xp": 999})
	loaded.load_profile()
	check(loaded.data.xp == 0 and loaded.load_status == &"new", "Incomplete temporary data must not become a profile")
	var legacy := {"version": 1, "xp": 300, "next_run_id": 8, "last_settled_run_id": 6, "active_run": {"id": 7, "mode": "courtyard"}, "skills": ["michael_edge"], "unlocks": []}
	write_json(PATH, legacy)
	loaded.load_profile()
	check(loaded.data.version == Profile.VERSION and loaded.data.xp == 300 and loaded.data.skills == ["michael_edge"] and loaded.data.active_run.id == 7 and loaded.data.last_settled_run_id == 6, "Migration must preserve XP, skills and reward identities")
	var staged: Dictionary = loaded.data.duplicate(true)
	staged.xp = 600
	write_json(PATH + ".tmp", staged)
	write_json(PATH + ".bak", {"version": Profile.VERSION})
	loaded.load_profile()
	check(loaded.data.xp == 300 and loaded.data.active_run.id == 7, "Interrupted write must preserve the committed profile even with a complete temp and torn backup")
	write_json(PATH + ".bak", legacy)
	write_json(PATH, {"version": Profile.VERSION, "xp": "partial"})
	loaded.load_profile()
	check(loaded.load_status == &"recovered" and loaded.data.version == Profile.VERSION and loaded.data.skills == ["michael_edge"], "A torn primary must recover and migrate a valid legacy backup")
	check(loaded.reset_progression() == OK, "Profile reset must save")
	check(JSON.parse_string(FileAccess.get_file_as_string(PATH)).version == Profile.VERSION, "First successful write must persist the upgraded schema")
	loaded.load_profile()
	check(loaded.data.xp == 0 and loaded.data.skills.is_empty() and loaded.data.active_run.id == 0, "Reset must persist and invalidate abandoned run rewards")
	check(loaded.begin_run(&"courtyard") == 8 and not loaded.settle(7, &"courtyard", &"defeat", 10, 1).ok, "Reset must preserve monotonic run identities")
	var exhausted: Dictionary = Profile.defaults()
	exhausted.next_run_id = Profile.SEQUENCE_LIMIT
	check(loaded._commit(exhausted) == OK and loaded.begin_run(&"endless") == 0, "Sequence exhaustion must not wrap or reuse IDs")
	cleanup()
	print("Profile checks complete: %d failures" % failures)
	quit(1 if failures else 0)
