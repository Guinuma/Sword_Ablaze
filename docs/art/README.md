# Art direction â€” The Exile

Selected protagonist: **The Exile** (concept C in art-direction-01.png).

## Visual identity

- Agile silhouette; short turquoise cape, ivory hood and pale mask.
- Dark fitted clothing and restrained tarnished-gold armor accents.
- Ember firearm with a blade silhouette; retain visual space for free aiming.
- No heavy armor or large wings on the protagonist.

## Gameplay targets

- Explore a 32 Ã— 32 logical-pixel character footprint against the current 640 Ã— 360 viewport.
- Keep the mask, cape and weapon recognizable at actual gameplay size.
- Separate the weapon from the body when producing usable sprites so it can follow the mouse.
- Start with idle and movement in four directions, then dash, damage and death.
- Use nearest filtering and consistent pivots; verify silhouettes on the arena floor.

## Reference status

The generated boards are concept references, not animation atlases or production-ready sprites. Their views and pixel scale require cleanup before integration. The arena now uses exile-body-01.png for the player, with a code-drawn responsive cape and independently aimed weapon. Enemies and arena retain geometric placeholders. The player currently uses one mirrored base pose with procedural bobbing, not directional frame animation. The generated body is a high-resolution concept-derived texture displayed at 36 logical pixels; a hand-cleaned low-resolution atlas remains future work.


## First playable visual

- Body asset: `assets/art/player/exile-body-01.png` (transparent PNG, generated with the built-in image tool).
- Visual implementation: `scripts/player/exile_visual.gd`.
- Actual engine capture: `docs/art/exile-gameplay-preview-01.png`.
- Generation prompt: `docs/art/exile-body-01-prompt.txt`.
- Body and feet are drawn above a soft shadow, with the cape behind the body and an independently rotated weapon. Pause/death overlays cover the player. Reset restores the initial cape pose.
