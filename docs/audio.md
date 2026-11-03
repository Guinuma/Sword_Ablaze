# Audio foundation

`default_bus_layout.tres` defines Master and three child buses: Music, SFX and UI. Route music players to Music, combat effects to SFX and menu sounds to UI. All three feed Master. Original synthesized prototype effects are generated as short 22,050 Hz mono PCM streams by `scripts/audio/sound_effects.gd`; no external recordings are used. The synthesis source is distributed under the repository MIT license. Music playback and transitions remain pending.

Main menu → Options → Audio Volumes provides four independent sliders (0–100%, steps of 5). Mouse and left/right keyboard navigation are supported. Zero mutes the bus; raising the value unmutes it. Values map to linear gain before conversion to decibels. Master changes do not overwrite the category values.

Volumes are optional fields in the existing version-1 preferences file, sharing its safe write and backup behavior. Old files default to 100%; malformed values default to 100%, numeric values clamp to 0–1. Preferences apply when entering both menu and arena, and visual preference writes preserve audio values.

Verification includes routing, independent gain, mute/unmute, persistence and limits in `tests/menu_smoke.gd`. Screenshot: `godot --path . --script tools/capture_audio.gd -- <absolute-png-path>`.

Combat connects actual shots, successful dashes, projectile impacts, eliminations, accepted damage, wave clears and chosen upgrades. Menu and arena buttons play a UI cue. Eight fixed voices reserve two for UI and six for combat; extra cues are dropped, identical cues are throttled to one per 45 ms, and each voice uses -18 dB gain. Pausing and restarting stop combat tails. Scene changes release their voices. Effects need listening and mix review on real speakers/headphones.

`tests/audio_smoke.gd` verifies PCM generation, routing, throttling, pool saturation, reserved UI capacity and stopping combat audio.

Next audio work: refine synthesized timbres through playtesting, select or produce licensed music, and add music start/fade/loop transitions. A soundtrack system beta can use a small set of placeholder tracks while original composition proceeds separately.
