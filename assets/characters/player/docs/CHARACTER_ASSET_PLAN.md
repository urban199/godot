# Neko character asset consolidation and rigging plan

## Target layout

```text
assets/characters/
  README.md
  enemies/                 # future enemy source assets
  props/                   # future shared character props
  player/
    anime-model.glb        # only player model; Actions upgrades this file in place
    docs/
      CHARACTER_ASSET_PLAN.md
```

## Migration executed in this change

1. Make `assets/characters/player/anime-model.glb` the only runtime model path.
2. Preserve its authored mesh pieces, face, hair, clothing, and vertex colors; do not replace them with procedural primitives. The source has no texture image or UV channel, so the generator adds UVs without discarding the vertex colors.
3. Replace the old Blender primitive generator with a Blender pipeline that imports this GLB, builds a humanoid armature, assigns vertex groups/weights to the existing mesh pieces, and authors separate locomotion/combat actions.
4. On push or manual dispatch, run Blender, stage the rigged GLB at the same asset path, import and validate with Godot 4.5.1, and commit only after validation passes.
5. Retire the old character package folders after confirming the root game has no runtime references to them. Keep the gameplay scripts/scenes and the single model source.

## Required generated-model checks

- A valid GLB with nonempty face/clothing mesh geometry and materials.
- A Godot `Skeleton3D` with at least 18 humanoid bones, including right hand.
- A skinned mesh with `Skin`, UV coordinates, and nonempty vertex weights.
- Distinct keyed clips: `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, `Reload`, `Hit`, `Death`.
- Main scene loads `anime-model.glb`, attaches the weapon to the right hand, and routes hit/death gameplay events to matching clips.
- Upload generated GLB and logs as Actions artifacts; commit the GLB only after all checks pass.

## Important limits

The current `anime-model.glb` is an authored static mesh with 93 named mesh parts and vertex colors, but its glTF metadata has no skeleton, skin weights, UVs, texture image, or animation clips. The Actions rigging script uses rigid per-part weights based on mesh names, so this creates an articulated, skinned character but does not provide polished deformation like a hand-authored rig. Face expression, cloth physics, facial animation, and deformation quality still require authored rigging and visual preview. Headless checks prove structure and wiring, not that the poses look natural.

The generated model is only considered ready after the workflow passes; inspect its artifact and the web/mobile preview before treating it as production-ready.
