# First finite run: prototype decisions

Decision date: 2026-11-03. This defines the implementation target for the first complete run. It does not claim that finite mode, the boss, victory, hub or permanent rewards are already implemented. The currently playable Arena remains endless until the finite flow is complete and selectable.

## Structure and duration

The finite run uses the existing nine encounter recipes in order, followed by a single boss encounter on wave ten. Wave ten has one boss, no ordinary enemy budget and no extra spawns after the boss dies. The existing elite opens wave nine. This reuses the validated introductions and gives the boss a clear final encounter instead of adding an arbitrary timer ending.

Target duration is 10–15 minutes for a successful early playtest, including upgrade selection and the boss. This is a tuning target, not a timeout, minimum duration or measured result. Faster wins are valid. A run never ends merely because time passes. Current automated timings and spawn budgets do not prove this duration; tune it through human runs after the complete flow exists.

The player selects Blade Rifle or Ember Fan before entering. Movement, aim, dash and damage protection remain the same. Temporary blessings are offered after clearing waves 3, 6 and 9, before the next intermission completes. Clearing wave nine therefore always offers the last eligible blessing before the boss. Exhausting all eligible upgrades skips the choice rather than blocking progression.

Ordinary waves retain the existing three-second intermission and up-to-20-HP recovery on clear. The run does not add shops, currency, rerolls, ammo or a time-pressure economy as a prerequisite for its first complete version. Broader economy decisions remain separate checklist work.

## Terminal outcomes

Victory requires the final boss to be defeated while the player is alive and the run is in active combat. All enemies and pending spawns for that encounter must be resolved, and no hostile projectile may remain able to damage the player after victory. Victory is a dedicated terminal state: stop simulation, clear combat projectiles, show a clear result heading and summary, and allow Retry or Return. It must not reuse the defeat animation or record a victory as a death.

Defeat occurs at zero HP, including the boss encounter. Keep the existing fall animation and defeat summary. Contact and projectile damage share the existing gate. If player death has already transitioned the run to defeat, a later same-step boss-death callback must not overwrite it with victory. A terminal outcome may be recorded or rewarded only once.

Retry starts wave one with the selected loadout, full base HP and no temporary upgrades, enemies, projectiles, drops or feedback left from the previous run. It requires a fresh firing trigger. Leaving a live run abandons it; it does not award a victory or defeat completion reward.

The result screen returns to the main menu while a hub is absent. Once the minimal hub exists, the same Return action leads there. No fake hub or permanent-reward claim is needed to finish the combat prototype; the full hub/reward loop stays unchecked until it is actually implemented and tested.

## Endless variant

Keep Endless Arena as an explicit separate selection. It continues cycling recipes 7–9 after wave nine, with the existing budget, simultaneous-enemy and spawn-rate caps. It has no finite boss win condition. Its defeats retain their survival-oriented wave/kill/time records. Finite results must be labeled separately so a ten-wave completion is not confused with an endless survival record.

During implementation, the existing Play Arena route continues to work. Make the finite route selectable only once entry, boss, terminal result, retry and return are all functional. The 20-minute soak must continue exercising Endless Arena; add separate finite-run coverage rather than silently truncating the existing stress test.

## Implementation and acceptance gates

1. Add a mode-aware run/director configuration with nine ordinary encounters plus the boss finale; keep endless configuration explicit and test both.
2. Implement a boss with announced attacks, recognizable phase change and a clear reward/result event. Its art may initially be a documented placeholder; final art remains checklist work.
3. Add terminal victory state, result presentation, mode labeling, retry and return. Verify that terminal callbacks cannot deliver results twice.
4. Test clean victory, boss defeat of the player, pause/focus loss, upgrade-before-boss flow, reset from every terminal screen, and no post-result combat damage.
5. Define and implement permanent reward/profile rules before displaying or awarding XP. Local records alone are not progression.
6. Play complete runs with both weapons, record actual duration and difficulty, and tune toward the target. Keep playtest and final-balance items open until human evidence exists.

Global XP, skill trees, global reward amounts, boss permanent drops, save migration and export platforms are not decided by this document. Those contracts must be defined and validated in their own checklist work.
