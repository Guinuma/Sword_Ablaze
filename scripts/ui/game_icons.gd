extends RefCounted
const TEXTURES = {
	&"sword_ablaze": preload("res://assets/art/icons/sword_ablaze.svg"),
	&"dawn_bow": preload("res://assets/art/icons/dawn_bow.svg"),
	&"seraph_halberd": preload("res://assets/art/icons/seraph_halberd.svg"),
	&"judgment_lance": preload("res://assets/art/icons/judgment_lance.svg"),
	&"xp": preload("res://assets/art/icons/xp.svg"),
	&"feather": preload("res://assets/art/icons/feather.svg"),
	&"wings": preload("res://assets/art/icons/wings.svg"),
	&"dash": preload("res://assets/art/icons/dash.svg"),
	&"melee": preload("res://assets/art/icons/melee.svg"),
}
static func get_icon(id: StringName) -> Texture2D:
	return TEXTURES.get(id, TEXTURES[&"sword_ablaze"])
