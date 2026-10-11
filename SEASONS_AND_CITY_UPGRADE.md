# Neko Nightfall — Expanded City & Seasons

## What's included

- Expanded world footprint: approximately 720 x 540 world units.
- Additional generated building blocks beyond the original central encounter area.
- Extended road grid, sidewalks, plaza, industrial yard, park pad and distant street lamps.
- Four selectable environment seasons with lighting, ambient color, fog, ground tint and tree-canopy palette changes:
  - Spring: cool mist and light rain
  - Summer: warmer lighting and clear weather
  - Autumn: amber lighting and falling leaves
  - Winter: blue lighting, cold fog and snow
- Lightweight CPU particle weather that follows the player, designed to avoid requiring a high-end PC.
- HUD season status and keyboard controls.

## Controls

- `Q`: cycle Spring → Summer → Autumn → Winter
- `1`: Spring
- `2`: Summer
- `3`: Autumn
- `4`: Winter

Existing movement, shooting, reload, flashlight, zombies, pickups, exit and restart flow are retained.

## Performance notes

The city is generated from primitive meshes at runtime. This makes the map easy to modify and keeps asset size small, but it is not equivalent to a hand-authored open-world city with detailed interiors. For low-end hardware, keep shadows modest and avoid increasing the weather particle amount significantly.

## Validation

Godot 4.5.1 is the intended engine. The current environment used to prepare this archive did not have network access to download the Godot executable, so a real headless editor import/export run could not be performed here. Run the included GitHub Actions workflow after pushing the project to validate the actual Godot export.
