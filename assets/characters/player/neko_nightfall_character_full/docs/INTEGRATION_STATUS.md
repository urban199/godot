# Character Integration Status

## Connected to the main game

- `scripts/humanoid_visual.gd` loads `models/neko_nightfall_rigged.glb` from this package as the survivor visual.
- The root project's `CharacterBody3D`, movement, weapon, camera switching, enemies, and mobile controls remain authoritative; the package demo controller is not used by the main scene.
- The visual loader searches recursively for a mesh, skeleton, and animation player. It makes imported nodes visible and forces imported base materials to opaque. If the required mesh or skeleton is missing, it falls back to the procedural survivor.
- Animation lookup supports library-prefixed names for `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, and `Reload`.

## Static findings and limits

- The model is a skinned glTF with UVs and six clips. Its GLB binary is identical to the previously integrated UV-fixed package; this move is a path/package cleanup, not a new model revision.
- `textures/neko_character_atlas.png` is the starter atlas. `textures/neko_face_details.png` is reference material and is not mapped by the GLB.
- The original notes describe rigid per-primitive bone weights; seams or stiff deformation may appear in extreme poses.
- Static inspection cannot establish that Godot's importer/runtime renders the model correctly. Import and visually check the root project before claiming the transparency issue is resolved.
