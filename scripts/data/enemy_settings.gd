extends Resource
## Shared tuning data; runtime state belongs to simulation components.

@export_range(1, 1000) var health: int = 2
@export_range(0.001, 1000.0) var speed: float = 46.0
@export_range(0.001, 1000.0) var speed_per_wave: float = 3.0
@export_range(0.001, 1000.0) var max_speed: float = 90.0
@export_range(0.001, 1000.0) var hit_radius: float = 10.0
@export_range(0.001, 1000.0) var contact_radius: float = 15.0
@export_range(0.001, 1000.0) var separation_distance: float = 18.0
@export_range(0.001, 1000.0) var body_margin: float = 8.0
@export_range(0.1, 5.0) var spawn_warning: float = 0.7
@export_range(16.0, 200.0) var spawn_safe_distance: float = 56.0
@export_enum("chaser", "ranged", "charger", "guardian") var kind: String = "chaser"
@export_range(32.0, 400.0) var preferred_distance: float = 150.0
@export_range(32.0, 600.0) var attack_range: float = 230.0
@export_range(0.1, 10.0) var attack_cooldown: float = 1.8
@export_range(0.1, 3.0) var attack_warning: float = 0.65
@export_range(20.0, 500.0) var projectile_speed: float = 130.0

@export_range(1, 1000) var projectile_damage: int = 50

@export_range(20.0, 600.0) var charge_speed: float = 300.0
@export_range(0.05, 2.0) var charge_duration: float = 0.45
@export_range(0.1, 3.0) var charge_recovery: float = 0.8

@export_range(0.1, 10.0) var turn_speed: float = 1.1
@export_range(0.0, 1.0) var knockback_multiplier: float = 1.0
