# Sanctuary: the Exile's home

PLAY → SANCTUARY now opens a walkable, non-combat home. The Exile uses the existing directional sprite, normal movement speed and saved movement bindings. A sheltered marble room contains a bed, desk, books, hearth, weapon rack and Gabriel. The shared layout defines all furniture footprints and three reachable interaction stations; actor movement uses the existing swept/sliding world collision, with an eight-pixel body radius and room bounds. The house has its own layout and does not alter arena obstacles.

## Walk and interact

Walk with WASD/arrows or your remapped movement keys. Approach a station and press Enter/Space, or click the contextual action at the bottom of the screen. The prompt enables only within 46 logical pixels and with a clear line to the interaction point. Walking onto the threshold alone never starts or abandons a run.

- Gabriel opens a mentor conversation, a read-only skill-tree introduction and the existing global progression screen. Michael and the flaming sword are introduced as the main path. Purchases and unlocks explicitly say WORK IN PROGRESS until priority 3; no points are spent or fake skills granted here.
- The arsenal opens the existing persistent Blade Rifle/Ember Fan loadout. Saved equipment applies when entering an arena and survives retries and return home.
- The door opens Arenas, Roguelite, Campaign and Title Screen. Arenas leads to the existing finite/Endless selection; the unfinished modes retain WORK IN PROGRESS.

Escape or Menu opens Resume, Options, Title Screen and Quit. Options retains feedback, audio, bindings, help and loadout. Menus freeze house movement; Back/Escape restores their immediate parent and focus. Closing the final panel releases UI focus back to walking, at the same position. Losing application focus also opens the hub menu. There are no shots, melee attacks, dashes, enemies or combat rewards in the home. The Sanctuary music continues through its menus and scene transitions.

## Scenes, presentation and saved state

`scenes/main/hub.tscn` now uses `scripts/hub/sanctuary.gd`, which reuses the existing menu/detail helpers while replacing the old overview with a walkable room. `sanctuary_layout.gd` owns physical bases and station positions; `sanctuary_art.gd` presents furnishings at those bases. Props and the Exile share Y sorting. Labels, prompts and controls draw above the world; modal dimming sits below detail panels. Existing native masonry tiles and the Exile atlas are reused. Gabriel uses a new transparent sprite generated with the built-in image tool, stored unmodified at assets/art/hub/gabriel-01.png; the final prompt is docs/art/gabriel-01-prompt.txt and its SHA-256/source record is in docs/art/asset-provenance-01.json. Alpha metadata selects the sprite without rewriting the PNG; it draws at 42 logical pixels including the halo. No combat scene is instantiated while exploring.

The top bar displays global level/XP, including profile recovery/unavailable states. Gabriel's progression page also shows available points. Exploration, dialogue and reopening progression do not allocate a run or grant XP. Position is temporary: entering or returning home starts at the safe central rug. No save migration or new progression schema is needed for this priority.

Runs launched from the door return home from pause or results. Retry stays in the selected mode and starts a fresh run. Successful result rewards settle before return, and failed pending saves retain the existing retry flow. Abandoning active combat returns without completion XP. Direct PLAY → ARENAS entry still returns to the title route.

## Verification

`tests/sanctuary_smoke.gd` verifies movement action/speed, normalized diagonals, long-step bounds and solid collision, reachable paths to every station, line-of-sight/range gating, real Enter/Escape input, mentor/preview/focus flow, modal movement freeze, arsenal persistence, door WIP routes, options/resume, focus-loss pause, visual reductions and zero exploration rewards. `tests/hub_smoke.gd` now launches through actual door/menu buttons and retains finite victory, both-mode defeat/retry, abandonment and saved-XP checks. Menu routes, reward, navigation and full-suite checks remain required.

`tools/capture_hub.gd` captures the home, Gabriel, knowledge preview, progression, arsenal, departure and options with isolated preferences and a 300-XP profile fixture. Current review images live in docs/art/priority2. Human usability, art and balance playtests remain useful; skill purchases and new weapons are later priorities.

## Priority 1 menu routes (2026-11-06)

Title offers PLAY, OPTIONS and QUIT. Play contains SANCTUARY, ARENAS, ROGUELITE, CAMPAIGN, SOUNDTRACK and QUIT, plus Back. ROGUELITE, CAMPAIGN and SOUNDTRACK are visible entries that open WORK IN PROGRESS, without starting combat or altering the selected mode. Soundtrack is a future page; background music and independent audio sliders already work.

`tests/menu_routes_smoke.gd` activates actual buttons to verify the requested ordering, WIP behavior, parent/focus restoration, Options routes, Sanctuary entry and both direct arena modes. Navigation checks cover closed focus cycles; startup checks activate Quit from both title and Play. `tools/capture_menu_routes.gd` reproduces the priority-1 menu screenshots.
