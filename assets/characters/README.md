# Character assets

The active survivor is the imported, skinned GLB in `player/neko_nightfall_anime_complete/models/`; `scripts/humanoid_visual.gd` loads and animates it. Zombies retain the procedural visual in that script. The GLB has one textured material atlas, an 18-bone humanoid skeleton, and eight distinct clips (six authored in the source GLB plus reproducibly generated `Hit` and `Death` reactions). `tools/characters/extend_neko_animations.js` documents and regenerates those two added clips from the original model.
