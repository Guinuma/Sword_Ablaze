# Global progression contract

Prototype decision, 2026-11-03. This document defines the next implementation; it does not claim that XP, the profile or the hub are already active in the game. Existing local records and loadout/preferences remain independent.

## Global XP and levels

Courtyard Run and Endless Arena use one shared reward calculation. On a terminal result, earn one XP per defeated enemy (maximum 100), plus ten XP per completed wave (maximum ten waves), plus 100 XP for a valid finite victory. Thus a defeat in either mode earns 0–200 XP; Courtyard victory earns up to 300 XP. Endless has no victory bonus because it has no victory condition. Enemy type and equipped weapon do not change XP. Elite/boss kills count once under the same kill rule.

A completed wave means its full budget has spawned and every active or pending enemy has been defeated. Clearing the boss completes wave ten. Reaching or starting a wave does not count as clearing it. Track completed waves explicitly in run state so intermissions, upgrade screens and terminal results cannot infer an incorrect reward from the displayed wave number.

Starting level is one. Every 100 global XP grants a level and one skill point, up to level twenty at 1,900 XP. XP is cumulative and never spent. Unspent points equal (level - 1) minus the validated cost of purchased nodes. Once capped, an outcome grants only the remaining XP needed to reach the cap; the result screen must show the actual applied amount, including zero. Node definitions and effects are separate skill-tree work.

Only victory and defeat settle a reward. Restarting, returning to the menu/hub during active play, closing the application or crashing abandons the run with no completion XP. There is no survival-time XP, idle-time reward, first-run gift or per-frame grant. Terminal XP is the same whether the player stays on the result screen, retries or returns. Balance these provisional amounts with human playtests; the caps prevent uncapped Endless growth from defining a different global economy.

## Separate temporary and permanent state

Global XP, levels, purchased skills and permanent unlock IDs belong to the profile. Current HP, wave budget, kills, elapsed combat time, healing drops, weapon cooldowns, offered blessings and blessing stacks belong to the live run. Temporary blessings are not XP and cannot be converted into permanent points. The starting weapon choice is a preference; both current weapons remain available without purchasing an unlock.

The HUD should label global XP as GLOBAL XP when it is introduced. Result summaries show the run reward and resulting global level. The hub shows cumulative XP and available skill points. No temporary XP/currency is introduced by this contract. Preferences stay in their existing safe file and are not reset by restarting a run.

## Profile version 1

The global profile will live at `user://profile.json`. Its initial schema is:

```json
{
  "version": 1,
  "xp": 0,
  "next_run_id": 1,
  "last_settled_run_id": 0,
  "active_run": {"id": 0, "mode": ""},
  "skills": [],
  "unlocks": []
}
```

`xp` is an integer in 0–1900. Sequence fields are nonnegative bounded integers, with next_run_id strictly greater than last_settled_run_id and any active ID. Active ID zero means no pending run; otherwise mode is `courtyard` or `endless`. Purchased skill and unlock IDs must be unique strings drawn from their eventual known definition sets. Do not store a duplicate level or point balance that can disagree with XP/purchases. Validation must include cross-field constraints and reasonable file/array/number limits.

Visual/audio/input/loadout preferences remain in `user://preferences.json`, independently versioned and loaded with the existing validator. This is the profile-to-preferences boundary, not a second copy of user settings. Local finite/endless records likewise remain separate files; failure to write a record must not cause a global reward to be delivered twice.

## Reward identity and safe commit

One local profile and one active run are supported for the first prototype. Allocate a monotonically increasing run ID and save it with the active mode before the run can earn XP. Starting another run supersedes an unfinished active ID as abandoned; do not resume an old scene snapshot. Allocation failure leaves combat playable with a visible “progression unavailable” state and no guessed/reused reward ID.

Settlement accepts only the active ID/mode, a valid terminal outcome and current run counters. It must reject an already settled ID, a mismatched mode, an old/unknown ID or an Endless victory. In one safe profile write, add capped XP, advance last_settled_run_id and clear the active run. Commit those fields together through a flushed temporary file, validated backup and rename. Marking a result paid separately from saving its XP is forbidden.

On write failure, preserve the pending reward identity and unchanged global XP so the same result can retry. After a successful settlement, repeated callbacks or a reloaded profile grant zero additional XP. The result screen should report a failed save and offer a way to retry it; it must not pretend an unsaved reward is permanent. Sequence numbers must never wrap or be reused when their limit is reached.

Load valid primary data, else valid backup, else a clearly reported initial profile. Do not promote partial `.tmp` data automatically. Do not overwrite an unknown future version. First version has no prior global-profile schema to migrate; future migrations need explicit version steps and regression fixtures. Preferences and arena records are not legacy global profiles and must not be silently converted into XP.

Concurrent application instances editing one profile are outside this first implementation and must be documented; sequential scene changes/reloads must remain safe. A later concurrency feature needs locking or compare-and-swap, not an assumption that rename solves stale writers.

## Verification before game integration

- Verify shared formulas, kill/wave caps, level boundaries, XP cap and actual awarded amount.
- Verify initial profile creation, strict validation, incomplete/corrupt primary recovery, valid backup preservation, malformed/mismatched fields and future-version write refusal.
- Verify run allocation, abandonment, mode mismatch, duplicate settlement before/after reload and failed writes followed by retry.
- Verify complete finite victory/defeat and Endless defeat apply the same base rules, with explicit completed-wave counters and one terminal receipt.
- Keep skill purchases, hub integration, interrupted-write simulation, migration support and full hub → combat → result → reward → hub tests as separate open work until implemented.
