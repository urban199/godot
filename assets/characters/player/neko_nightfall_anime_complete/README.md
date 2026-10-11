# Neko Nightfall Anime Character Package

This package is integrated into the main Neko Nightfall project. The runtime survivor model is loaded by `scripts/humanoid_visual.gd`; the root project's existing player, weapon, camera, enemy, and touch-control systems remain in use. Open the repository root `project.godot` for the actual game. The included demo scene/controller and nested project file are retained as source-package references, not as replacements for gameplay.

## Contents

- `models/neko_nightfall_rigged.glb`: skinned humanoid GLB with 18 joints and eight distinct clips: `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, `Reload`, `Hit`, `Death`.
- `tools/characters/extend_neko_animations.js`: deterministic GLB generator that refines triangle density while preserving UVs/skinning, then adds two authored reaction clips; the original six clips are preserved.
- `textures/neko_character_atlas.png`: starter atlas referenced/embedded by the model.
- `textures/neko_face_details.png`: reference texture, not mapped by the model.
- `reference/NEKO_NIGHTFALL_APPROVED_ANIME_REFERENCE.png`: concept sheet only; it is not the runtime mesh or a source for the GLB geometry.
- `docs/ASSET_INVENTORY.md` and `docs/IMPLEMENTATION_PLAN.md`: source inventory and original integration plan.
- `docs/INTEGRATION_STATUS.md`: actual wiring and static-check limits for this repository.

## Honest status

The active GLB now has 10,848 mesh vertices and 57,072 triangle indices (42 primitives), expanded deterministically from the source's 3,067 vertices and 14,268 indices. Midpoints interpolate UVs, normals, and the four strongest skinning influences; the 18-bone skeleton, nine materials, embedded atlas, and all six source animations are retained, with distinct `Hit` and `Death` clips appended. This improves geometric density and smooth shading without a large texture or runtime cost, but it does not invent new anatomy, hair strands, clothing layers, or silhouette detail—the underlying design still comes from the original model and needs a proper high-detail source model for a genuinely Genshin-like result. The concept sheet is not runtime geometry. Rigid source weights may still cause seams or stiff deformation. The GitHub workflow can import and validate the GLB and game scene, but it has not been run for this change; visual quality still needs human review.
