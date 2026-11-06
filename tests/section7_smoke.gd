extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	set_meta("profile_path", "user://section7_profile.json")
	call_deferred("_run")
func _run() -> void:
	var preferences = load("res://scripts/settings/preferences.gd").new("user://section7_preferences.json")
	preferences.hit_stop = false
	preferences.screen_shake = false
	check(preferences.save() == OK, "Feedback options must save")
	var reloaded = load("res://scripts/settings/preferences.gd").new(preferences.path)
	reloaded.load_preferences()
	check(not reloaded.hit_stop and not reloaded.screen_shake, "Feedback options must survive reload")
	var accent = load("res://scripts/ui/impact_feedback.gd").new()
	for rate in [30, 60, 120, 144, 240]:
		accent.clear()
		accent.trigger(true, true)
		var lost := 0.0
		for step in range(rate):
			var delta: float = 1.0 / rate
			lost += delta - accent.advance(delta, true, true)
			check(accent.offset.length() <= 2.13, "Shake must stay bounded")
		check(is_equal_approx(lost, 0.035), "Hit-stop must have the same total duration at all rates")
		check(accent.offset == Vector2.ZERO, "Shake must settle exactly")
	accent.trigger(true, true)
	check(accent.advance(0.01, false, false) == 0.01 and accent.offset == Vector2.ZERO, "Disable options must cancel active accents")
	var arena = load("res://scenes/main/main.tscn").instantiate()
	arena.preferences = preferences
	arena.records = arena.ArenaRecords.new("user://section7_records.json")
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.preferences.hit_stop = true
	arena.preferences.screen_shake = true
	arena.preferences.reduced_motion = false
	arena._take_player_damage(1)
	check(arena.impact_feedback.stop_left > 0, "Accepted damage must trigger hit-stop")
	var elapsed: float = arena.run.elapsed
	arena._physics_process(0.01)
	check(arena.run.elapsed == elapsed, "Hit-stop must freeze simulation")
	check(arena.world.position != Vector2.ZERO, "Shake must move the world")
	arena._set_paused(true)
	check(arena.impact_feedback.stop_left == 0 and arena.world.position == Vector2.ZERO, "Pause must clear accents")
	arena._set_paused(false)
	arena.preferences.reduced_motion = true
	arena._on_critical_hit(Vector2.ZERO)
	check(arena.impact_feedback.stop_left == 0 and arena.impact_feedback.shake_left == 0, "Reduce motion must suppress both accents")
	arena.preferences.reduced_motion = false
	arena._on_critical_hit(Vector2.ZERO)
	arena._reset_run()
	check(arena.impact_feedback.stop_left == 0 and arena.world.position == Vector2.ZERO, "Restart must clear accents")
	var music = arena.music
	music.set_process(false)
	check(music.current == &"combat", "Arena must select combat music")
	for track in music.TRACKS.values():
		check(track.loop_mode == AudioStreamWAV.LOOP_FORWARD and track.get_length() > 15, "Tracks must be full looping arrangements")
	music._process(2.0)
	check(music.voices[1].playing and music.voices[1].bus == &"Music", "Combat music must use Music bus")
	arena._set_paused(true)
	check(music.ducked, "Pause must duck music")
	arena._set_paused(false)
	check(not music.ducked, "Resume must restore music")
	var menu = load("res://scenes/main/hub.tscn").instantiate()
	menu.preferences = reloaded
	root.add_child(menu)
	check(menu.Music.for_tree(self) == music and music.current == &"sanctuary", "Hub must reuse soundtrack and select ambience")
	arena.free()
	await process_frame
	check(music.voices[1].playing, "Scene handoff must retain outgoing track for crossfade")
	music._process(0.5)
	check(music.voices[0].playing and music.levels[0] > 0 and music.levels[1] > 0, "Transition must crossfade both tracks")
	music._process(2.0)
	check(not music.voices[1].playing and music.voices[0].playing, "Fade completion must release outgoing playback")
	menu._show_feedback_options()
	menu.detail_body.get_child(1).button_pressed = true
	check(menu.preferences.hit_stop, "Feedback toggle must update preference")
	menu.free()
	await create_timer(0.35).timeout
	for path in [preferences.path, String(get_meta("profile_path")), "user://section7_records.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path + suffix)
	print("Section 7 checks complete: %d failures" % failures)
	quit(1 if failures else 0)
