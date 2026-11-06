# Keyboard bindings

Preferences version 1 accepts an optional `bindings` object mapping gameplay action names to physical Godot key codes. Missing fields restore project defaults. Mouse fire and menu navigation remain available. Escape stays reserved for cancellation and pause. Rebinding rejects keys already used by another gameplay action. Reset restores the project keyboard defaults.

Bindings share the preferences safe temporary write and backup path. Both menu and arena apply them on load. `tests/bindings_smoke.gd` covers reload, conflicts, reserved actions, mouse preservation and reset.

Main menu → Options → Keyboard Bindings provides action buttons. Activate one with mouse or keyboard, press a new key, or cancel with Escape. Conflicts keep capture open with a message. Restore Defaults resets all eight actions and saves. Write failures are reported while the new binding remains active for the current session. Screenshots: `godot --path . --script tools/capture_controls.gd -- <absolute-png-path>`.

Every new arena run shows a short action-driven HUD tutorial: move, aim with the mouse, fire, dash, then select a blessing after wave three. Prompts use current keyboard bindings, wait for the corresponding action, hide under pause/results/choice overlays, and reset with the run. Combat continues normally. Tutorial state is temporary, not persistent progression. `tests/tutorial_smoke.gd` verifies ordered completion and reset; `tools/capture_tutorial.gd` captures all five prompts.

Menu navigation uses closed focus paths: Tab moves forward, Shift+Tab moves backward, arrows move between controls in reading order, and Enter activates buttons. Audio sliders consume left/right for volume adjustment. Focus borders remain visible. Home, detail pages, pause, results and blessing choices each restrict navigation to their visible controls. Pausing a blessing choice and resuming restores choice focus. `tests/navigation_smoke.gd` sends Tab input through complete cycles across these screens and checks visible focus styles; it also checks pause/choice focus restoration.

Melee uses right-click or E by default and can be remapped alongside the other gameplay keys. Holding repeats only after the 0.45 s cooldown. Release after pause, restart or a blessing choice before attacking again. The swing blocks gunfire for its 0.16 s animation. Keen Edge can grant critical hits to both attacks; it is an ordinary temporary blessing and resets with the run.


## Sanctuary home

Sanctuary walking uses the same saved movement actions and normalized speed as combat. Enter/Space or the on-screen contextual button interacts with a nearby, unobstructed station: Gabriel (knowledge/progression), the arsenal (loadout), or the door (modes/title). Firing, melee and dash inputs never perform combat actions in the house. Escape/Menu opens the hub menu; losing application focus also opens it. Open dialogue/options/departure panels suspend movement. Back/Escape restores the parent panel, or returns control to walking after the final panel closes. The movement legend reflects remapped keys and clips long names to fit the footer.
