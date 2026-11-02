extends RefCounted
## Owns run statistics and legal lifecycle transitions.
signal phase_changed(phase: Phase)
signal damaged(health: int)
signal enemy_defeated(total: int)

enum Phase { COMBAT, INTERMISSION, PAUSED, DEAD, UPGRADE }
const MAX_HEALTH: int = 5
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
	health = mini(health + 1, MAX_HEALTH)
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


func take_damage() -> void:
	if phase != Phase.COMBAT:
		return
	health = maxi(0, health - 1)
	if health == 0:
		_set_phase(Phase.DEAD)
	damaged.emit(health)


func record_kill() -> void:
	if phase == Phase.COMBAT:
		kills += 1
		enemy_defeated.emit(kills)


func reset() -> void:
	health = MAX_HEALTH
	kills = 0
	elapsed = 0.0
	resume_phase = Phase.COMBAT
	_set_phase(Phase.COMBAT)


func _set_phase(value: Phase) -> void:
	if phase != value:
		phase = value
		phase_changed.emit(phase)
