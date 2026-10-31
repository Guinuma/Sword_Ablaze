extends RefCounted
## Advances only when combat explicitly supplies simulation time.
signal spawn_requested
signal wave_cleared
signal wave_started(number: int)

const MAX_ENEMIES: int = 18
const SPAWN_INTERVAL: float = 1.6
const WAVE_BREAK: float = 3.0
var number: int = 1
var remaining: int = 5
var break_time: float = 0.0
var spawn_cooldown: float = 0.8


func reset() -> void:
	number = 1
	remaining = 5
	break_time = 0.0
	spawn_cooldown = 0.8


func advance(delta: float, living_enemies: int) -> void:
	if break_time > 0.0:
		break_time = maxf(0.0, break_time - delta)
		if break_time == 0.0:
			number += 1
			remaining = mini(5 + (number - 1) * 2, 40)
			spawn_cooldown = 0.3
			wave_started.emit(number)
		return
	if remaining == 0 and living_enemies == 0:
		break_time = WAVE_BREAK
		wave_cleared.emit()
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0 and remaining > 0 and living_enemies < MAX_ENEMIES:
		remaining -= 1
		spawn_cooldown = maxf(0.4, SPAWN_INTERVAL - (number - 1) * 0.1)
		spawn_requested.emit()
