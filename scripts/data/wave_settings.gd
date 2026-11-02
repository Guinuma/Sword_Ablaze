extends Resource
## Shared tuning data; runtime state belongs to simulation components.

@export_range(1, 1000) var max_enemies: int = 18
@export_range(1, 1000) var initial_budget: int = 5
@export_range(1, 1000) var budget_growth: int = 2
@export_range(1, 1000) var max_budget: int = 40
@export_range(0.001, 1000.0) var spawn_interval: float = 1.6
@export_range(0.001, 1000.0) var interval_reduction: float = 0.1
@export_range(0.001, 1000.0) var min_spawn_interval: float = 0.4
@export_range(0.001, 1000.0) var break_duration: float = 3.0
@export_range(0.001, 1000.0) var initial_delay: float = 0.8
@export_range(0.001, 1000.0) var next_wave_delay: float = 0.3
@export_range(1, 1000) var ranged_start_wave: int = 3
@export_range(1, 1000) var ranged_every: int = 3
