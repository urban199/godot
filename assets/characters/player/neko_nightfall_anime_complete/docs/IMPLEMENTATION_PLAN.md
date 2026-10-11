# Neko Nightfall — Character Asset & Integration Plan
**Target:** Godot 4.5.1 • Existing repository: `https://github.com/urban199/godot`  
**Purpose:** Give this plan to a coding agent to implement a complete, optimized 3D playable character in the existing game.  
**Important:** The accompanying concept image is a visual target only. It is not a rigged 3D model and must not be imported as a character mesh.

## 1. Non-negotiable requirements
- Work inside the existing repository. Inspect it first; do not replace the project or rewrite unrelated systems.
- Keep the current player controller, weapon logic, enemy logic, camera switching, touch controls, UI, and input actions unless a compatibility fix is required.
- Target Godot **4.5.1** and the project's current renderer. Prefer the Compatibility renderer if that is what the project currently uses.
- The character must be a real 3D humanoid with a `Skeleton3D`, skinned mesh, materials, UVs, and working animation tracks—not a static image or a collection of unrigged meshes.
- Provide a usable third-person model and support first-person mode without showing the full body clipping through the camera. Use a separate first-person arms/weapon viewmodel if the current game architecture supports it.
- Optimize for low-end hardware and mobile: avoid excessive bones, materials, transparent layers, real-time lights, and high-poly accessories.
- All changes must be committed to the existing branch and verified through GitHub Actions. The developer's local PC should only need a browser and GitHub.

## 2. Character art direction
Use the approved concept image as a visual reference:
- Anime-inspired 3D heroine, short light-blonde hair, red/amber eyes, dark gothic-tactical survival outfit, utility belt, gloves, boots, restrained metal details.
- Keep the design suitable for a survival-horror game; no exaggerated physics or excessive transparent clothing.
- Create a consistent front/side/back silhouette. Avoid loose accessories that intersect the body during animation.
- Expose safe customization parameters (hair/eye/outfit colors) only if they can be implemented cleanly.

## 3. Required deliverables
Create or update the following paths, adapting names to the existing project's conventions:
- `assets/characters/neko/mesh/` — source model (`.blend` if available) and exported `.glb`.
- `assets/characters/neko/textures/` — texture maps used by the model.
- `assets/characters/neko/materials/` — reusable Godot materials if needed.
- `assets/characters/neko/animations/` — source animation file or documented animation source.
- `scenes/characters/neko_player.tscn` — character scene with `Skeleton3D`, skinned mesh, `AnimationPlayer` or `AnimationTree`, collision shape, and attachment points.
- `scripts/characters/neko_animation_controller.gd` — animation state integration, only if the existing controller cannot handle it.
- `docs/CHARACTER_IMPLEMENTATION.md` — notes, import settings, animation names, performance profile, and controls.
- Do not create duplicate player controllers if the repository already has one; extend the existing controller instead.

## 4. Model, skeleton, skinning, and materials
1. Inspect `project.godot`, player scene/scripts, existing animation names, weapon attachment points, camera setup, and export workflow.
2. Use a humanoid skeleton with sensible bone naming and consistent scale/orientation. Include root/hips, spine, neck/head, arms/hands, legs/feet, and fingers only to the extent needed by current gameplay.
3. Apply transforms and validate the armature. Check for broken weights, flipped normals, detached accessories, stretched limbs, and mesh clipping.
4. Export a Godot-compatible `.glb` with embedded or correctly referenced textures. Keep source files when available.
5. Use a compact PBR set: albedo/base color, normal map only where useful, and roughness/metallic values. Prefer a single atlas or a small number of materials.
6. Use readable, non-empty textures. Do not claim a 4K texture set exists unless the actual files are generated and committed. For low-end targets, ship a 1K or 2K runtime texture set and retain larger source textures only if useful.
7. Ensure hair and clothing are attached to the skeleton and do not require costly real-time cloth simulation. Use simple bone-driven hair motion only if stable; otherwise use a static/limited secondary-motion setup.

## 5. Required animation set
Animations must be actual imported animation clips, tested in Godot, and named consistently. Reuse existing names where the game already depends on them.

**Core locomotion**
- `Idle`
- `Walk`
- `Run`
- `Sprint` (optional if Run already covers sprint speed)
- `Turn_Left`, `Turn_Right` (optional if handled by the controller)

**Combat**
- `Aim_Idle`
- `Aim_Walk`
- `Aim_Run` or `Aim_Strafe`
- `Shoot`
- `Reload`
- `Weapon_Equip` / `Weapon_Unequip` if supported
- `Melee_Attack` if the game already has melee combat

**Reactions and movement**
- `Jump_Start`, `Jump_Loop`, `Jump_Land` only if the project has jumping
- `Hit_Front`, `Hit_Back`, `Hit_Left`, `Hit_Right` or a smaller compatible hit set
- `Crouch_Idle`, `Crouch_Walk` only if crouching exists
- `Death`

At minimum, `Idle`, `Walk`, `Run`, `Aim_Idle`, `Shoot`, `Reload`, `Hit`, and `Death` must work. If source animations cannot be legally or technically obtained, create simple original placeholder clips and clearly document which clips remain placeholders. Do not fake animations by merely renaming identical clips.

## 6. Animation tuning
- Use `AnimationTree` with a state machine or blend space where appropriate; preserve the current controller architecture if it already has a working system.
- Blend locomotion smoothly based on actual velocity; do not transition to Run while the player is stationary.
- Configure sensible blend times (start around 0.12–0.25 s and tune after testing).
- Set looping correctly: Idle/Walk/Run/Aim locomotion loop; Shoot/Reload/Hit/Death are non-looping unless the clip design requires otherwise.
- Ensure one-shot animations return to a valid locomotion/aim state.
- Prevent repeated reload/shoot animation triggers from restarting every frame. Trigger them from the existing gameplay events.
- Sync firing effects and recoil to the weapon logic, but do not let cosmetic animation decide whether a shot is actually fired.
- Aim at the current camera target if the game supports aim targeting. Use a small upper-body additive/override layer only if compatible with the rig.
- Test transitions for abrupt snapping, foot sliding, root-motion conflicts, weapon hand mismatch, and reload hand placement.
- Document every animation's loop setting, expected duration, trigger, and fallback.

## 7. Scene and gameplay integration
- Attach the model to the existing player scene rather than replacing the player root or physics controller.
- Keep movement and collision physics separate from the animated mesh. The character's visual skeleton must not drive physics unexpectedly.
- Add named attachment nodes such as `WeaponSocket`, `RightHandSocket`, and `HeadSocket` only where needed.
- Align the weapon to the hand in idle, aim, shoot, and reload poses. Avoid duplicating the weapon if the game already spawns/equips it.
- In third-person mode, show the full body. In first-person mode, hide the head/body parts that obstruct the camera or use a separate arms-only viewmodel. Keep weapon and crosshair behavior intact.
- Verify camera switching, mouse capture, firing, reload, damage, death, respawn, and any touch UI on mobile.
- Do not hardcode input names before checking `project.godot`; use existing Input Map actions.

## 8. Performance budget
Initial targets; measure and adjust rather than claiming untested results:
- Prefer a single skinned body mesh with a small number of accessory meshes.
- Aim for roughly 15k–30k triangles for the full character LOD0; reduce if the scene already struggles.
- Keep material slots low (target 3–5 for the character).
- Use 1K/2K runtime textures, mipmaps where suitable, and compressed texture import settings compatible with the target renderer.
- Add LODs only if they work with the project's import/export setup. Do not add complex LOD tooling solely for appearance.
- Avoid mandatory real-time hair/cloth physics. Use baked animation or simple secondary bone motion.
- Check draw calls, texture memory, animation cost, and frame pacing in a representative scene.
- Never state that a performance target passed without a measured test or reproducible build log.

## 9. GitHub-only build and validation workflow
The developer uses a low-spec PC and does not want to run Godot locally. Use GitHub Actions for validation/export:
1. On each push/PR, install or download the pinned Godot 4.5.1 headless/editor binary appropriate for the runner.
2. Run a headless editor import step, for example `godot --headless --editor --path . --import`.
3. Run a headless project validation/startup check. Capture the full log and fail the job on script parse errors, missing resources, or import failures.
4. If the repository already has a Web export preset and working deployment workflow, repair and extend it instead of creating competing workflows.
5. Export Web using the existing preset name and publish to GitHub Pages only after successful validation.
6. Upload logs and export artifacts to the Actions run so failures are inspectable in a browser.
7. Avoid committing `.godot/`, temporary builds, cache directories, or generated exports unless the repository explicitly requires them.
8. If the rig/animation source is created in Blender, use a pinned headless Blender job only if the runner can install it reliably; do not make a fragile Blender dependency mandatory for every game build if exported `.glb` is already committed.
9. Do not report success merely because the workflow YAML parses. Require Godot import/export and resource checks to pass.

## 10. Acceptance checklist
- [ ] Character is a real skinned 3D model with `Skeleton3D`.
- [ ] Model has working UVs and actual referenced texture/material files.
- [ ] `.glb` imports in Godot 4.5.1 with no missing-resource warnings.
- [ ] All required animation clips are present and visibly distinct.
- [ ] AnimationTree/AnimationPlayer transitions work from gameplay events.
- [ ] Weapon aligns in aim, shoot, and reload poses.
- [ ] Third-person and first-person camera modes both work without major clipping.
- [ ] Existing movement, collision, enemies, damage, and UI remain functional.
- [ ] Character remains usable at low graphics settings and on mobile-oriented settings.
- [ ] GitHub Actions import/validation/export succeeds after push.
- [ ] Web preview deploys from the existing Pages workflow, if that is already configured.
- [ ] `docs/CHARACTER_IMPLEMENTATION.md` documents limitations and any placeholder clips honestly.

## 11. Implementation order for the coding agent
**Phase A — Audit first**
- Inspect repository tree, current player scene/script, animation system, weapons, cameras, Input Map, project renderer, and workflows.
- Write a short audit note listing exact files to edit and compatibility risks.
- Do not begin by replacing the project.

**Phase B — Asset**
- Add the actual rigged model and texture files.
- Verify skeleton hierarchy, skinning, UVs, materials, scale, and import settings.
- If the coding agent cannot produce a genuine rigged model, stop and report the missing asset dependency instead of substituting a concept image or empty mesh.

**Phase C — Animation**
- Import and inspect all clips.
- Configure `AnimationPlayer`/`AnimationTree`, blend transitions, looping, and one-shot triggers.
- Add a small test scene or debug mode if necessary, without replacing the main game.

**Phase D — Integration**
- Attach the character visual to the existing player scene.
- Wire locomotion/combat signals from existing logic.
- Test camera modes, weapon sockets, reload/shoot, hit, death, and respawn.

**Phase E — CI and review**
- Run GitHub Actions import, validation, and Web export.
- Fix errors using logs; do not silence errors broadly.
- Update README/docs with the asset paths, clip names, controls, and build status.
- Commit changes in small, reviewable commits.

## 12. Required final report from the coding agent
The implementation is not complete until the agent reports:
1. Exact files added/modified.
2. Actual source model format and exported model path.
3. Skeleton root and key bone/socket names.
4. Complete list of imported animation clips and which are placeholders.
5. How locomotion, shooting, reload, damage, and death trigger animation.
6. Godot import/validation result and GitHub Actions run link.
7. Web preview link if deployment succeeded.
8. Known limitations and performance measurements, if measured.
