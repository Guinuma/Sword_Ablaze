extends Node
## Persistent two-voice soundtrack: scene changes retain playback and crossfade.
const TRACKS = {
	&"sanctuary": preload("res://assets/audio/sanctuary.wav"),
	&"combat": preload("res://assets/audio/courtyard.wav"),
}
const FADE_SECONDS := 1.25
const GAIN := 0.38
var voices: Array[AudioStreamPlayer] = []
var levels := [0.0, 0.0]
var targets := [0.0, 0.0]
var current: StringName = &""
var ducked := false
var scene_ref: WeakRef
var quitting := false
var duck_gain := 1.0

static func for_tree(tree: SceneTree) -> Node:
	var existing := tree.root.get_node_or_null("Soundtrack")
	if existing != null:
		return existing
	var music = load("res://scripts/audio/music.gd").new()
	music.name = "Soundtrack"
	if tree.root.is_node_ready():
		tree.root.add_child(music)
	else:
		tree.root.add_child.call_deferred(music)
	return music

func _ready() -> void:
	get_tree().auto_accept_quit = false
	for index in range(2):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Music"
		voice.volume_db = -80.0
		add_child(voice)
		voices.append(voice)

func bind_scene(scene: Node, track: StringName) -> void:
	if not is_node_ready():
		bind_scene.call_deferred(scene, track)
		return
	scene_ref = weakref(scene)
	scene.tree_exiting.connect(func(): call_deferred("_release_if_unused"))
	select(track)

func _release_if_unused() -> void:
	var scene = scene_ref.get_ref() if scene_ref != null else null
	if scene != null and scene.is_inside_tree():
		return
	for voice in voices:
		voice.stop()
		voice.stream = null
	levels = [0.0, 0.0]
	targets = [0.0, 0.0]
	current = &""

func select(track: StringName) -> void:
	if track == current or not TRACKS.has(track):
		return
	current = track
	var index := 0 if track == &"sanctuary" else 1
	for other in range(2):
		targets[other] = GAIN if other == index else 0.0
	if not voices[index].playing:
		voices[index].stream = TRACKS[track]
		voices[index].play()

func _process(delta: float) -> void:
	duck_gain = move_toward(duck_gain, 0.35 if ducked else 1.0, delta * 3.0)
	for index in range(2):
		levels[index] = move_toward(levels[index], targets[index], GAIN * delta / FADE_SECONDS)
		var gain: float = levels[index] * duck_gain
		voices[index].volume_db = linear_to_db(maxf(gain, 0.0001))
		if levels[index] == 0.0 and targets[index] == 0.0:
			voices[index].stop()

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	if quitting:
		return
	quitting = true
	set_process(false)
	for voice in voices:
		voice.stop()
		voice.stream = null
	# Godot retires audio-server playback on a subsequent mixer update.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
