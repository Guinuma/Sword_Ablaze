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

Section 2 was completed previously; sections 3 and 4 were authorized on 2026-11-04. All 17 items are implemented or explicitly decided for prototype scope. Current movement/fire/dash timings were retained after the user's playtest response: “Current speed and timing feel good.” This does not claim final release balance or external playtesting.

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


## Sections 3 and 4 — Enemies, encounters and Arena

Reviewed 2026-11-04 at prototype scope. The user confirmed complete runs with both weapons and requested Warden reinforcement pressure with about ten enemies at once. Applied as ten total including the boss and pending warnings, with a 2.5-second mixed escort cadence. Follow-up review of the changed boss and measured run duration remain pending; these checkmarks do not claim final balance.

| Scope | Evidence |
| --- | --- |
| Pursuit, wall separation, knockback, safe spawns and caps | combat_smoke and run_soak; enemy_system.gd |
| Ranged, charge, guardian and elite behavior | combat/charger/guardian/elite smoke checks; docs/enemies.md |
| Encounter introductions, compositions and repetition | encounter_smoke; nine Resource recipes; user full-run feedback |
| Two-phase Warden, reinforcements and rewards | finite_run_smoke, boss_reinforcement_smoke, profile/reward checks |
| Navigation | Explicitly deferred until section 6 adds interior collision obstacles; the current open arena uses direct movement |
| Simultaneous damage, chain kills, terminal freeze and reset | combat_smoke, finite_run_smoke and reinforcement checks |
| Wave growth, cadence, healing, intervals and HUD | combat_smoke, encounter_smoke and finite_run_smoke |
| Finite/Endless entry, records and saved XP/level | menu_smoke, hub_smoke, reward_flow_smoke and profile_smoke |
| Victory/defeat, retry and Sanctuary return | hub_smoke uses result buttons for victory return and both-mode defeat retry/return; reinforcement check covers victory retry |
| Opening, middle and advanced playtesting | User reported full runs with both weapons; Warden feedback implemented; exact timing not supplied |

No later-section art or interior obstacles were introduced. Existing project.godot serialization, .vscode and unrelated image imports stay outside this commit.


## Section 5 — The Exile art

Completed 2026-11-04 at the native-grid prototype scope. All 17 checklist items are implemented or retained with updated native artwork. The active player no longer scales down generated body/walk/defeat sheets. Existing concept references and their provenance remain available.

| Scope | Evidence |
| --- | --- |
| Direction, concept boards and references | Original art-direction boards and prompts retained in docs/art |
| Fixed grid, palette and consistent pixels | exile-native.svg: 24 × 32 cells at 1:1, integer rectangles, twelve-color palette; reproducible builder; art notes |
| Transparent body, shadow, cape and free-aim weapon | ExileVisual native atlas, stepped shadow/cape, shared body/weapon palette |
| Mirrored center and directional idle/walk | Shared cell anchor, front/back/right with left mirror; four walk poses per view and separate idle |
| Dash, nonfatal hurt and defeat | Two dash/two hurt poses per view; four native defeat poses; player_art_smoke checks timing and reset |
| Hands, feet, shadow and muzzle | Native baseline, rounded grips; shared PlayerState.weapon_grip; existing combat and 360-degree continuity checks |
| Light/dark and dense-effects readability | exile-native-review.png and exile-native-gameplay.png, reviewed from actual Godot renders |
| Aim, diagonal movement, dash and overlays | Eight-direction state board, 1,024-combination graphical sweep, crowded combat/pause capture and full regression suite |

The previous generated player assets remain historical references. No section 6 enemy/environment art changes are included. This is a completed project art pass; external visual approval and broad hardware review are not implied. Existing unrelated local files remain outside the commit.
