# Integration Status

## Main game wiring

- `scripts/humanoid_visual.gd` loads this package's GLB for the survivor visual.
- The main game keeps its existing `CharacterBody3D`, movement, combat, camera switching, enemies, and mobile controls. The package demo controller does not replace those systems.
- The visual loader checks for a mesh and skeleton, makes imported nodes visible, forces imported base materials opaque, locates animation clips (including library-prefixed names), adds a right-hand `BoneAttachment3D` weapon socket, and falls back to the procedural survivor if the mesh or skeleton is unavailable.
- `Idle`, `Walk`, and `Run` are selected from player movement; right mouse / touch `AIM` selects `Aim`; firing and reload events trigger their matching clips; nonlethal damage triggers `Hit`; lethal damage and zombie death trigger `Death`.
- The existing `AnimationPlayer` is retained, with short transitions between locomotion/aim clips and combat one-shots; locomotion loops while combat/reaction clips are configured as non-looping.
- `Hit` and `Death` contain distinct authored rotation/translation keys generated from the existing 18-joint rig by `tools/characters/extend_neko_animations.js`.
- `scripts/ci/validate_character.gd` checks importable mesh geometry, UV skin resource, skeleton, all eight unique clips, and player-scene use of the imported model and hand socket.

## Static findings

- The active GLB has an 18-joint skeleton and 10,848 vertices/57,072 indices across 42 triangle primitives, with UV0, skinning, nine materials, and the embedded color atlas. A deterministic midpoint-refinement stage expands the original 3,067-vertex/14,268-index mesh while interpolating UVs, normals, and skinning weights; the generator also appends distinct `Hit` and `Death` clips to the six source animations.
- This is a geometry-density and shading improvement, not a new character sculpt: anatomy, hair/clothing design, and silhouette detail remain limited by the source mesh. A genuinely higher-detail model needs a separately authored or sourced mesh/rig. The modified GLB has only been checked statically; Godot import, deformation, and visual appearance still require the GitHub workflow and preview review.
- The new approved anime reference sheet is an image-only visual target. The plan explicitly says it must not be treated as model geometry; it is not referenced by runtime scenes.
- The image advertises more maps and animations than the included archive actually contains. The actual GLB inventory is 18 skeleton joints and six clips; the included textures are the starter atlas and a face reference image.
- Headless Godot 4.5.1 import, scene startup, rig/clip validation, and web export are configured in GitHub Actions. Those runs cannot establish visual quality; a human still needs to inspect the character, weapon alignment, and deformation in the exported preview. No GitHub Actions run has been triggered from this workspace.
