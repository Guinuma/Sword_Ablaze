extends SceneTree
var failures := 0
func _initialize() -> void:
	set_meta("profile_path", "user://event_integration_profile.json")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(String(get_meta("profile_path")) + suffix)
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	set_meta("finite_run", false)
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.records = arena.ArenaRecords.new("user://event_integration_records.json")
	arena.preferences = arena.Preferences.new("user://event_integration_preferences.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	var events: Array[StringName] = []
	arena.run.damaged.connect(func(_health): events.append(&"damaged"))
	arena.run.enemy_defeated.connect(func(_kills): events.append(&"defeated"))
	arena.waves.wave_cleared.connect(func(): events.append(&"wave_cleared"))
	arena.player.shot.emit(arena.player.muzzle_position(), Vector2.RIGHT)
	check(arena.projectiles.items.size() == 1 and arena.sounds.last_played.has(&"shot"), "Player shot event must reach projectile and audio systems")
	arena._take_player_damage()
	check(events.count(&"damaged") == 1 and arena.sounds.last_played.has(&"damage"), "Accepted damage must reach shared event and audio")
	arena.enemies.items.append({"position": arena.player.muzzle_position(), "health": 1, "flash": 0.0})
	arena.projectiles.advance(0.0, arena.enemies.items, arena.ARENA)
	check(events.count(&"defeated") == 1 and arena.run.kills == 1, "Projectile defeat must reach the central kill event")
	check(arena.sounds.last_played.has(&"impact") and arena.sounds.last_played.has(&"defeat"), "Impact/defeat events must reach distinct audio cues")
	arena.waves.remaining = 0
	arena.waves.advance(0.0, 0)
	check(events.count(&"wave_cleared") == 1 and arena.run.cleared_waves == 1 and arena.sounds.last_played.has(&"wave"), "Director clear must reach wave counter and audio")
	arena.run.start_combat(2)
	arena.run.health = 1
	arena.player.hurt_cooldown = 0.0
	arena._take_player_damage()
	check(arena.reward_received and arena.reward_awarded == 11, "Terminal event must settle one kill and one clear through global rewards")
	arena._on_run_phase_changed(arena.RunState.Phase.DEAD)
	check(arena.profile.data.xp == 11 and arena.records.data.runs == 1, "Repeated terminal event must not duplicate reward or record")
	arena.free()
	await create_timer(0.35).timeout
	for path in [String(get_meta("profile_path")), "user://event_integration_records.json", "user://event_integration_preferences.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Event integration checks complete: %d failures" % failures)
	quit(1 if failures else 0)
