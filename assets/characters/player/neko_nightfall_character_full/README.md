# Neko Nightfall Character Package

An integrated character asset package for the main Neko Nightfall Godot project. It contains a skinned humanoid glTF model, six animation clips, starter textures, a concept reference, and the original implementation plan. The root game's existing player controller, camera, combat, and touch controls remain authoritative; `scripts/humanoid_visual.gd` loads the character model from this folder.

Open the repository's root `project.godot` in Godot 4.5.1 or newer. The included demo controller and scene are retained as reference and do not replace gameplay code.

## Included

- `models/neko_nightfall_rigged.glb`: skinned glTF model with 18 joints and `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, and `Reload` clips.
- `textures/neko_character_atlas.png`: starter palette/fabric atlas embedded/referenced by the GLB.
- `textures/neko_face_details.png`: face-detail reference texture; not mapped by the model.
- `docs/IMPLEMENTATION_PLAN.md`: original integration and extension plan.
- `docs/INTEGRATION_STATUS.md`: current connections and static-validation limits.
- `reference/character_concept_reference.png`: visual direction only, not a 3D asset.

## Status and limitations

This is a rigged prototype, not a production-quality character. The mesh uses rigid per-primitive bone weights, so joints may show seams or stiff deformation in extreme poses. The atlas is a starter palette/fabric texture, not a detailed 4K PBR set. Facial expressions, polished fingers, professional mocap, and advanced cloth/hair simulation are not included.

The GLB is byte-identical to the previously integrated UV-fixed model (SHA-256 `47B3E8E07AB7F5123BF602D33C17859506C5E531332925A464496E649B120DB0`). Moving the package does not alter its geometry. Static wiring has been checked, but Godot import and runtime visibility have not been executed here; visual success is not claimed.
