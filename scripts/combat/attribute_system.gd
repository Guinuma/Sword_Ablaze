extends RefCounted
## Attribute meters live on enemies, so clearing an encounter clears its effects.
signal defeated(enemy: Dictionary)
const BURN_TICKS := 3
const BURN_INTERVAL := 0.65
const PYRE_RADIUS := 40.0
const COUNTER_WINDOW := 0.65
const MARK_DURATION := 3.0
const SHIELD_DURATION := 4.0
const SHIELD_STRENGTH := 12

var fire := false
var pyre := false
var impact := false
var countercharge := false
var furnace := false
var counter_time := 0.0
var light := false
var verdict := false
var vitality := false
var shelter := false
var light_target: Dictionary = {}
var light_hits := 0
var shield := 0
var shield_time := 0.0


func configure(skills: Array, melee_id: StringName) -> void:
	fire = "michael_ember" in skills and melee_id == &"sword_ablaze"
	pyre = "michael_pyre" in skills
	impact = "joan_break" in skills
	countercharge = "joan_counter" in skills
	furnace = "holy_furnace" in skills
	light = "gabriel_seal" in skills
	verdict = "gabriel_verdict" in skills
	vitality = "raphael_grace" in skills
	shelter = "raphael_shelter" in skills


func reset() -> void:
	counter_time = 0.0
	light_target = {}
	light_hits = 0
	shield = 0
	shield_time = 0.0


func grant_shield() -> bool:
	if not vitality or shield > 0:
		return false
	shield = SHIELD_STRENGTH
	shield_time = SHIELD_DURATION
	return true


func absorb(amount: int) -> int:
	var absorbed := mini(shield, maxi(amount, 0))
	shield -= absorbed
	return amount - absorbed


func ranged_hit(enemy: Dictionary) -> void:
	_apply_shelter(enemy)
	if not light:
		return
	if not is_same(light_target, enemy):
		light_target = enemy
		light_hits = 0
	if enemy.health <= 0:
		light_target = {}
		light_hits = 0
		return
	light_hits += 1
	if light_hits >= 3:
		enemy["light_time"] = MARK_DURATION
		light_hits = 0


func _apply_shelter(enemy: Dictionary) -> void:
	if shelter and shield > 0:
		enemy["knockback"] *= 1.3


func dashed() -> void:
	if countercharge:
		counter_time = COUNTER_WINDOW


func melee_hit(enemy: Dictionary, boss: bool, heavy: bool) -> void:
	_apply_shelter(enemy)
	if enemy.health <= 0:
		return
	if verdict and enemy.get("light_time", 0.0) > 0.0:
		enemy["light_time"] = 0.0
		enemy.health -= 3
		if enemy.health <= 0:
			return
	if fire and enemy.get("burn_ticks", 0) == 0:
		enemy["fire_meter"] = int(enemy.get("fire_meter", 0)) + 1
		if enemy.fire_meter >= 2:
			_ignite(enemy, BURN_TICKS)
	if not impact or not heavy or enemy.get("stagger_time", 0.0) > 0.0:
		return
	enemy["impact_meter"] = int(enemy.get("impact_meter", 0)) + (2 if counter_time > 0.0 else 1)
	counter_time = 0.0
	if enemy.impact_meter >= (5 if boss else 3):
		enemy["impact_meter"] = 0
		enemy["stagger_time"] = 0.18 if boss else 0.55
		if furnace and enemy.get("burn_ticks", 0) > 0:
			enemy.health -= enemy.burn_ticks
			# Keep the fire marker until defeat so Pyre can propagate the kill.
			if enemy.health > 0:
				enemy["burn_ticks"] = 0


func advance(delta: float, enemies: Array[Dictionary]) -> void:
	counter_time = maxf(0.0, counter_time - delta)
	if shield > 0:
		shield_time = maxf(0.0, shield_time - delta)
		if shield_time == 0.0:
			shield = 0
	var fallen: Array[Dictionary] = []
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if enemy.get("light_time", 0.0) > 0.0:
			enemy["light_time"] = maxf(0.0, enemy.light_time - delta)
		var ticks: int = enemy.get("burn_ticks", 0)
		if ticks == 0:
			continue
		enemy.burn_time -= delta
		while enemy.burn_time <= 0.0 and enemy.burn_ticks > 0:
			enemy.health -= 1
			if enemy.health <= 0:
				enemies.remove_at(index)
				fallen.append(enemy)
				break
			enemy.burn_ticks -= 1
			enemy.burn_time += BURN_INTERVAL
	for enemy in fallen:
		defeated.emit(enemy)


func spread(enemy: Dictionary, enemies: Array[Dictionary], geometry: RefCounted) -> void:
	if not pyre or enemy.get("burn_ticks", 0) == 0:
		return
	var origin: Vector2 = enemy.position
	for other in enemies:
		if other.get("spawn_time", 0.0) > 0.0 or other.get("burn_ticks", 0) > 0:
			continue
		if origin.distance_squared_to(other.position) <= PYRE_RADIUS * PYRE_RADIUS and (geometry == null or is_inf(geometry.segment_hit(origin, other.position))):
			_ignite(other, 2)


func _ignite(enemy: Dictionary, ticks: int) -> void:
	enemy["fire_meter"] = 0
	enemy["burn_ticks"] = ticks
	enemy["burn_time"] = BURN_INTERVAL
