# Audio foundation

`default_bus_layout.tres` defines Master and three child buses: Music, SFX and UI. Route music players to Music, combat effects to SFX and menu sounds to UI. All three feed Master. No sound files, music playback or transition system are included yet.

Main menu → Options → Audio Volumes provides four independent sliders (0–100%, steps of 5). Mouse and left/right keyboard navigation are supported. Zero mutes the bus; raising the value unmutes it. Values map to linear gain before conversion to decibels. Master changes do not overwrite the category values.

Volumes are optional fields in the existing version-1 preferences file, sharing its safe write and backup behavior. Old files default to 100%; malformed values default to 100%, numeric values clamp to 0–1. Preferences apply when entering both menu and arena, and visual preference writes preserve audio values.

Verification includes routing, independent gain, mute/unmute, persistence and limits in `tests/menu_smoke.gd`. Screenshot: `godot --path . --script tools/capture_audio.gd -- <absolute-png-path>`.

Next audio work: select or produce licensed sounds/music, connect combat events, cap simultaneous voices, and add music start/fade/loop transitions. A soundtrack system beta can use a small set of placeholder tracks while original composition proceeds separately.
