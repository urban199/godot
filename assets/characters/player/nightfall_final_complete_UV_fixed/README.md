# Neko Nightfall UV-Fixed Character

This asset is integrated into the main game project. The player visual is loaded from `models/neko_nightfall_rigged.glb` by `scripts/humanoid_visual.gd`; use the project's root `project.godot` to run the game.

The GLB contains a humanoid skin, UV coordinates, an embedded base-color atlas, and the `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, and `Reload` animation clips. `textures/neko_character_atlas.png` is the source atlas. `textures/neko_face_details.png` remains a reference image and is not mapped by the model.

This is a low-poly prototype. Its vertices are rigidly weighted to joints, so extreme poses may show seams. Godot import and runtime playback have not been tested; integration has only been checked statically.
