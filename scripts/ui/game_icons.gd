extends RefCounted
const TEXTURES = {
	&"blade": preload("res://assets/art/icons/blade.svg"),
	&"scatter": preload("res://assets/art/icons/scatter.svg"),
	&"xp": preload("res://assets/art/icons/xp.svg"),
	&"feather": preload("res://assets/art/icons/feather.svg"),
	&"wings": preload("res://assets/art/icons/wings.svg"),
	&"dash": preload("res://assets/art/icons/dash.svg"),
	&"melee": preload("res://assets/art/icons/melee.svg"),
}
static func get_icon(id: StringName) -> Texture2D:
	return TEXTURES.get(id, TEXTURES[&"blade"])
