# Neko Nightfall — Anime HD Web Upgrade Pack

## Target
- Godot 4.5.1
- Web browser / GitHub Pages
- Compatibility renderer (WebGL 2.0)
- Visual direction: high-detail anime character, gothic black/red outfit, rain-soaked neon city
- Priority: balance between image quality, download size, and FPS

## What's included
- The complete original Godot project and existing gameplay scripts/scenes.
- The existing multi-part GLB refined with a subdivision pass to smooth coarse silhouettes.
- `assets/art_direction/neko_character_turnaround_reference.png`: generated character turnaround / costume reference.
- `assets/art_direction/anime_city_environment_reference.png`: generated city mood and environment reference.
- Existing GitHub Actions workflows and export preset retained.

## Important asset status
The supplied art images are concept references, not UV texture maps and not 3D meshes. The GLB refinement increases mesh density and improves coarse silhouettes, but it does NOT add a production-quality humanoid skeleton, skin weights, or a set of authored animations. It is not equivalent to a professionally sculpted/rigged Genshin Impact character. A genuine result at that level requires a fully authored or properly licensed rigged GLB/Blend asset and compatible animation clips.

## Next steps
1. Open this folder in Godot 4.5.1 and let imported assets finish processing.
2. Run the main scene and check the model scale/materials.
3. Push to GitHub and run the Web workflow; test the deployed game in a real browser.
4. To reach the full target, replace/upgrade the GLB with a rigged humanoid asset whose license allows redistribution, then retarget idle/walk/run/aim/shoot/reload/hit/death animations.
5. Use the city reference as a style guide while adding actual 3D building/street assets; do not use the reference image as a fake 3D level.

## Web performance guidelines
- Keep Compatibility renderer for web.
- Prefer 1K–2K textures for most props and reserve larger textures for the hero character only when the download budget allows it.
- Limit dynamic lights, transparent materials, and screen-space effects.
- Test on real target browsers; a successful headless export alone does not prove runtime correctness.
