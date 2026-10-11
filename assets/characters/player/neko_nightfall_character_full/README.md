# Neko Nightfall Character Package

This package is the preserved baseline source for the active anime character asset in `../neko_nightfall_anime_complete/`. Its skinned humanoid GLB contains the original six clips; the active output adds original `Hit` and `Death` clips using `tools/characters/extend_neko_animations.js`.

Open the repository's root `project.godot` in Godot 4.5.1 or newer. The root game loads the generated output package, not this baseline folder. The included demo controller and scene are retained as reference and do not replace gameplay code.

## Included

- `models/neko_nightfall_rigged.glb`: skinned glTF model with 18 joints and `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, and `Reload` clips.
- `textures/neko_character_atlas.png`: starter palette/fabric atlas embedded/referenced by the GLB.
- `textures/neko_face_details.png`: face-detail reference texture; not mapped by the model.
- `docs/IMPLEMENTATION_PLAN.md`: original integration and extension plan.
- `docs/INTEGRATION_STATUS.md`: source package notes; current wiring is documented in the active output package.
- `reference/character_concept_reference.png`: visual direction only, not a 3D asset.

## Status and limitations

This is a rigged prototype, not a production-quality character. The mesh uses rigid per-primitive bone weights, so joints may show seams or stiff deformation in extreme poses. The atlas is a starter palette/fabric texture, not a detailed 4K PBR set. Facial expressions, polished fingers, professional mocap, and advanced cloth/hair simulation are not included.

The baseline GLB is retained unchanged as the deterministic input for adding keyed reaction animations. It has a low-poly mesh with rigid per-primitive bone weights; extreme poses may show seams or stiff deformation. The active output includes the same geometry and material atlas, plus two distinct reaction clips.
