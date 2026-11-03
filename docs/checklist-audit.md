# Checklist review by section

Work proceeds in README section order. Review existing checkmarks against the current code and verification, finish remaining actionable items, and push only after the section is finished and validated. Human playtests and undecided product choices must remain open until there is appropriate evidence or a decision. A passing logic test is not evidence of human balance or final art quality.

## Section 1 — Technical foundation

Reviewed against source and the validation suite on 2026-11-03. All 21 items are implemented at prototype scope. Evidence:

| Checklist item | Current evidence |
| --- | --- |
| Godot/GDScript/Compatibility setup | project.godot, CONTRIBUTING.md; Godot 4.5.1 import/startup checks |
| Logical viewport, window, scaling/filter | project.godot: 640 × 360, 1280 × 720, integer canvas scaling, nearest filtering |
| Functional scenes and folders | scenes/main/{menu,hub,main}.tscn; scripts, assets and resources trees; scene-flow checks |
| Repository, MIT license, contribution guide | Git history, LICENSE, CONTRIBUTING.md |
| Projectile simulation component/events | scripts/combat/projectile_system.gd; combat and event-integration checks |
| Enemy spawn/movement/separation/contact component | scripts/enemies/enemy_system.gd; combat/charger/guardian/elite checks |
| Player movement/dash/fire timing component | scripts/player/player_state.gd; combat and weapon checks |
| HUD presentation component | scripts/ui/arena_hud.gd; navigation/menu/feedback checks and graphical captures |
| Wave component/events | scripts/run/wave_director.gd; combat, encounter and event-integration checks |
| Run health/kills/time state | scripts/run/run_state.gd; combat and complete-run checks |
| Explicit phases and pause restoration | RunState.Phase; combat/navigation/finite-run pause and terminal checks |
| Upgrade selection/freeze/pause integration | upgrade_system.gd, RunState.UPGRADE; combat/soak/navigation checks |
| Reusable weapon/enemy/wave Resources | scripts/data and resources/default_*.tres; configuration regression checks |
| Reusable temporary-upgrade Resources | resources/upgrades; accumulation/limits/reset checks in combat suite |
| Central damage/kill/wave events | RunState signals, WaveDirector signals and main-scene connections |
| Audio/reward event integration | tests/event_integration_smoke.gd: real shot → projectile/audio, impact/kill → audio/counter, wave clear → audio/counter, terminal result → 11 saved XP exactly once |
| Input Map preservation | project.godot defaults and preferences.apply_bindings; bindings/menu checks preserve mouse fire and menu actions |
| Safe visual preferences | preferences.gd validation/temporary writes/backup; combat/menu preference persistence checks |
| Saved keyboard remapping | preferences bindings and keyboard settings screen; binding/menu/navigation checks |
| Collision/layer/group/pivot conventions | docs/technical-conventions.md, current collision/draw code and combat regressions |
| Bounded entities and dense measurements | projectile/enemy/particle caps; soak checks; docs/performance simulation and rendered baselines |

The new event-integration regression follows the real scene connections rather than calling the audio/reward helpers directly. It also verifies that a repeated terminal event cannot duplicate global XP or local records. It uses isolated preferences, records and profile files.

The existing uncommitted project.godot changes expand InputEvent serialization while preserving the configured physical keys and display/renderer values; they remain outside these commits. Editor configuration and unrelated image import files are also left untouched.

Next review: Section 2 — Player and base combat. Its unchecked playtest, art-alignment and design-decision items are not implied complete by this foundation review.
