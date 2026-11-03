extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var effects = load("res://scripts/audio/sound_effects.gd").new()
	root.add_child(effects)
	check(effects.voices.size() == 8, "Voice pool must be bounded")
	for cue in effects.TONES:
		var stream: AudioStreamWAV = effects.streams[cue]
		check(stream.data.size() > 0 and stream.mix_rate == 22050, "Each cue must contain PCM audio")
	check(not effects.play(&"unknown"), "Unknown cues must be ignored")
	check(effects.play(&"shot"), "First shot must play")
	check(not effects.play(&"shot"), "Repeated same-frame shots must be throttled")
	for cue in [&"impact", &"defeat", &"damage", &"dash", &"upgrade"]:
		check(effects.play(cue), "Combat voice must be available")
	check(not effects.play(&"wave"), "Full combat pool must drop extra cues")
	check(effects.play(&"ui"), "UI must retain reserved capacity during combat")
	check(effects.voices[0].bus == &"UI" and effects.voices[2].bus == &"SFX", "Voices must respect category volumes")
	effects.stop_combat()
	for index in range(2, 8):
		check(not effects.voices[index].playing, "Pause must stop combat tails")
	check(effects.voices[0].playing, "Combat stop must preserve UI")
	effects.free()
	await create_timer(0.35).timeout
	print("Audio checks complete: %d failures" % failures)
	quit(1 if failures else 0)
