# Keyboard bindings

Preferences version 1 accepts an optional `bindings` object mapping gameplay action names to physical Godot key codes. Missing fields restore project defaults. Mouse fire and menu navigation remain available. Escape stays reserved for cancellation and pause. Rebinding rejects keys already used by another gameplay action. Reset restores the project keyboard defaults.

Bindings share the preferences safe temporary write and backup path. Both menu and arena apply them on load. `tests/bindings_smoke.gd` covers reload, conflicts, reserved actions, mouse preservation and reset.
