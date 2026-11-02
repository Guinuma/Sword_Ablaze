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
