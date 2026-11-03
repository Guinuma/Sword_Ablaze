extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	var director = load("res://scripts/run/wave_director.gd").new()
	check(director.settings.encounters.size() == 9, "Nine opening encounters must be authored")
	check(director.budget_for_wave(4) == 9, "Breather wave must reduce budget")
	check(director.budget_for_wave(6) == 14, "Firing line must use its own budget")
	check(director.encounter_for_wave(10) == director.encounter_for_wave(7), "Later waves must repeat from configured cycle start")
	check(director.encounter_for_wave(11) == director.encounter_for_wave(8), "Cycle must retain varied compositions")
	check(director.budget_for_wave(10000) == 40, "Advanced recipes must retain global budget cap")
	var kinds: Array[StringName] = []
	director.spawn_requested.connect(func(kind): kinds.append(kind))
	for wave in range(1, 13):
		director.number = wave
		director.spawn_count = 0
		director.remaining = director.budget_for_wave(wave)
		var recipe = director.encounter_for_wave(wave)
		var budget: int = director.remaining
		kinds.clear()
		for index in range(budget):
			director.spawn_cooldown = 0.0
			director.advance(0.01, 0)
			var expected: StringName = recipe.opener if index == 0 and recipe.opener != &"" else recipe.pattern[index % recipe.pattern.size()]
			check(kinds[index] == expected, "Every spawn must follow its recipe or opener")
		check(director.remaining == 0 and kinds.size() == budget, "Recipe must consume exact wave budget")
	# Custom resources without recipes retain the generic fallback.
	director.settings = director.settings.duplicate()
	var empty_recipes: Array[Resource] = []
	director.settings.encounters = empty_recipes
	director.reset()
	check(director.remaining == 5 and director.encounter_for_wave(1) == null, "Empty configuration must retain fallback")
	print("Encounter checks complete: %d failures" % failures)
	quit(1 if failures else 0)
