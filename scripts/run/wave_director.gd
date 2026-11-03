extends RefCounted
## Advances only when combat explicitly supplies simulation time.
signal spawn_requested(kind: StringName)
signal wave_cleared
signal wave_started(number: int)

const WaveSettings = preload("res://scripts/data/wave_settings.gd")
var settings: WaveSettings = load("res://resources/default_wave.tres")
var spawn_count: int = 0
var number: int = 1
var remaining: int = budget_for_wave(1)
var break_time: float = 0.0
var spawn_cooldown: float = settings.initial_delay


func reset() -> void:
	spawn_count = 0
	number = 1
	remaining = budget_for_wave(1)
	break_time = 0.0
	spawn_cooldown = settings.initial_delay


func advance(delta: float, living_enemies: int) -> void:
	if break_time > 0.0:
		break_time = maxf(0.0, break_time - delta)
		if break_time == 0.0:
			number += 1
			spawn_count = 0
			remaining = budget_for_wave(number)
			spawn_cooldown = settings.next_wave_delay
			wave_started.emit(number)
		return
	if remaining == 0 and living_enemies == 0:
		break_time = settings.break_duration
		wave_cleared.emit()
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0 and remaining > 0 and living_enemies < settings.max_enemies:
		remaining -= 1
		var recipe = encounter_for_wave(number)
		var multiplier: float = recipe.interval_multiplier if recipe != null else 1.0
		spawn_cooldown = maxf(settings.min_spawn_interval, (settings.spawn_interval - (number - 1) * settings.interval_reduction) * multiplier)
		spawn_count += 1
		var kind: StringName = &"ranged" if number >= settings.ranged_start_wave and spawn_count % settings.ranged_every == 0 else &"chaser"
		if number >= settings.charger_start_wave and spawn_count % settings.charger_every == 0:
			kind = &"charger"
		if number >= settings.guardian_start_wave and spawn_count % settings.guardian_every == 0:
			kind = &"guardian"
		if recipe != null and not recipe.pattern.is_empty():
			kind = recipe.pattern[(spawn_count - 1) % recipe.pattern.size()]
			if spawn_count == 1 and recipe.opener != &"":
				kind = recipe.opener
			if kind not in [&"chaser", &"ranged", &"charger", &"guardian", &"elite"]:
				kind = &"chaser"
		spawn_requested.emit(kind)


func encounter_for_wave(wave: int) -> Resource:
	if settings.encounters.is_empty():
		return null
	var index := maxi(0, wave - 1)
	if index >= settings.encounters.size():
		var first := clampi(settings.repeat_from_wave - 1, 0, settings.encounters.size() - 1)
		index = first + (index - first) % (settings.encounters.size() - first)
	return settings.encounters[index]

func budget_for_wave(wave: int) -> int:
	var recipe = encounter_for_wave(wave)
	var multiplier: float = recipe.budget_multiplier if recipe != null else 1.0
	return clampi(int(round((settings.initial_budget + (wave - 1) * settings.budget_growth) * multiplier)), 1, settings.max_budget)
