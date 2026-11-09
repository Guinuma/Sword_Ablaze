# Arena and enemy visual specification

Implemented 2026-11-04 for the 640 × 360 logical viewport with integer scaling and nearest texture sampling.

## Grid, perspective and light

The illustrated courtyard remains the outer arena and abyss background. Four reusable floor variations use 32 × 32 logical-pixel cells in a 128 × 32 atlas. They are blended at 25% over the existing floor near repaired masonry to avoid high-contrast checkerboards. Their outer pixel profiles match; cracks and ten sparse flecks stay inside each cell. The 32 × 8 wall-trim segment repeats along all four bounds, rotates at corners and clips its final segment to the exact remaining width, with no uncovered corner/gap. The existing ornate outer columns, abyss and gold motifs remain visible.

Props use a slightly elevated three-quarter camera, ivory marble highlights from upper left, muted gold bands, and dark crevices. World silhouettes are grounded and Y-sorted by the footprint center. The tops of columns can occlude actors passing behind them; the lower plinths are solid. Hitboxes follow the lower footprint, not the full height of the picture.

Color budget: icons and native tile accents use the twelve-swatch project reference palette. The refined player follows its ivory/teal/dark-cloth/gold material families; its generated sheets are not falsely claimed to contain exactly twelve indexed colors. Native floor/edge tiles use twelve or fewer low-saturation slate/stone/gold swatches. Generated enemy/prop atlases are not falsely described as indexed-color files: their budget is five material families (ivory stone, old gold, dark violet, burgundy cloth, corruption pink), with ivory/gold reserved for readable silhouettes and pink for small cores/cracks. Broad glow/bloom is avoided. Gold square player shots, magenta diamond hostile shots, turquoise dash/healing accents and neutral masonry retain distinct shape as well as color cues.

## Solid layout and navigation

ArenaGeometry defines two pillar footprints (24 × 18) and two broken-wall footprints (40 × 14): Rect2(138,132,24,18), Rect2(476,248,24,18), Rect2(124,260,40,14), Rect2(476,132,40,14). Their art anchors at the footprint center, with its base on the footprint bottom. Props use all four poses of courtyard-props-02.png at approximately 26 px pillar width and 42 px wall width. Art trim can overhang the solid footprint by one pixel. Actor collision expands these rectangles by each actor's existing radius/margin. The initial player point and Warden spawn are unobstructed.

Movement sweeps against expanded rectangles, then slides along blocked faces; a dash cannot tunnel across a prop. A cached visibility graph of expanded prop corners supplies enemy waypoints. Ranged enemies seek line of sight when cover blocks their preferred-range stance; charging enemies route first and only lock a charge when the lane is clear. Knockback and separation keep actors out of props. Player/hostile projectiles use nearest world-versus-target segment hits, muzzle paths cannot start shots through cover, melee requires an unobstructed segment, and pickups cannot be collected through cover. No Godot physics-body masks are silently mixed into the mathematical collision system.

## Enemy silhouettes and state mapping

- Ruin Ram / charger: horned, low quadruped aberration; stalking, compressed warning, extended charge, exhausted recovery. Atlas frames 0–3 follow the simulation phase. Existing amber lane, trail and recovery cue remain. Its four limbs and broken cathedral skull develop the aberration concept without adding another gameplay archetype.
- Bastion Guardian: wide plate armor, large kite shield, visible rear corruption crack. Front/right/rear/left poses select by simulation facing. The exact rotating 120-degree armor arc stays visible at ground level; the artwork does not decide damage reduction.
- Crowned Sentinel: distinct three-point crown and short burgundy mantle; idle, two opposing walking steps, raised-arm cast. Its eight warning spokes and gold ground ring remain the behavioral cues.
- Warden: regal crown, large halo, layered ivory plate and burgundy vestments; idle/cast in both phases. Phase two uses a shattered halo and brighter armor cracks, not just a recolor. All warning directions still come from EnemySystem.boss_directions. Escort cap/cadence and combat values are unchanged.

Enemy sheets are 2 × 2 transparent atlases; individual AtlasTexture regions were measured from alpha bounds. Shared per-sheet scaling preserves relative pose size and grounds all frames at y=8. Runtime heights: ram up to 28 px (40 px width cap), guardian 42, elite 44, Warden 65. Existing wisp and sentinel stay at their prior scale. The Exile's revision-3 generated front/back/side sheets each have nine idle/walk/dash/hurt poses, plus a four-pose defeat sheet. They render nearest at 32px standing height; pointed cloth cowl, dark recessed mask, trailing cloth and asymmetric ivory tabard replace the helmet-like square head without changing combat pivots. The earlier native SVG is an inactive reference.

## Icons, verification and provenance

16 × 16 SVG icons cover the four playable Michael weapons, global XP, healing feather, healing wings, dash and melee. They appear in loadout, progression, HUD or world pickups; temporary blessing badges retain their existing symbols, ranks and effect tooltips. No unimplemented currencies or skills are presented as usable systems.

Review captures: section6-arena.png and section6-warden-phase2.png. tools/capture_section6.gd also creates a collision-overlay review. tools/validate_section6_visuals.gd rendered 512 type/facing/state/reduced-effect combinations; the player sweep rendered 1,024 combinations. Obstacle regressions cover five physics rates, dash tunneling, navigation, line of sight, cover priority, melee and fast projectiles. Full finite/endless, pause, reward and long-session checks remain required. The rendered section-6 performance sample is recorded under docs/performance.

Prompts and hashes: asset-provenance-01.json and *-02-prompt.txt. Consolidated source/rights conditions: ../../CREDITS.md. The generated PNGs were made with the built-in image tool and retain their original alpha; no Python image-editing pipeline was used.
