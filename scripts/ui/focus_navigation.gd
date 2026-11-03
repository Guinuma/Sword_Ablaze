extends RefCounted
## Explicit closed focus paths keep modal keyboard navigation inside its controls.
static func ring(controls: Array[Control]) -> void:
	if controls.is_empty():
		return
	for index in range(controls.size()):
		var current := controls[index]
		var previous := current.get_path_to(controls[(index - 1 + controls.size()) % controls.size()])
		var next := current.get_path_to(controls[(index + 1) % controls.size()])
		current.focus_previous = previous
		current.focus_next = next
		current.focus_neighbor_top = previous
		current.focus_neighbor_bottom = next
		current.focus_neighbor_left = previous
		current.focus_neighbor_right = next

static func collect(node: Node, result: Array[Control]) -> void:
	if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL:
		if not node is BaseButton or not node.disabled:
			result.append(node)
	for child in node.get_children():
		collect(child, result)
