# First finite run: prototype decisions

Decision date: 2026-11-03. This defines the implementation target for the first complete run. Finite Courtyard Run, the Warden boss, terminal victory, separate local win records and mode selection are now implemented. Global XP is now awarded through the shared profile contract; the Sanctuary hub is implemented and skill purchases remain pending. User full-run feedback was received on 2026-11-04; exact run duration remains unmeasured.

## Structure and duration

The finite run uses the existing nine encounter recipes in order, followed by a single boss encounter on wave ten. Wave ten has one boss with recurring escorts while it is alive, no ordinary enemy budget and no extra spawns after the boss dies. The existing elite opens wave nine. This reuses the validated introductions and gives the boss a clear final encounter instead of adding an arbitrary timer ending.

Target duration is 10–15 minutes for a successful early playtest, including upgrade selection and the boss. This is a tuning target, not a timeout, minimum duration or measured result. Faster wins are valid. A run never ends merely because time passes. Current automated timings and spawn budgets do not prove this duration; tune it through human runs after the complete flow exists.

The player selects a melee weapon and a ranged weapon before entering. Movement, aim, dash and damage protection remain the same. Temporary blessings are offered after clearing waves 3, 6 and 9, before the next intermission completes. Clearing wave nine therefore always offers the last eligible blessing before the boss. Exhausting all eligible upgrades skips the choice rather than blocking progression.

Ordinary waves retain the existing three-second intermission and up-to-20-HP recovery on clear. The run does not add shops, currency, rerolls, ammo or a time-pressure economy as a prerequisite for its first complete version. Broader economy decisions remain separate checklist work.

## Terminal outcomes

Victory requires the final boss to be defeated while the player is alive and the run is in active combat. Remaining escorts and pending warnings are dismissed when the Warden dies, and no hostile projectile may remain able to damage the player after victory. Victory is a dedicated terminal state: stop simulation, clear combat projectiles, show a clear result heading and summary, and allow Retry or Return. It must not reuse the defeat animation or record a victory as a death.

Defeat occurs at zero HP, including the boss encounter. Keep the existing fall animation and defeat summary. Contact and projectile damage share the existing gate. If player death has already transitioned the run to defeat, a later same-step boss-death callback must not overwrite it with victory. A terminal outcome may be recorded or rewarded only once.

Retry starts wave one with the selected loadout, full base HP and no temporary upgrades, enemies, projectiles, drops or feedback left from the previous run. It requires a fresh firing trigger. Leaving a live run abandons it; it does not award a victory or defeat completion reward.

The result screen returns to the main menu while a hub is absent. Once the minimal hub exists, the same Return action leads there. No fake hub or permanent-reward claim is needed to finish the combat prototype; the full hub/reward loop stays unchecked until it is actually implemented and tested.

## Endless variant

Keep Endless Arena as an explicit separate selection. It continues cycling recipes 7–9 after wave nine, with the existing budget, simultaneous-enemy and spawn-rate caps. It has no finite boss win condition. Its defeats retain their survival-oriented wave/kill/time records. Finite results must be labeled separately so a ten-wave completion is not confused with an endless survival record.

Play Arena now opens a mode choice between Courtyard Run and Endless Arena. Entry, boss, terminal result, retry and return are implemented. The 20-minute soak must continue exercising Endless Arena; add separate finite-run coverage rather than silently truncating the existing stress test.

## Implementation and acceptance gates

1. Add a mode-aware run/director configuration with nine ordinary encounters plus the boss finale; keep endless configuration explicit and test both.
2. Implement a boss with announced attacks, recognizable phase change and a clear reward/result event. Its art may initially be a documented placeholder; final art remains checklist work.
3. Add terminal victory state, result presentation, mode labeling, retry and return. Verify that terminal callbacks cannot deliver results twice.
4. Test clean victory, boss defeat of the player, pause/focus loss, upgrade-before-boss flow, reset from every terminal screen, and no post-result combat damage.
5. Define and implement permanent reward/profile rules before displaying or awarding XP. Local records alone are not progression.
6. Play complete runs with both weapons, record actual duration and difficulty, and tune toward the target. Keep playtest and final-balance items open until human evidence exists.

Global XP, skill trees, global reward amounts, boss permanent drops, save migration and export platforms are not decided by this document. Those contracts must be defined and validated in their own checklist work.


## Implemented Warden and local reward

The Warden has 120 HP, a 22 px projectile hit radius, a 25 px contact radius and no knockback. It appears with a 1.5 s safe spawn warning in the upper center of the arena. It remains stationary and alternates radial rings and aimed fans, each with fixed warning lines. Phase one uses eight ring shots or three fan shots, a 1.1 s warning and 2.4 s cooldown. At half HP, the next announced attack enters phase two: twelve ring shots or five fan shots, a 0.8 s warning and 1.6 s cooldown. Projectiles deal 20 damage and travel at 130 px/s (156 in phase two). A phase change never changes an already announced pattern mid-warning.

The result includes the local victory count, “Crown broken” summary and saved global XP under [the shared progression contract](progression.md). Permanent combat upgrades still await skill-tree implementation. Finite outcomes save to `user://finite_records.json`, separately from endless records. Successful completion increments optional version-1 `wins`; defeats increment runs without wins. Old records without `wins` load with zero. The menu mode selector shows finite victories. The result is delivered once; no projectile or contact can damage a won run. Death already registered before the final-clear event takes precedence.

Boss art now uses a dedicated generated crowned-armor atlas with intact/broken-halo idle/cast poses. See docs/art/section6-spec.md and CREDITS.md for source and conditions. `tests/finite_run_smoke.gd` checks both attack phases, matching telegraph/projectile directions, complete automated runs with both weapons, three blessing choices, pause, victory persistence/deduplication, retry and death precedence. Menu tests check finite entry and return. `tools/capture_finite.gd` captures both phases and victory. These tests do not measure the 10–15-minute target or establish fair difficulty.


## Warden reinforcements (2026-11-04)

The user confirmed full runs with both weapons and requested additional enemies during the boss, with about ten at once. The cap is ten total, including the Warden and pending warnings. One escort spawns every 2.5 seconds after boss activation, cycling chaser, chaser, ranged, charger. At capacity, the next spawn waits for a slot without banking a burst. Existing perimeter placement, warning and player-distance safety apply. Pause and terminal states freeze spawning; retry resets it. Both boss phases use the same cadence. Warden defeat dismisses escorts and clears hostile fire before victory, so no cleanup wave is required.

WaveSettings exposes boss_max_enemies, boss_reinforcement_interval and boss_reinforcements. The reinforcement regression verifies delay, warnings, pause, mixed types, cap/refill, projectile boss defeat with surviving escorts, victory cleanup and retry. Follow-up human review of this new pacing is pending; the 10–15-minute target is still unmeasured.
