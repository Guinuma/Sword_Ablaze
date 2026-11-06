extends RefCounted
## Bounded real-time accents; never changes Engine.time_scale or collision state.
const STOP := 0.035
const SHAKE := 0.14
var stop_left := 0.0
var shake_left := 0.0
var cooldown := 0.0
var offset := Vector2.ZERO

func trigger(hit_stop: bool, shake: bool) -> void:
	if cooldown > 0.0:
		return
	stop_left = STOP if hit_stop else 0.0
	shake_left = SHAKE if shake else 0.0
	cooldown = 0.18

func advance(delta: float, hit_stop: bool, shake: bool) -> float:
	cooldown = maxf(0.0, cooldown - delta)
	var skipped := minf(stop_left, delta) if hit_stop else 0.0
	stop_left = maxf(0.0, stop_left - delta) if hit_stop else 0.0
	shake_left = maxf(0.0, shake_left - delta) if shake else 0.0
	var strength := shake_left / SHAKE
	offset = Vector2(sin(shake_left * 170.0), cos(shake_left * 133.0)) * 1.5 * strength
	return delta - skipped

func clear() -> void:
	stop_left = 0.0
	shake_left = 0.0
	cooldown = 0.0
	offset = Vector2.ZERO
