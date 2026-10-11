# Character Integration Status

## Connected to the main game

- This is the unchanged six-animation baseline source. Runtime loads the derived model at `../neko_nightfall_anime_complete/models/neko_nightfall_rigged.glb`.
- The output receives the two additional distinct reaction clips from `tools/characters/extend_neko_animations.js` before Godot import.
- Main gameplay wiring and CI validation details are documented in `../neko_nightfall_anime_complete/docs/INTEGRATION_STATUS.md`.

## Static findings and limits

- The model is a skinned glTF with UVs and six clips. Its GLB binary is identical to the previously integrated UV-fixed package; this move is a path/package cleanup, not a new model revision.
- `textures/neko_character_atlas.png` is the starter atlas. `textures/neko_face_details.png` is reference material and is not mapped by the GLB.
- The original notes describe rigid per-primitive bone weights; seams or stiff deformation may appear in extreme poses.
- The source GLB's UVs, skin attributes, embedded atlas, skeleton, and six original animation channels are preserved; the Node generator checks and appends binary glTF key data without replacing existing animation clips.
