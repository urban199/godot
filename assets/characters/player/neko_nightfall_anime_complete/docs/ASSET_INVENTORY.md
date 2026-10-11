# Asset Inventory

- `models/neko_nightfall_rigged.glb`: glTF binary model.
- Embedded animation clips: `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, `Reload`, `Hit`, `Death`.
- The original six clips are in the source GLB. `Hit` and `Death` are additional distinct skeleton keyframe animations generated reproducibly by `tools/characters/extend_neko_animations.js`.
- Skeleton nodes detected: Root, Hips, Spine, Chest, Neck, Head, UpperArm_L, LowerArm_L, Hand_L, UpperArm_R, LowerArm_R, Hand_R, UpperLeg_L, LowerLeg_L, Foot_L, UpperLeg_R, LowerLeg_R, Foot_R.
- `textures/neko_character_atlas.png`: character atlas.
- `textures/neko_face_details.png`: face detail texture.
- `reference/NEKO_NIGHTFALL_APPROVED_ANIME_REFERENCE.png`: concept/reference sheet only, not runtime geometry.

This inventory describes file contents; it is not a substitute for a Godot runtime test.
