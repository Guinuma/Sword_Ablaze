extends Resource
## One temporary upgrade; balance effects are applied from base stats each time.
@export var id: StringName
@export var title: String
@export var description: String
@export_enum("move_speed", "fire_interval", "damage", "knockback", "dash_cooldown", "max_health") var attribute: String = "move_speed"
@export var multiplier: float = 1.0
@export var addition: float = 0.0
@export_range(1, 10) var max_stacks: int = 3
