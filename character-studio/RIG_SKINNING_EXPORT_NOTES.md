# Neko Nightfall Character Studio — rig/skinning upgrade

This build improves the browser export pipeline:

- Mesh transforms are baked into one character-local coordinate space before skinning.
- A shared humanoid skeleton is created (hips, spine, chest, neck, head, arms, hands, legs, feet).
- Mesh vertices receive normalized four-influence skin weights, with head/arm/leg-aware weighting where mesh names make that possible.
- GLB export includes Idle, Walk, Run, Aim, Shoot, and Death animation clips using quaternion tracks.
- Geometry remains the existing stylized parametric base mesh; this is not a hand-sculpted AAA character or production motion-capture rig.

## Validation status

The JavaScript module passes `node --check`. The GLB exporter runs in the browser through Three.js from the CDN, so a full GLB round-trip/import test still needs to be done in a browser and Godot 4.5.1. Skin weights are heuristic and can cause distortion around skirts, hair, accessories, and joints. Inspect all six clips before using the asset in gameplay.

## Godot import checklist

1. Export `neko-rigged-character.glb` from Character Studio.
2. Copy it into the Godot project's `assets/` folder.
3. Import it in Godot and open the scene generated from the GLB.
4. Verify skeleton hierarchy, materials, and animation names in the Import/Scene docks.
5. Preview `Idle`, `Walk`, `Run`, `Aim`, `Shoot`, and `Death`; check elbows, knees, skirt, hair, and accessories.
6. Do not replace the live player scene until the model has passed the checks above.
