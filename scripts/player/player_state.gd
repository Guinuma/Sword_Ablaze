extends RefCounted
## Input-independent player movement, dash and weapon timing.
signal shot(origin: Vector2, direction: Vector2)
signal dashed()
signal melee(origin: Vector2, direction: Vector2)

const SPEED: float = 120.0
var geometry: RefCounted
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
# Keep protection through collision checks on the final dash step.
var dashed_this_step: bool = false
var dash_cooldown: float = 0.0
var dash_direction := Vector2.RIGHT
var hurt_cooldown: float = 0.0
var fire_requires_release: bool = false
var muzzle_time: float = 0.0
var melee_settings = load("res://resources/default_melee.tres")
var melee_cooldown: float = 0.0
var melee_time: float = 0.0
var melee_requires_release: bool = false


func advance(delta: float, movement: Vector2, mouse_position: Vector2, dash_pressed: bool, fire_pressed: bool, bounds: Rect2, melee_pressed: bool = false) -> void:
	var start := player_position
	dashed_this_step = false
	melee_time = maxf(0.0, melee_time - delta)
	melee_cooldown = maxf(0.0, melee_cooldown - delta)
	if not melee_pressed:
		melee_requires_release = false
	if not fire_pressed:
		fire_requires_release = false
	muzzle_time = maxf(0.0, muzzle_time - delta)
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if dash_pressed:
		try_dash(movement)
	if dash_time > 0.0:
		dashed_this_step = true
		player_position += dash_direction * DASH_SPEED * minf(delta, dash_time)
		dash_time = maxf(0.0, dash_time - delta)
	else:
		player_position += movement * move_speed * delta
	if geometry != null:
		player_position = geometry.move_actor(start, player_position, 8.0)
	player_position = player_position.clamp(bounds.position + Vector2(8, 8), bounds.end - Vector2(8, 8))
	var mouse_direction := mouse_position - player_position
	if mouse_direction.length_squared() > 1.0:
		aim = mouse_direction.normalized()
	if melee_pressed and not melee_requires_release and melee_cooldown <= 0.0:
		melee_cooldown = melee_settings.cooldown
		melee_time = melee_settings.duration
		melee.emit(player_position, aim)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if fire_pressed and not fire_requires_release and fire_cooldown <= 0.0 and melee_time <= 0.0:
		for index in range(weapon.pellets):
			var angle := 0.0 if weapon.pellets == 1 else (float(index) / (weapon.pellets - 1) - 0.5) * weapon.spread
			shot.emit(muzzle_position(), aim.rotated(angle))
		fire_cooldown = weapon.fire_interval
		muzzle_time = 0.06


func muzzle_position() -> Vector2:
	var grip := weapon_grip(aim)
	return player_position + grip + aim * weapon.muzzle_offset


func try_dash(movement: Vector2) -> void:
	if dash_cooldown > 0.0:
		return
	dash_direction = movement.normalized() if movement.length_squared() > 0.0 else aim
	dash_time = DASH_DURATION
	dash_cooldown = dash_recharge
	dashed.emit()


func is_dash_protected() -> bool:
	return dash_time > 0.0 or dashed_this_step


func reset() -> void:
	move_speed = SPEED
	dash_recharge = DASH_COOLDOWN
	player_position = Vector2(320, 200)
	aim = Vector2.RIGHT
	fire_cooldown = 0.0
	dash_time = 0.0
	dashed_this_step = false
	dash_cooldown = 0.0
	dash_direction = Vector2.RIGHT
	hurt_cooldown = 0.0
	fire_requires_release = true
	muzzle_time = 0.0
	melee_cooldown = 0.0
	melee_time = 0.0
	melee_requires_release = true


static func weapon_grip(direction: Vector2) -> Vector2:
	return Vector2(7.0 * smoothstep(0.45, 0.8, absf(direction.y)), -6)
