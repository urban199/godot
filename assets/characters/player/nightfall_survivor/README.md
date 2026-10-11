# Neko Nightfall — Anime 3D A Pack

Included:
- `model/neko_nightfall_anime_survivor_A.glb`: stylized blonde-haired, red-eyed gothic anime survivor prototype.
- `materials/`: simple Godot StandardMaterial3D resources.
- `godot/CameraModeToggle.gd`: sample camera toggle script.
- `docs/LOW_END_SETTINGS.md`: optimization notes.

Import:
1. Extract this package.
2. Copy `model/` into `res://assets/characters/`.
3. Open the GLB in Godot 4.x and instance it into your scene.
4. Add a collision body and connect it to your existing player controller as needed.

Limitations:
This is a real static 3D mesh with separate low-poly parts and simple PBR materials. It is a stylized prototype, not a polished commercial anime model. It is NOT rigged: no Skeleton3D, skin weights, or animation clips are included. The camera script is an example, not an integrated controller. Not tested in the user's project or on target hardware.
