# Prototype weapon loadouts

Main menu → Weapon Loadout offers two starting weapons. Both are available immediately; no global progression is required. The selected `blade` or `scatter` ID is saved as an optional version-1 preferences field. Missing/invalid IDs select Blade Rifle. Choice takes effect on arena entry, remains through restarts and is preserved when visual/audio/input preferences are saved. Temporary upgrades reset each run and recalculate from the selected weapon Resource.

| Weapon | Shot interval | Damage per projectile | Projectile speed | Knockback per hit | Pattern |
| --- | --- | --- | --- | --- | --- |
| Blade Rifle | 0.16 s | 1 | 360 px/s | 135 px/s | One accurate shot |
| Ember Fan | 0.55 s | 1 | 300 px/s | 85 px/s | Five projectiles equally spaced over 0.5 radians |

The fan trades long-range precision and repeat-fire frequency for close-range coverage and burst damage. A centered small target 40 px from the player receives all five pellets; at 200 px only the center pellet connects. The rifle hits once at either distance and fires over three times as often. Those geometry differences are verified through real projectile collision in `tests/weapon_smoke.gd`, rather than a stat comparison alone. They establish a mechanical alternative, not final balance: damage upgrades apply per pellet and need combination playtesting.

One trigger creates one volley and consumes one fire cooldown. Existing projectile caps, lifetime, nearest-target collision, guardian armor, dash input and release-after-menu rules still apply. If the projectile cap is reached during a volley, remaining pellets are dropped. Audio throttling produces one shot cue for simultaneous pellet events. All pellets share the same muzzle origin and fan around the current aim. The current gun sprite is shared placeholder presentation; a dedicated Ember Fan visual/icon remains future art work.

Weapon regression checks cover close/distant hit patterns, selected Resource application to player and projectiles, loadout persistence and upgrade/reset behavior. Menu tests cover equipping/saving, and navigation tests include the loadout screen. `tools/capture_loadout.gd` captures its presentation.
