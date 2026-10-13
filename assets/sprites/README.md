# Generated character atlases

These three 1536×1024 transparent PNG atlases were generated with the built-in OpenAI ImageGen tool for this project. Character designs are original prototypes, not licensed franchise characters.

Each atlas uses four columns and two rows of 384×512 cells. The frame order is:

| Cell | Pose |
|---|---|
| Row 1, columns 1–4 | Idle, run, jump, guard |
| Row 2, columns 1–4 | Light attack, heavy attack, energy skill, KO |

The game reads these regions as `AnimatedSprite2D` poses through `AtlasTexture`. `scripts/fighter.gd` maps movement/combat state to an animation; the two run poses and two attack poses provide short loops/chains. Recheck alpha edges and per-cell alignment if the atlases are replaced.
