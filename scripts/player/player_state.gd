extends RefCounted
## Input-independent player movement, dash and weapon timing.
signal shot(origin: Vector2, direction: Vector2)

const SPEED: float = 120.0
var move_speed: float = SPEED
const WeaponSettings = preload("res://scripts/data/weapon_settings.gd")
var weapon: WeaponSettings = load("res://resources/default_weapon.tres")
var player_position := Vector2(320, 200)
var aim := Vector2.RIGHT
var fire_cooldown: float = 0.0
const CONTACT_COOLDOWN: float = 0.85
const DASH_SPEED: float = 380.0
const DASH_DURATION: float = 0.14
const DASH_COOLDOWN: float = 1.2
var dash_recharge: float = DASH_COOLDOWN
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction := Vector2.RIGHT
var hurt_cooldown: float = 0.0
var fire_requires_release: bool = false
var muzzle_time: float = 0.0


func advance(delta: float, movement: Vector2, mouse_position: Vector2, dash_pressed: bool, fire_pressed: bool, bounds: Rect2) -> void:
	if not fire_pressed:
		fire_requires_release = false
	muzzle_time = maxf(0.0, muzzle_time - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if dash_pressed:
		try_dash(movement)
	if dash_time > 0.0:
		player_position += dash_direction * DASH_SPEED * minf(delta, dash_time)
		dash_time = maxf(0.0, dash_time - delta)
	else:
		player_position += movement * move_speed * delta
	player_position = player_position.clamp(bounds.position + Vector2(8, 8), bounds.end - Vector2(8, 8))
	var mouse_direction := mouse_position - player_position
	if mouse_direction.length_squared() > 1.0:
		aim = mouse_direction.normalized()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if fire_pressed and not fire_requires_release and fire_cooldown <= 0.0:
		shot.emit(muzzle_position(), aim)
		fire_cooldown = weapon.fire_interval
		muzzle_time = 0.06


func muzzle_position() -> Vector2:
	var grip := Vector2(7 if aim.y < -0.6 else 0, -2)
	return player_position + grip + aim * weapon.muzzle_offset


func try_dash(movement: Vector2) -> void:
	if dash_cooldown > 0.0:
		return
	dash_direction = movement.normalized() if movement.length_squared() > 0.0 else aim
	dash_time = DASH_DURATION
	dash_cooldown = dash_recharge


func reset() -> void:
	move_speed = SPEED
	dash_recharge = DASH_COOLDOWN
	player_position = Vector2(320, 200)
	aim = Vector2.RIGHT
	fire_cooldown = 0.0
	dash_time = 0.0
	dash_cooldown = 0.0
	dash_direction = Vector2.RIGHT
	hurt_cooldown = 0.0
	fire_requires_release = true
	muzzle_time = 0.0
