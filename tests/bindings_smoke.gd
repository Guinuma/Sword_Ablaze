extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var preferences = load("res://scripts/settings/preferences.gd").new("user://bindings_smoke.json")
	preferences.reset_bindings()
	check(not preferences.set_binding(&"dash", KEY_W), "Conflicting movement key must be rejected")
	check(not preferences.set_binding(&"dash", KEY_ESCAPE), "Escape must remain available for cancellation")
	check(not preferences.set_binding(&"ui_accept", KEY_Q), "Menu bindings must remain unchanged")
	check(preferences.set_binding(&"dash", KEY_Q), "New key must apply")
	check(preferences.set_binding(&"fire", KEY_F), "Fire key must apply")
	check(InputMap.action_get_events(&"fire").size() == 2, "Mouse fire must survive keyboard remapping")
	check(preferences.save() == OK, "Bindings must save")
	var loaded = load("res://scripts/settings/preferences.gd").new(preferences.path)
	loaded.load_preferences()
	check(loaded.bindings.get(&"dash") == KEY_Q, "Saved bindings must reload")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	check(InputMap.event_is_action(event, &"dash"), "Loaded key must drive InputMap")
	loaded.reset_bindings()
	check(not InputMap.event_is_action(event, &"dash"), "Reset must remove remapped key")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(preferences.path + suffix)
	print("Bindings checks complete: %d failures" % failures)
	quit(1 if failures else 0)
