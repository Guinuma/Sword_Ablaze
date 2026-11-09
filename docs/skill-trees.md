# Gabriel's prototype skill trees

Small functional version, 2026-11-06. Three branches, six one-time knowledge nodes. Gabriel teaches them in the Sanctuary; Michael and Sword Ablaze remain the principal path. Michael’s nodes unlock weapons from the [weapon catalogue](weapons.md).

| Patron / identity | Node | Cost | Requires | Permanent effect |
| --- | --- | --- | --- | --- |
| Michael / Sword Ablaze, main path | Ember Edge | 1 | None | +1 melee damage and Seraph Halberd |
| Michael / Sword Ablaze, main path | Flame Reach | 2 | Ember Edge | +6 logical pixels melee reach and Judgment Lance |
| Gabriel / precision | Clear Sight | 1 | None | +10% projectile speed |
| Gabriel / precision | True Aim | 2 | Clear Sight | +5 percentage points critical chance, shots and melee |
| Raphael / restoration | Living Light | 1 | None | +10 maximum and starting HP |
| Raphael / restoration | Renewed Step | 2 | Living Light | -10% base dash recharge |

The existing level-20 / 1,900-XP cap stays. Levels grant nineteen possible points; this prototype costs nine total and can be completed at level ten. XP is cumulative and never spent. Available points are derived from level minus validated purchased costs, never stored separately. Each branch is a parent-to-child chain. Nodes display learned, learnable, locked or insufficient-points state; costs and effects are visible, and prerequisite names appear in tooltips. Michael's available nodes use the main gold treatment.

RESET SKILLS (FREE), available through Gabriel, clears the learned nodes and returns their derived point cost without changing XP, records, preferences or run identity. This is a reversible prototype choice for testing builds. The roster, costs, effects, cap and free reset can be revised after playtesting; this is not the final tree.

Profile version 1 already reserved skills/unlocks arrays. Existing empty-skill saves remain valid; skills now accepts only the six known unique IDs, with required parents and an affordable total. Weapon access is derived from learned nodes, so the reserved unlocks array needs no separate weapon entries. Purchase/reset re-read the profile, validate the candidate, and use its existing flushed temporary write, validated backup and rename path. Failed writes do not spend points or pretend a node was saved. Future-version protection remains in force. Concurrent running app instances remain unsupported.

Learned effects are applied from base Resources when an arena starts or retries. Temporary blessings compose on those permanent bases. Shared melee settings drive both swing timing and hit simulation. Recalculations never repeatedly add knowledge bonuses; retries remove temporary blessings while preserving knowledge. Free reset is available in the Sanctuary and affects subsequent runs. The full learned-tree limits are +1 melee damage, +6 reach, +10% shot speed, +5% critical chance, +10 HP and -10% base dash recharge, before ordinary bounded blessings.

Verification: tests/skills_smoke.gd covers costs, prerequisites, duplicate and unknown IDs, forged/overspent profiles, failed purchase/reset writes and retries, reload, free refunds, live melee damage/reach, permanent stats, temporary blessing composition and retry separation. Existing profile tests cover backup/future-version protection; Sanctuary tests cover mentor navigation. tools/capture_skills.gd reproduces available/learned screenshots under docs/art/priority3. Human balance feedback remains pending.
