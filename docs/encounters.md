# Arena encounter recipes

`resources/default_wave.tres` references nine editable Resources in `resources/encounters/`. Each uses `scripts/data/encounter_definition.gd`: a title, ordered enemy pattern, optional one-off opener, budget multiplier and spawn-interval multiplier. Patterns repeat until the wave budget is consumed. This changes composition and pacing without changing enemy AI.

| Wave | Recipe | Pattern (C chaser, R ranged, A charger, G guardian) | Budget | Interval multiplier |
| --- | --- | --- | --- | --- |
| 1 | Pursuit | C | 5 | 1.0 |
| 2 | Pressure | C C | 7 | 1.0 |
| 3 | Crossfire | C C R | 9 | 1.0 |
| 4 | Breather | C R C C | 9 | 1.25 |
| 5 | Charge | C C R C A | 13 | 1.15 |
| 6 | Firing Line | R C R C A C | 14 | 1.2 |
| 7 | Bulwark | C C R C A R G | 17 | 1.15 |
| 8 | Pincer | A C R C R G | 19 | 1.1 |
| 9 | Siege | G C R A C R A C | 21 | 1.25 |

Siege replaces its first pattern entry with one crowned sentinel elite. The opener consumes an ordinary budget slot and does not recur when the rest of the pattern repeats.

From wave 10 onward, recipes 7–9 repeat. Base budget remains 5 + 2 × (wave - 1), multiplied by the recipe factor, rounded and clamped to 1–40. Spawn interval is (1.6 - 0.1 × (wave - 1)) × recipe factor, with a floor of 0.4 s. Longer intervals and reduced budgets provide deliberate relief around new introductions. The 18-enemy simultaneous cap, pending-spawn safety, three-second intermission, healing and upgrade cadence are unchanged.

The director selects the recipe from the wave number; no independent recipe cursor can get out of sync during reset. Resources with no encounter list retain the old generic ratios for custom/test configurations. An empty pattern also uses those ratios; an unknown enemy kind safely becomes a chaser. `repeat_from_wave` is clamped to the available range.

`tests/encounter_smoke.gd` verifies every spawn in the first twelve waves, exact budgets, cycle selection, advanced budget cap and the empty-list fallback. Combat and long-session regressions verify lifecycle behavior. These are authored prototype encounters; human balance playtests remain pending. No win condition, boss or permanent rewards are added by this system.
