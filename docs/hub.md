# Sanctuary hub

The title screen opens the Sanctuary. Its five actions provide arena selection, global progression, options, weapon loadout and return to the title screen. It displays the current global level, XP and available skill points, with clear profile-recovery/unavailable notices. Skill purchasing remains separate checklist work; points are earned from levels and are not spent yet.

Runs launched from the Sanctuary return there from pause or results. Retry stays in the selected mode and starts a fresh run. Successful result rewards are settled before return, and reopening progression only reads the profile; it never awards XP. Failed pending reward saves retain the result/retry flow. Abandoning active combat returns without completion XP.

`scenes/main/hub.tscn` shares the existing menu presentation, focus/navigation, audio and preferences code with a dedicated hub layout. Direct legacy/test arena entry can still return to the title route; the normal title → Sanctuary → mode flow returns to the Sanctuary. The hub is a menu-based prototype, not a walkable world.

`tests/hub_smoke.gd` drives title → hub → finite combat → victory → reward → hub, confirms the saved 300-XP reward and level four, then checks title re-entry and Endless abandonment without more XP. Tests use isolated profile/record paths. `tools/capture_hub.gd` captures the overview and progression page with an isolated 300-XP fixture. Human difficulty and hub-usability playtests remain pending.
