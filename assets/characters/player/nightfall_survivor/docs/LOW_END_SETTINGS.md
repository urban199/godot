# Low-end settings
- Static low-poly GLB; no large textures or transparent hair cards.
- Not rigged: no Skeleton3D, skin weights, or animation clips.
- Try Godot Compatibility renderer if Forward+ is too expensive.
- Disable SSAO, SSR, volumetric fog, glow, and real-time shadows in Low preset.
- Limit dynamic lights, shadow casters, and active enemies.
- Use 512x512 textures if adding textures later.
- Reduce 3D render scale on Android if needed.
- Profile on actual hardware; a small model alone cannot guarantee FPS.
Next stage: create a humanoid Skeleton3D with skin weights and clips in Blender, then export GLB.
