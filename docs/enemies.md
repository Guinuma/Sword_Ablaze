# Enemy roster and prototype tuning

These values define the current Arena prototype, not final balance. Source of truth: `resources/default_enemy.tres`, `default_ranged.tres`, `default_charger.tres`, `default_guardian.tres` and defaults in `scripts/data/enemy_settings.gd`. Speeds use logical pixels per second. At wave n, approach speed is min(base + (n - 1) × growth, cap).

| Enemy | HP | Speed base / growth / cap | First wave | Role and player response |
| --- | --- | --- | --- | --- |
| Corrupted wisp / chaser | 2 | 46 / 3 / 90 | 1 | Continuous pursuit pressure; keep moving and clear a path before getting surrounded. |
| Fractured sentinel / ranged | 2 | 36 / 1 / 60 | 3 | Break predictable kiting with aimed shots; move across the fixed warning line or dash through the shot. |
| Armored ram / charger | 4 | 32 / 1 / 48 | 5 | Interrupt straight-line retreat; sidestep its locked lane, then attack during recovery. |
| Stone guardian | 8 | 25 / 0.5 / 38 | 7 | Durable space pressure; circle its slow-turning shield and shoot the exposed sides/rear. |
| Crowned sentinel / elite | 10 | 30 / 0.5 / 45 | 9 | Radial area pressure; move into the gaps between eight fixed warning spokes before the volley. |

## Attacks and defensive properties

- Every active enemy deals 15 contact damage through the shared player damage gate. A successful hit gives 0.85 s of protection. Dash blocks contact and hostile shots, including its final movement step.
- The sentinel approaches beyond 165 px and retreats inside 135 px, maintaining a 150 px preferred range. It starts an attack inside 230 px after a 1.8 s cooldown, locks aim for a 0.65 s warning, then fires at 130 px/s for 50 damage. It stands still during the warning.
- The ram approaches until an attack is ready within 190 px. It locks its direction for 0.85 s, charges at 300 px/s for up to 0.45 s (135 px), then stands still for 0.8 s. A wall ends the rush early. The next approach uses a 1.4 s cooldown. Knockback can still displace it during otherwise stationary stages.
- The guardian turns its shield at no more than 1.1 rad/s. Front means a 120-degree arc facing the incoming shot. Front damage is ceil(base damage / 2), minimum one; all other angles take double damage. It receives 20% of normal knockback. Other enemies receive full knockback.
- Wisp, sentinel and ram use a 10 px shot-hit radius, 15 px contact radius, 18 px separation distance and 8 px wall margin. Guardian uses 13 / 18 / 28 / 14 px respectively. Presentation silhouettes do not define collision.

The crowned sentinel uses the ranged spacing behavior, but announces eight radial directions for 1.05 s before firing eight 20-damage shots at 110 px/s. Its cooldown is 3 s and its knockback is 50% of normal. A crown and gold ground halo distinguish it from the regular sentinel; dedicated idle/walk/cast art is integrated. It shares the normal hit/contact radii and rewards.

## Introduction and encounter budget

One enemy consumes one spawn from the wave budget, including stronger types. Pending spawn warnings count toward the simultaneous limit of 18. Each warning lasts at least 0.7 s; activation waits while the player is within 56 px. Pending enemies cannot move, deal contact damage or receive player shots.

The first nine waves use authored [encounter recipes](encounters.md); the last three recipes repeat afterward. Opening introductions preserve one sentinel per three spawns in wave three, one ram per five in wave five, and one guardian per seven in wave seven. Later compositions vary by recipe. Siege has one elite opener replacing its first pattern entry, so it adds no extra spawn budget. Human difficulty/composition playtests remain separate checklist work.

## Rewards

Every defeated enemy currently gives exactly one run kill and the same exclusive healing-drop roll: 1% wings (+100 HP), 15% feather (+10 HP), 84% no drop. Tougher types do not grant extra kills or increased drop chances. Drops are optional recovery, not guaranteed compensation for a dangerous enemy. The shared drop system caps the field at 64 items; items expire after 30 simulation seconds. Full health preserves a pickup until useful or expired.

Kills and cleared waves contribute to the saved end-of-run global XP reward under docs/progression.md; XP is not awarded separately per enemy. Temporary upgrades still come from clearing each third wave. Warden victory is recorded and settled once. There is no per-kill currency or permanent-item drop.

## Validation and art status

Combat regressions cover shared damage/protection, spawn safety, separation, ranged attacks, kill/drop behavior and reset. Charger and guardian regressions cover their specialized behavior and introduction cadence. These are logic checks; they do not establish difficulty balance.

Wisp and sentinel retain their integrated sprites. Ram, guardian, elite and Warden use dedicated transparent four-pose atlases; see docs/art/section6-spec.md for concepts, scale and state selection. Crowded scene captures and 512 facing/state/reduced-effects renders were reviewed. Pillars and ruins now block movement/shots; enemies use radius-aware visibility-graph waypoints, and ranged enemies seek unobstructed aim.

The Warden has 120 HP and a 22px hit/25px contact radius; phase behavior and capped escorts are described in run-design.md.
