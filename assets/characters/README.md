# Character asset layout

`player/anime-model.glb` is the sole player-character model and source asset. It contains 93 authored mesh parts for the face, hair, body, and clothing, with vertex colors (not a packed texture). GitHub Actions imports this GLB in Blender, adds UVs where missing, a humanoid armature, vertex groups/weights, and distinct animation actions, validates the result with Godot 4.5.1, then commits the generated GLB back to the same path.

The runtime player scene, controller, camera, weapon, enemies, and input mapping remain unchanged. The generated model is expected to provide a `Skeleton3D`, skinned mesh, and `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, `Reload`, `Hit`, and `Death` clips. Until Actions succeeds, the source is static; it is displayed without claiming animation support.

The other character directories were historical package copies/prototypes and are being retired in favor of this single-source layout. See `player/docs/CHARACTER_ASSET_PLAN.md` for the migration and validation plan.
