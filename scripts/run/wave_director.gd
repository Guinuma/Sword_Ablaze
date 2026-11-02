extends RefCounted
## Advances only when combat explicitly supplies simulation time.
signal spawn_requested
signal wave_cleared
signal wave_started(number: int)

const WaveSettings = preload("res://scripts/data/wave_settings.gd")
var settings: WaveSettings = load("res://resources/default_wave.tres")
var number: int = 1
var remaining: int = settings.initial_budget
var break_time: float = 0.0
var spawn_cooldown: float = settings.initial_delay


func reset() -> void:
	number = 1
	remaining = settings.initial_budget
	break_time = 0.0
	spawn_cooldown = settings.initial_delay


func advance(delta: float, living_enemies: int) -> void:
	if break_time > 0.0:
		break_time = maxf(0.0, break_time - delta)
		if break_time == 0.0:
			number += 1
			remaining = mini(settings.initial_budget + (number - 1) * settings.budget_growth, settings.max_budget)
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
		spawn_cooldown = maxf(settings.min_spawn_interval, settings.spawn_interval - (number - 1) * settings.interval_reduction)
		spawn_requested.emit()
