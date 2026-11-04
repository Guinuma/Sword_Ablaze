# Known issues and validation boundaries

Reviewed 2026-11-03 against the automated suite and graphical capture tools. This list records current limitations and reproduced fixes; it is not release certification or a substitute for human playtesting.

## Fixed during checklist continuation

- Section 2 live rendering exposed a folded/self-intersecting cape polygon during direction changes. A convex strip and collapsed-tip fallback now avoid triangulation failures; a graphical sweep covers 1,024 aim/movement/state combinations.
- Section 2 now includes user-requested melee and temporary critical chance via Keen Edge, with shared armor/reward rules. Hands/weapon attachment uses a smoothed shared pivot; final pixel-art poses remain later-section work.

- Charger warning failed to compile after its corridor width was tied to the profile contact radius. Giving the intermediate vector an explicit type fixes the parser error; full import/combat checks and graphical runs now pass.
- The empty-encounter fallback regression assigned an untyped array to a typed Resource field and stalled. The test now supplies `Array[Resource]`; exact spawn-pattern and fallback checks pass.
- Keyboard navigation could leave blessing choices for the combat pause button. Closed focus rings now exclude hidden/disabled controls, and keyboard-input tests cover menus, options, pause, choices and results.
- Help and pause restart instructions retained default key names after remapping. They now derive names from the active InputMap, with a remapped-help regression.
- Immediate test shutdown reported leaked audio playback/WAV references. Sound-effects scene teardown now stops voices and releases their streams. Audio-using tests free their scenes and allow 0.35 s for the audio server to retire pending playback references before quitting. Clean full-suite runs verify this lifecycle instead of suppressing warnings.
- Upgrade feedback could be occluded by the actor sprite. Short feedback cues now draw above actors and below modal dimming/HUD; normal/reduced-settings captures were reviewed.

## Open issues and limitations

| Area | Remaining work | Evidence or reproduction |
| --- | --- | --- |
| Difficulty | Follow-up review of Warden reinforcements and measured run duration | User confirmed full runs with both weapons on 2026-11-04; requested Warden reinforcements are implemented. Automated clearing does not establish balance. |
| Audio | Listen on real speakers/headphones; refine synthesized effects; compose music and transitions | Current effects are original synthesized prototype tones; no music is included. |
| Art | Final native-resolution sprites, hands/weapon/cape alignment, dedicated ram/guardian art | Ram and guardian are geometric placeholders; integrated character art still needs pixel cleanup. |
| Accessibility | UI scale/fullscreen/aspect-ratio checks, controller decision, full localization plan | Current visual reviews focus on the 640 × 360 layout at 1280 × 720. Very long custom key names can crowd compact HUD labels. |
| Game loop | Implement skill purchases; playtest reinforced boss and global reward pacing | Endless Arena repeats encounters; Courtyard Run now has a boss and local victories, global XP is now saved on results, and Sanctuary supports entry, retry and return. |
| Persistence | Migrations, skill purchases and interrupted-write recovery testing | Profile tests now cover safe writes, corruption, reward identity and failed-save retries; migration/purchase and power-loss coverage remain pending. |
| Performance | More hardware and real-session measurements | The rendered benchmark is one Windows integrated-GPU machine under seeded load. |
| Distribution | Platform/channel decisions, export presets, clean-machine validation and consolidated credits | No demo release is authorized or implied by a passing prototype suite. |

Run `python tools/validate.py --godot <executable>` before expanding behavior. Graphical capture tools supplement logic tests; every new feature should keep its remaining visual/playtest limits explicit. Existing local editor configuration is outside these fixes and is left uncommitted.
