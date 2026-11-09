# Gabriel's prototype skill trees

Gabriel opens the Stained Glass tree in the Sanctuary. Four patron rosettes form a single map. Select a node to inspect its cost, prerequisite, bonuses and any weapon unlock. Gold paths show learned nodes. Michael, Gabriel and Raphael start from the central sigil, while Joana d’Arc branches from Michael’s Ember Edge.

| Patron / identity | Node | Cost | Requires | Permanent effect |
| --- | --- | --- | --- | --- |
| Michael / Sword Ablaze, main path | Ember Edge | 1 | None | +1 melee damage and Seraph Halberd |
| Michael / Sword Ablaze, main path | Flame Reach | 2 | Ember Edge | +6 logical pixels melee reach and Judgment Lance |
| Gabriel / precision | Clear Sight | 1 | None | +10% projectile speed |
| Gabriel / precision | True Aim | 2 | Clear Sight | +5 percentage points critical chance, shots and melee |
| Raphael / restoration | Living Light | 1 | None | +10 maximum and starting HP |
| Raphael / restoration | Renewed Step | 2 | Living Light | -10% base dash recharge |
| Joana d’Arc / resolve | Rallying Standard | 1 | Ember Edge | +5% move speed |
| Joana d’Arc / resolve | Unbroken Stand | 2 | Rallying Standard | +30 melee knockback |

## Fire and Impact

| Node | Cost | Requires | Effect |
| --- | --- | --- | --- |
| Living Ember | 1 | Ember Edge | Two Sword Ablaze hits ignite an enemy for three damage ticks, 0.65 seconds apart. |
| Pyre | 1 | Living Ember | Burning enemies spread two ticks of fire on defeat to nearby enemies within 40 px and line of sight. |
| Guard Break | 1 | Rallying Standard | Melee hits with at least 3 base damage after skills build Impact. Three Impact staggers regular enemies for 0.55 seconds. Bosses require five and stagger for 0.18 seconds. |
| Countercharge | 1 | Guard Break | The first eligible hit within 0.65 seconds of dashing adds two Impact instead of one. |
| Holy Furnace | 3 | Pyre and Countercharge | Staggering a burning enemy immediately applies its remaining burn damage. |

Fire and Impact are shown above enemies. Stagger pauses enemy movement and attack logic and disables contact damage while active.

## Light and Vitality

| Node | Cost | Requires | Effect |
| --- | --- | --- | --- |
| Luminous Seal | 1 | True Aim | Three consecutive projectile hits on the same target apply a Light mark for 3 seconds. Hitting another target resets the streak. |
| Verdict | 1 | Luminous Seal | The next melee hit consumes the mark for 3 extra damage. |
| Grace | 1 | Renewed Step | A healing pickup collected at full health grants a shield that absorbs 12 damage and lasts 4 seconds. While shielded, full-health pickups stay on the ground. |
| Shelter | 1 | Grace | Melee and ranged attacks apply 30% more knockback while the shield holds. |

A gold diamond indicates a marked enemy. A teal ring indicates an active shield. Marks and shields use active combat time and clear when a run restarts.

Maximum account level is 60% of the total node cost, rounded down, with a minimum of level 1. The current tree costs 23 points, so the account caps at level 13 (1,200 XP) with 12 points to spend. Level 1 grants no point. Existing saves keep earned XP and learned nodes, but can only spend points within the current cap. Free respec restores the current point budget. XP is cumulative and never spent. Available points are derived from level minus validated purchased costs, never stored separately. The inspector displays learned, learnable, locked or insufficient-points state. Nodes stay inspectable even when purchasing is disabled.

RESET SKILLS (FREE), available through Gabriel, clears the learned nodes and returns their derived point cost without changing XP, records, preferences or run identity. This is a reversible prototype choice for testing builds. The roster, costs, effects, cap and free reset can be revised after playtesting; this is not the final tree.

Profile version 1 already reserved skills/unlocks arrays. Existing empty-skill saves remain valid; skills now accepts only the known unique IDs, with required parents and an affordable total. Weapon access is derived from learned nodes, so the reserved unlocks array needs no separate weapon entries. Purchase/reset re-read the profile, validate the candidate, and use its existing flushed temporary write, validated backup and rename path. Failed writes do not spend points or pretend a node was saved. Future-version protection remains in force. Concurrent running app instances remain unsupported.

Learned effects are applied from base Resources when an arena starts or retries. Temporary blessings compose on those permanent bases. Shared melee settings drive both swing timing and hit simulation. Recalculations never repeatedly add knowledge bonuses; retries remove temporary blessings while preserving knowledge. Free reset is available in the Sanctuary and affects subsequent runs. The full learned-tree limits are +1 melee damage, +6 reach, +10% shot speed, +5% critical chance, +10 HP, -10% base dash recharge, +5% move speed and +30 melee knockback, before ordinary bounded blessings.

Verification: tests/skills_smoke.gd covers costs, prerequisites, duplicate and unknown IDs, forged/overspent profiles, failed purchase/reset writes and retries, reload, free refunds, live melee damage/reach, permanent stats, temporary blessing composition and retry separation. Existing profile tests cover backup/future-version protection; Sanctuary tests cover mentor navigation. tools/capture_skills.gd captures the current tree. The screenshots under docs/art/priority3 show the earlier prototype. Human balance feedback remains pending.
