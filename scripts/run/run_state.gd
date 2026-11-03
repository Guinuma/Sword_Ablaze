extends RefCounted
## Owns run statistics and legal lifecycle transitions.
signal phase_changed(phase: Phase)
signal damaged(health: int)
signal healed(amount: int)
signal enemy_defeated(total: int)

enum Phase { COMBAT, INTERMISSION, PAUSED, DEAD, UPGRADE }
const MAX_HEALTH: int = 100
const HIT_DAMAGE: int = 15
var max_health: int = MAX_HEALTH
var phase: Phase = Phase.COMBAT
var resume_phase: Phase = Phase.COMBAT
var health: int = MAX_HEALTH
var kills: int = 0
var elapsed: float = 0.0


func is_active() -> bool:
	return phase == Phase.COMBAT or phase == Phase.INTERMISSION


func advance(delta: float) -> void:
	if is_active():
		elapsed += delta


func set_paused(value: bool) -> void:
	if phase == Phase.DEAD:
		return
	if value and (is_active() or phase == Phase.UPGRADE):
		resume_phase = phase
		_set_phase(Phase.PAUSED)
	elif not value and phase == Phase.PAUSED:
		_set_phase(resume_phase)


func start_intermission() -> void:
	if phase != Phase.COMBAT:
		return
	heal(20)
	_set_phase(Phase.INTERMISSION)


func start_combat(_wave: int) -> void:
	if phase == Phase.INTERMISSION:
		_set_phase(Phase.COMBAT)


func start_upgrade() -> void:
	if phase == Phase.INTERMISSION:
		_set_phase(Phase.UPGRADE)


func finish_upgrade() -> void:
	if phase == Phase.UPGRADE:
		_set_phase(Phase.INTERMISSION)


func take_damage(amount: int = HIT_DAMAGE) -> void:
	if phase != Phase.COMBAT or amount <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		_set_phase(Phase.DEAD)
	damaged.emit(health)


func record_kill() -> void:
	if phase == Phase.COMBAT:
		kills += 1
		enemy_defeated.emit(kills)


func reset() -> void:
	max_health = MAX_HEALTH
	health = MAX_HEALTH
	kills = 0
	elapsed = 0.0
	resume_phase = Phase.COMBAT
	_set_phase(Phase.COMBAT)


func _set_phase(value: Phase) -> void:
	if phase != value:
		phase = value
		phase_changed.emit(phase)


func heal(amount: int) -> int:
	if not is_active() or amount <= 0 or health <= 0:
		return 0
	var previous := health
	health = mini(max_health, health + amount)
	var recovered := health - previous
	if recovered > 0:
		healed.emit(recovered)
	return recovered


func set_max_health(value: int) -> void:
	var next := maxi(MAX_HEALTH, value)
	var increase := maxi(0, next - max_health)
	max_health = next
	if health > 0:
		health = mini(max_health, health + increase)
