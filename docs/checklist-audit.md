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


## Section 5 — The Exile art (initial pass; player revision superseded in section 6)

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


## Section 6 — Arena, enemies and visual language

Completed 2026-11-04, including the user-requested Exile hood correction. All 18 section-6 items have implementation/reference evidence. This is project prototype completion; it does not imply a published build or final difficulty approval.

| Checklist scope | Evidence |
| --- | --- |
| Art direction, grid, camera, light and color budget | Existing boards retained; docs/art/section6-spec.md defines 32px masonry, 16px icons, grounded 3/4 art and material colors |
| Floor tiles, walls, abyss/corners/transitions | Four low-contrast tile variants blend over courtyard repairs; repeating trim closes exact bounds; original illustrated abyss retained |
| Collidable pillars and ruins | Four textured props, shared base rectangles, swept actor/world collision and visibility-graph navigation |
| Integrated original arena, wisp and sentinel | Prior sprite/atlas implementations retained and reviewed beside new assets |
| Player/sentinel walk and directional views | Existing animation retained; Exile rebuilt from its original hooded concept with 31 generated directional/state/fall poses; player regression and 1,024-combination sweep |
| Aberration concept | Ruin Ram: low horned four-legged corrupted cathedral beast, four behavior poses, integrated as charger |
| Dedicated guardian, elite and boss art | Guardian cardinal views; Crowned Sentinel idle/walk/cast; Warden phase-specific idle/cast and broken halo |
| Player/hostile projectile distinction | Gold squares versus magenta diamonds retained, checked in dense gameplay |
| Blessing and remaining icons | Existing ranked blessing badges retained; seven new native icons in HUD, loadout, progression and pickups |
| In-game scale/contrast review | section6-arena.png, section6-warden-phase2.png, corrected player review, crowded gameplay and collision-overlay review |
| Provenance and consolidated conditions | Every PNG/SVG under assets/art is covered by updated SHA-256 inventory; new prompts persisted; CREDITS.md distinguishes original MIT, generated art records and font OFL notices |

Validation: full regression suite, new obstacle and asset-region checks, 512 enemy visual combinations, 1,024 player combinations and a fresh rendered dense benchmark. Interior obstacles also resolve section 3's previously conditional navigation item. Obstacles block player/hostile fire, muzzle paths, melee and pickup-through-wall interactions; ranged enemies route to line of sight rather than waiting behind cover. New arena props and images use the existing simulation coordinate system and preserve the Warden escort rules.

Generated PNGs were created with the built-in image-generation tool, copied into the repository unmodified and selected with AtlasTexture regions. Native SVG icons/tile accents extend the code-authored assets. Existing editor serialization, .vscode and unrelated image import files remain outside the commit.


Player-art correction after the section-6 review: the earlier block sprite was replaced by refined generated front/back/side nine-pose atlases and a four-pose defeat atlas, matching the original Exile concept and enemy material detail. Standing height is 32 logical pixels, nearest-sampled; animation timing and the shared weapon pivot are unchanged. The former native SVG and builder remain inactive history. Atlas alpha bounds are metadata only; source PNGs remain unmodified. Current art notes supersede the section-5 source-format and palette claims for the active player.


## Section 7 — Feedback and audio

Completed 2026-11-06 at prototype scope. The user chose subtle hit-stop and screen shake with disable options. All nine items now have implementation evidence.

| Scope | Evidence |
| --- | --- |
| Bounded impact/death/damage particles and flashes | Existing event connections retained; particles shortened to 0.22 s, velocity reduced, 3 px translucent muzzle flash and softer enemy hit tint |
| Effect intensity, duration and layer tuning | Per-kind short cue timings/opacity; projectiles now draw above actors, below cues/modal dimming/HUD; section7-dense/reduced engine captures |
| Spawn, dash, upgrade, heal and wave effects | feedback_smoke verifies successful events, expiry, freeze, capacity and reset |
| Shot, impact, elimination, damage, dash and menu sounds | Existing original synthesis, event_integration_smoke and audio_smoke retained |
| Combat music, Sanctuary ambience and transitions | Original eight-bar D-minor WAV loops and reproducible NumPy builder; persistent two-voice Music-bus playback, 1.25 s crossfade and smooth modal ducking |
| Independent saved volumes and bounded sound output | Existing four buses, safe preference writes, reserved UI voices and cue throttle retained; music gain/voice count also bounded |
| Hit-stop and shake decision/accessibility | 35 ms hold, 140 ms decaying shake up to 1.5 px per axis, 180 ms retrigger cooldown; separate saved options; Reduce visual motion disables both |

Verification: complete automated suite including five-rate impact timing, actual damage/critical feedback, saved options, scene handoff/crossfade, loop/routing/ducking, navigation and clean startup/shutdown. Graphical review covers dense combat, reduced settings and both options panels. Startup now boots the real main scene and exits through the same graceful audio shutdown used by Quit/window close; no warnings are suppressed. The long simulation remains a logic check, not human balancing. Speaker/headphone mix and subjective impact feel still need human playtesting.

Pre-existing project.godot serialization, .vscode and unrelated image imports remain outside this section's changes. No export or release is implied.


## Current priority 1 — Menus and work-in-progress entries

Completed 2026-11-06 following the user's new README priority order. Title now has exactly PLAY, OPTIONS, QUIT. Play contains SANCTUARY, ARENAS, ROGUELITE, CAMPAIGN, SOUNDTRACK, QUIT, with a separate Back button. The three unfinished entries show WORK IN PROGRESS and return to Play without starting combat or changing modes. Sanctuary retains its existing menu prototype pending priority 2.

Options preserves how-to-play, loadout, feedback, audio and keyboard settings in a compact layout. Back/Escape restores the immediate parent page and originating focus, including after re-equipping a weapon. Direct Arenas retain title return, while Sanctuary-launched runs retain hub return and existing records/XP settlement.

Evidence: full validation suite, including menu_routes_smoke actual button activation, persistent loadout and nested focus checks, navigation_smoke focus rings, existing both-mode/hub/reward flows, clean Quit from both title and Play, and the long simulation (wave 48, 19 upgrade choices, zero failures). Engine captures priority1-title/play/wip/options/options-error were visually reviewed for layout and readable save errors. No priority 2 house, Gabriel, skill purchases or new weapons were implemented in this change.


## Current priority 2 — Walkable Sanctuary home

Completed 2026-11-06 at prototype scope. The hub scene now opens the Exile's home: existing directional player art/movement, bounded marble room, solid bed/desk/books/hearth/arsenal/Gabriel, and a sheltered departure threshold. Original code-authored furnishings reuse the existing masonry palette; Gabriel has a new transparent generated sprite with preserved PNG, final prompt, hash and source record.

Interaction is proximity- and line-of-sight-gated. Enter/Space or the contextual button opens Gabriel, arsenal or departure. Gabriel provides dialogue, global progression and a read-only skill-tree introduction centered on Michael/the flaming sword, explicitly marked WORK IN PROGRESS. This completes the mentor/entry point for this priority without claiming priority 3 purchases or priority 4 weapons. The arsenal preserves both existing loadouts; the door preserves Arenas and future-mode WIP routes. Escape/menu/focus loss suspend home movement; nested Back restores focus, and final close restores walking at the same position.

Evidence: sanctuary_smoke checks input, speed/diagonals, long-step swept collision/bounds, paths to all stations, range/LOS rejection, Enter/Escape, modal freeze, mentor/preview nesting, persistent equipment, door routes, focus loss, reduced visuals and zero exploration XP/run allocation. Hub smoke now launches through actual door/Arenas/mode buttons and retains complete victory, both-mode defeat/retry, abandonment and reward deduplication coverage. Full import, startup, menu/navigation, combat/reward/audio suite and long simulation pass; the soak reached wave 48 with 19 choices and zero failures.

Engine screenshots under docs/art/priority2 cover home, Gabriel, knowledge introduction, progression, arsenal, departure and options. Visual review corrected the menu button width and separated station plaques from furniture. The house remains a prototype art pass; human usability and art feedback are still useful. Priority 3 remains open in the README. Existing editor serialization and unrelated local files remain untouched by this priority.


## Current priority 3 — Small functional skill tree

Completed 2026-11-06 at the user's explicitly requested small prototype scope, not as the final tree. Gabriel offers Michael (main Sword Ablaze/melee path), Gabriel (precision) and Raphael (restoration), with two nodes each. Roots cost one point and require no parent; children cost two and require their own root. The existing nineteen-point cap stays; all six nodes cost nine points. Free Sanctuary reset refunds learned costs without changing XP. New weapons remain priority 4.

Implementation: known-ID/prerequisite/budget validation extends the reserved profile skills field without invalidating empty-skill saves. Purchase/reset use the existing atomic save/backup path and refuse duplicate, unknown, unaffordable or future-version writes. UI shows learned/available/locked/insufficient states, visible effects and separate permanent points. Learned melee damage/reach, projectile speed, crit chance, maximum HP and dash recovery apply to both weapon loadouts from base Resources, then temporary blessings compose once; retry clears only temporary effects.

Verification: profile and Sanctuary checks plus skills_smoke cover save failure/retry, forged IDs/prerequisites/overspending, free refunds/reload, actual extended melee hits, permanent run attributes, blessing composition and nonduplicating retries. Available/learned tree screenshots were reviewed at the existing game scale. This documents a small testing tree, with balance and larger patron/weapon roster deliberately left for later work.
