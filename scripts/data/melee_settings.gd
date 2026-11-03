extends Resource
@export_range(1, 100) var damage: int = 2
@export_range(1.0, 100.0) var reach: float = 32.0
@export_range(0.1, 3.14) var half_angle: float = PI / 3.0
@export_range(0.1, 3.0) var cooldown: float = 0.45
@export_range(0.05, 1.0) var duration: float = 0.16
@export_range(0.0, 500.0) var knockback: float = 170.0
