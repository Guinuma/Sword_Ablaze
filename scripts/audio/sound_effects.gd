extends Node
## Original synthesized prototype effects. No external audio assets.
const MAX_VOICES := 8
const UI_VOICES := 2
const RATE := 22050
const TONES := {
	&"melee": [180.0, 650.0, 0.12],
	&"critical": [1100.0, 450.0, 0.09],
	&"shot": [780.0, 160.0, 0.075],
	&"impact": [340.0, 100.0, 0.055],
	&"defeat": [260.0, 65.0, 0.16],
	&"damage": [150.0, 55.0, 0.22],
	&"dash": [220.0, 920.0, 0.14],
	&"ui": [660.0, 880.0, 0.07],
	&"upgrade": [440.0, 1320.0, 0.28],
	&"wave": [520.0, 1040.0, 0.25],
}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}

func _ready() -> void:
	for cue in TONES:
		streams[cue] = _synthesize(TONES[cue])
	for index in range(MAX_VOICES):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"UI" if index < UI_VOICES else &"SFX"
		# Conservative fixed gain plus a hard voice cap bounds dense combat output.
		voice.volume_db = -18.0
		add_child(voice)
		voices.append(voice)

func play(cue: StringName) -> bool:
	if not streams.has(cue):
		return false
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(cue, -1000)) < 45:
		return false
	var is_ui := cue == &"ui"
	for index in range(voices.size()):
		if (index < UI_VOICES) != is_ui or voices[index].playing:
			continue
		voices[index].stream = streams[cue]
		voices[index].play()
		last_played[cue] = now
		return true
	return false

func stop_combat() -> void:
	for index in range(UI_VOICES, voices.size()):
		voices[index].stop()

func watch_buttons(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func(): play(&"ui"))
	for child in node.get_children():
		watch_buttons(child)

func _synthesize(tone: Array) -> AudioStreamWAV:
	var count := int(float(tone[2]) * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for index in range(count):
		var progress := float(index) / count
		phase += TAU * lerpf(tone[0], tone[1], progress) / RATE
		var envelope := minf(1.0, float(index) / (RATE * 0.004)) * pow(1.0 - progress, 2.0)
		var sample := int(sin(phase) * envelope * 26000.0)
		data.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream


func _exit_tree() -> void:
	# Release playback references before scene destruction or application shutdown.
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()
	voices.clear()
