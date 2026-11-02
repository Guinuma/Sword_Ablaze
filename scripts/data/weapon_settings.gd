extends Resource
## Shared tuning data; runtime state belongs to simulation components.

@export_range(0.001, 1000.0) var fire_interval: float = 0.16
@export_range(0.001, 1000.0) var projectile_speed: float = 360.0
@export_range(1, 1000) var damage: int = 1
@export_range(0.001, 1000.0) var knockback: float = 135.0
@export_range(0.001, 1000.0) var muzzle_offset: float = 16.0
