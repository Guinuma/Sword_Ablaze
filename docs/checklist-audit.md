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

## Section 2 — Player and base combat

Section 2 is the last authorized section in this continuation. Do not begin Section 3 after closing it. All 17 items are implemented or explicitly decided for prototype scope. Current movement/fire/dash timings were retained after the user's playtest response: “Current speed and timing feel good.” This does not claim final release balance or external playtesting.

| Checklist item | Evidence |
| --- | --- |
| Normalized movement, bounds and mouse aim | Input.get_vector in main; PlayerState movement/clamping and combat checks |
| Continuous fire and projectile cleanup | PlayerState timing, ProjectileSystem bounds/lifetime; combat and weapon checks |
| Segment collision | ProjectileSystem segment/circle nearest-hit query; high-speed collision regressions |
| Nearest enemy only and projectile consumption | combat_smoke target ordering and repeated-hit checks |
| Health/contact protection/death/restart | RunState and shared damage gate; combat/finite-run checks |
| 100 base HP, max-health blessing and healing drops | combat/healing regression cases; RunState and HealingDrops |
| Directional dash, cooldown and bounds | PlayerState; combat checks at multiple physics rates |
| Pause/resume | RunState phases; combat/menu/navigation checks |
| Tune control timing/hitboxes in playtests | User approved existing feel; movement/dash/fire timings retained; physical and visual weapon pivot refined |
| Dash protection at 30/60/120/144/240 Hz | combat_smoke tests start/end against contact and projectiles |
| Shared weapon/shot/flash pivot | PlayerState.weapon_grip used by muzzle and ExileVisual; cardinal and 360-angle continuity checks |
| Hands and weapon across aim directions | New sleeves/hand grips, smooth attachment; eight-direction enlarged engine capture and 1,024-combination graphical sweep |
| Fresh trigger after pause/restart | fire release gates; existing combat tests |
| Fresh trigger after resume/restart/choice | shared fire/melee release gates; combat and melee-flow checks |
| Focus-loss pause and explicit resume | application-focus notification and RunState; combat regression checks |
| Blade behavior decision | User requested melee; right-click/E, forward 120-degree swing, 32 px plus target radius, 2 damage, 0.45 s cooldown |
| Ammo/critical/status decision | User requested critical hits or statuses; Keen Edge provides up to 30% critical chance and x2 damage. Ammo remains unlimited; reload/status systems deferred |

Melee and projectiles share damage/armor ordering and impact/defeat events, so critical hits do not bypass guardian rules or duplicate rewards. `melee_critical_smoke.gd` verifies targeting, damage, cooldown rates, reset and upgrade limits; `melee_flow_smoke.gd` verifies real input, feedback, kill counting and pause/release behavior.

The live graphical session exposed a self-intersecting cape polygon during direction changes. It was replaced with a convex strip that stays drawable even at a collapsed tip. Geometry checks cover 360 directions and five tip distances; `tools/validate_player_visual.gd` rendered 1,024 facing/travel/state combinations without errors. Final pixel cleanup, directional sprite replacement and broader difficulty testing remain in later sections and were not undertaken here.

Only the new melee input action is staged from project.godot. The user's pre-existing editor serialization changes, .vscode settings and unrelated image import files remain uncommitted.
