# Audio foundation

`default_bus_layout.tres` defines Master and three child buses: Music, SFX and UI. Route music players to Music, combat effects to SFX and menu sounds to UI. All three feed Master. Original synthesized prototype effects are generated as short 22,050 Hz mono PCM streams by `scripts/audio/sound_effects.gd`; no external recordings are used. The synthesis source is distributed under the repository MIT license. Original music loops are now included; see below.

Main menu → Options → Audio Volumes provides four independent sliders (0–100%, steps of 5). Mouse and left/right keyboard navigation are supported. Zero mutes the bus; raising the value unmutes it. Values map to linear gain before conversion to decibels. Master changes do not overwrite the category values.

Volumes are optional fields in the existing version-1 preferences file, sharing its safe write and backup behavior. Old files default to 100%; malformed values default to 100%, numeric values clamp to 0–1. Preferences apply when entering both menu and arena, and visual preference writes preserve audio values.

Verification includes routing, independent gain, mute/unmute, persistence and limits in `tests/menu_smoke.gd`. Screenshot: `godot --path . --script tools/capture_audio.gd -- <absolute-png-path>`.

Combat connects actual shots, successful dashes, projectile impacts, eliminations, accepted damage, wave clears and chosen upgrades. Menu and arena buttons play a UI cue. Eight fixed voices reserve two for UI and six for combat; extra cues are dropped, identical cues are throttled to one per 45 ms, and each voice uses -18 dB gain. Pausing and restarting stop combat tails. Scene changes release their voices. Effects need listening and mix review on real speakers/headphones.

`tests/audio_smoke.gd` verifies PCM generation, routing, throttling, pool saturation, reserved UI capacity and stopping combat audio.

## Section 7 soundtrack and transitions

Two original eight-bar D-minor arrangements share a harmonic motif: Sanctuary (72 BPM, sustained chords and bell melody) and Courtyard (112 BPM, bass pulse and synthesized kick). `tools/build_music.py` rebuilds the mono 22,050 Hz, 16-bit WAVs using Python/NumPy. No recordings, samples, external composition or sound pack are used; source and generated audio use the repository MIT license. Note releases wrap around each loop; Godot imports with forward looping and uncompressed PCM.

`scripts/audio/music.gd` owns two Music-bus players at the SceneTree root. Title and Sanctuary select ambience; Arena selects combat. Transitions crossfade over 1.25 seconds, with fixed total gain bounded at 0.38; a new transition reverses an in-progress fade without adding voices. Same-track navigation preserves playback. Pause, upgrades, intermission and results smoothly duck music to 35%; resume/retry restore combat gain. Music continues during hit-stop. Music and Master sliders affect both tracks immediately. Exiting the last bound scene stops playback and releases streams.

## Impact accents and visual tuning

User decision, 2026-11-06: include subtle hit-stop and screen shake, each independently disabled in Options → Combat Feedback. Both default on; Reduce visual motion overrides both, including the existing in-arena pause toggle. Optional booleans retain version-1 save compatibility and malformed values use defaults.

Accepted nonfatal player damage and landed critical hits trigger a 35 ms simulation hold and a 140 ms decaying shake, at most 1.5 logical pixels per axis. A 180 ms real-time retrigger cooldown prevents dense critical streams extending the hold indefinitely. Timing consumes the exact hold remainder at 30/60/120/144/240 Hz. Only simulation delta is reduced: UI, audio and input release handling continue; Engine.time_scale stays unchanged. Shake offsets all world presentation layers together and compensates mouse aim; HUD stays fixed. Pause, upgrade, terminal state, restart and reduction changes clear accents. Damage protection and collision math retain their existing rules.

Particles now last 0.22 s and travel more slowly; muzzle flashes shrink to 3 px with 75% opacity. Enemy hit tints peak at 1.3 instead of 1.8. Spawn/dash/critical cues last 0.28/0.2/0.24 s; other rewards retain longer cues, with lower opacity and expansion. Projectiles draw above actors, beneath cues, modal dimming and HUD. Particle/cue/voice caps remain unchanged.

Verification: `tests/section7_smoke.gd` covers actual damage/critical accents, timing across five rates, disable/reduced-motion behavior, pause/reset, preference persistence, scene handoff, ducking, looping, routing and fade completion. Navigation checks cover the extra options screen. `tools/capture_section7.gd` reproduces dense/reduced combat and both options screens in docs/art. Speaker/headphone mix and subjective feel still need human playtesting.

Normal Quit and window-close requests stop soundtrack playback and allow a 0.1-second mixer retirement before quitting. The startup regression boots the actual entry scene for 120 frames and exits through this same path, keeping leak detection enabled. Forcing `--quit-after` bypasses graceful audio shutdown and can report pending looping playback at exit in Godot 4.5.1; use the startup script for clean automated validation.
