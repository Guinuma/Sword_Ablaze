extends Resource
## Shared tuning data; runtime state belongs to simulation components.

@export_range(0.001, 1000.0) var fire_interval: float = 0.16
@export_range(0.001, 1000.0) var projectile_speed: float = 360.0
@export_range(1, 1000) var damage: int = 1
@export_range(0.001, 1000.0) var knockback: float = 135.0
@export_range(0.001, 1000.0) var muzzle_offset: float = 16.0

@export_range(1, 9) var pellets: int = 1
@export_range(0.0, 1.5) var spread: float = 0.0

@export_range(0.0, 1.0) var critical_chance: float = 0.0
@export_range(1.0, 5.0) var critical_multiplier: float = 2.0
