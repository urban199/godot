# Rigged character status

The Character Studio export has been upgraded to bake mesh transforms into a consistent character-local space, create a shared humanoid skeleton, generate normalized approximate skin weights, and export six animation clips: Idle, Walk, Run, Aim, Shoot, and Death.

**Known limitation:** the mesh is still a stylized parametric base assembled from primitive geometry. The rig and weights are generated heuristically, not manually painted/production-quality. Browser GLB export and Godot import/deformation still require end-to-end visual verification. See `character-studio/RIG_SKINNING_EXPORT_NOTES.md` for the test checklist.
