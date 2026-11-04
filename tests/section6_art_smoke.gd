extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _run() -> void:
	for kind in ["charger", "guardian", "elite", "warden"]:
		var frames: SpriteFrames = load("res://assets/art/enemies/%s-02-frames.tres" % kind)
		check(frames.get_frame_count(&"poses") == 4, "Each enemy must have four integrated state/direction poses")
		for index in range(4):
			var texture: AtlasTexture = frames.get_frame_texture(&"poses", index)
			var size := texture.atlas.get_size()
			var cell := Rect2(Vector2(index % 2, index / 2) * size / 2, size / 2)
			check(cell.encloses(texture.region), "Atlas frames must never sample an adjacent sprite")
			check(texture.region.size.x > 0 and texture.region.size.y > 0, "Integrated sprite crops must be nonempty")
		check(frames.get_frame_texture(&"poses", 0).atlas.get_image().get_pixel(0, 0).a == 0.0, "Enemy sheet must retain genuine transparency")
	var icons = load("res://scripts/ui/game_icons.gd")
	check(icons.TEXTURES.size() == 7, "Current weapon, healing, XP and ability icons must all be available")
	for texture in icons.TEXTURES.values():
		check(texture.get_size() == Vector2(16, 16), "UI icons must share the native 16px grid")
	print("Section 6 art checks complete: %d failures" % failures)
	quit(1 if failures else 0)
