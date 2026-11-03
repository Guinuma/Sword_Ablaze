extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://feedback_smoke_global_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var arena = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.preferences.reduced_motion = true
	arena.preferences.reduced_flashes = true
	arena.run.health = 80
	arena.run.heal(10)
	check(arena.feedback.items.size() == 1 and arena.feedback.items[0].kind == &"heal", "Actual healing must emit feedback even with reductions enabled")
	arena.run.health = 100
	arena.run.heal(10)
	check(arena.feedback.items.size() == 1, "Full health must not emit healing feedback")
	arena.feedback.clear()
	arena._try_dash(Vector2.RIGHT)
	check(arena.feedback.items.size() == 1 and arena.feedback.items[0].kind == &"dash", "Successful dash must emit cue")
	arena._try_dash(Vector2.RIGHT)
	check(arena.feedback.items.size() == 1, "Failed dash must not emit cue")
	arena._set_paused(true)
	var life: float = arena.feedback.items[0].life
	arena._physics_process(0.2)
	check(arena.feedback.items[0].life == life, "Pause must freeze feedback")
	arena._set_paused(false)
	arena.feedback.advance(1.0)
	check(arena.feedback.items.is_empty(), "Feedback must expire")
	arena._spawn_enemy()
	var enemy: Dictionary = arena.enemies.items[0]
	enemy.position = Vector2(80, 100)
	enemy.spawn_time = 0.01
	arena.enemies.advance(0.02, arena.player.player_position, 1, arena.ARENA)
	check(arena.feedback.items.size() == 1 and arena.feedback.items[0].kind == &"spawn", "Activation must emit spawn cue")
	for index in range(100):
		arena.feedback.add(&"wave", Vector2.ZERO)
	check(arena.feedback.items.size() == 32, "Feedback must remain bounded")
	arena._reset_run()
	check(arena.feedback.items.is_empty(), "Restart must clear feedback")
	arena.free()
	await create_timer(0.35).timeout
	print("Feedback checks complete: %d failures" % failures)
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	quit(1 if failures else 0)
