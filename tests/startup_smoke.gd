extends SceneTree
## Boot the actual entry scene and shut down through its soundtrack lifecycle.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await scene_changed
	for frame in range(120):
		await process_frame
	var music := root.get_node_or_null("Soundtrack")
	if current_scene == null or music == null or not music.voices[0].playing:
		push_error("Startup must load the title and begin ambience")
		quit(1)
		return
	print("Startup checks complete: 0 failures")
	var controls: Array[Control] = []
	var from_play := OS.get_cmdline_user_args().has("--play-quit")
	if from_play:
		current_scene._show_play()
	current_scene.FocusNavigation.collect(current_scene.detail if from_play else current_scene.home, controls)
	for button in controls:
		if button is Button and button.text == "QUIT":
			button.pressed.emit()
			return
	push_error("The active menu must expose Quit")
	music.quit_game()
