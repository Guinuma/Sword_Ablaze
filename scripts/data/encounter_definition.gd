extends Resource
## One wave recipe; the director repeats its ordered spawn pattern to the budget.
@export var title: String = "Pursuit"
@export var pattern: Array[StringName] = [&"chaser"]
@export_range(0.25, 2.0) var budget_multiplier: float = 1.0
@export_range(0.25, 3.0) var interval_multiplier: float = 1.0

@export var opener: StringName = &""
