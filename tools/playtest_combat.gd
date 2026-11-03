extends SceneTree
## Launches ordinary combat with isolated files for direct keyboard/mouse review.
func _initialize() -> void:
	set_meta("profile_path", "user://combat_review_profile.json")
	call_deferred("_run")
func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = arena.Preferences.new("user://combat_review_preferences.json")
	arena.records = arena.ArenaRecords.new("user://combat_review_records.json")
	root.add_child(arena)
	current_scene = arena
