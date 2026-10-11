# Neko Nightfall — Rigged Character Prototype

## Import / run
1. Extract the ZIP.
2. Open `project.godot` in Godot 4.5 or newer.
3. Let Godot import `models/neko_nightfall_rigged.glb`.
4. Press F6/F5 to run `scenes/CharacterDemo.tscn`.

## Contents
- `models/neko_nightfall_rigged.glb`: glTF 2.0 model with a humanoid joint hierarchy, skin attributes (`JOINTS_0`, `WEIGHTS_0`), inverse bind matrices, and six animation clips: Idle, Walk, Run, Aim, Shoot, Reload.
- `textures/neko_character_atlas.png`: starter palette/fabric atlas.
- `textures/neko_face_details.png`: eye detail texture reference.
- `scripts/character_controller.gd`: movement, animation selection, camera toggle, demo lighting and HUD.
- `scenes/CharacterDemo.tscn`: integrated scene.

## Controls
WASD move; Shift run; Space jump; F toggle third/first person.
1 Idle; 2 Walk; 3 Run; 4 Aim; 5 Reload; 6 Shoot.

## Important limitations
This is an original stylized low-poly prototype, not a polished anime production model. The GLB uses a real glTF skin and bone weights, but each primitive's vertices are rigidly weighted to one joint (no smooth cross-joint deformation), so extreme poses can show seams. Facial expressions, detailed fingers, hair cards, physically modeled clothing folds, and professional motion-captured animation are not included. The PNGs are provided as starter/reference textures; the GLB currently uses per-material colors rather than a fully painted UV atlas. Godot import/runtime has not been executed in this environment, so validate the import and animation names in your installed Godot version before integrating into the game.
