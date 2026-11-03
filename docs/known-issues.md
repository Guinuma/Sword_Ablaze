# Known issues and validation boundaries

Reviewed 2026-11-03 against the automated suite and graphical capture tools. This list records current limitations and reproduced fixes; it is not release certification or a substitute for human playtesting.

## Fixed during checklist continuation

- Charger warning failed to compile after its corridor width was tied to the profile contact radius. Giving the intermediate vector an explicit type fixes the parser error; full import/combat checks and graphical runs now pass.
- The empty-encounter fallback regression assigned an untyped array to a typed Resource field and stalled. The test now supplies `Array[Resource]`; exact spawn-pattern and fallback checks pass.
- Keyboard navigation could leave blessing choices for the combat pause button. Closed focus rings now exclude hidden/disabled controls, and keyboard-input tests cover menus, options, pause, choices and results.
- Help and pause restart instructions retained default key names after remapping. They now derive names from the active InputMap, with a remapped-help regression.
- Immediate test shutdown reported leaked audio playback/WAV references. Sound-effects scene teardown now stops voices and releases their streams. Audio-using tests free their scenes and allow 0.35 s for the audio server to retire pending playback references before quitting. Clean full-suite runs verify this lifecycle instead of suppressing warnings.
- Upgrade feedback could be occluded by the actor sprite. Short feedback cues now draw above actors and below modal dimming/HUD; normal/reduced-settings captures were reviewed.

## Open issues and limitations

| Area | Remaining work | Evidence or reproduction |
| --- | --- | --- |
| Difficulty | Human playtesting of opening, middle and late waves; tune mixes and upgrades | Deterministic soak clears enemies automatically and does not measure difficulty. |
| Audio | Listen on real speakers/headphones; refine synthesized effects; compose music and transitions | Current effects are original synthesized prototype tones; no music is included. |
| Art | Final native-resolution sprites, hands/weapon/cape alignment, dedicated ram/guardian art | Ram and guardian are geometric placeholders; integrated character art still needs pixel cleanup. |
| Accessibility | UI scale/fullscreen/aspect-ratio checks, controller decision, full localization plan | Current visual reviews focus on the 640 × 360 layout at 1280 × 720. Very long custom key names can crowd compact HUD labels. |
| Game loop | Define finite run/win condition, elite and boss, rewards and hub | Current Arena continues through repeating encounter recipes; no victory or global XP exists. |
| Persistence | Global profile, migrations, skill purchases and reward deduplication | Existing save tests cover preferences and local records only. |
| Performance | More hardware and real-session measurements | The rendered benchmark is one Windows integrated-GPU machine under seeded load. |
| Distribution | Platform/channel decisions, export presets, clean-machine validation and consolidated credits | No demo release is authorized or implied by a passing prototype suite. |

Run `python tools/validate.py --godot <executable>` before expanding behavior. Graphical capture tools supplement logic tests; every new feature should keep its remaining visual/playtest limits explicit. Existing local editor configuration is outside these fixes and is left uncommitted.
