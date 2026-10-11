# Neko Nightfall — Anime Character Builder for GitHub Pages

This package adds a browser-based parametric anime character builder to the existing Godot project. You do not need to run Blender or Godot editor locally to adjust the builder parameters.

## Deploy
1. Extract this ZIP.
2. Upload the contents of `godot-projectV0/` to the root of your GitHub repository.
3. In GitHub repository settings, choose **Settings → Pages → Build and deployment → Source: GitHub Actions**.
4. Push to `main`, or open **Actions → Neko Character Studio Pages → Run workflow**.
5. Open the Pages URL shown by the workflow.

The Pages workflow publishes `character-studio/` as the website. If the repository uses a different default branch, change `branches: [main]` in `.github/workflows/character-studio-pages.yml`.

## Builder features
- Parametric smooth-shaded anime base character generated in Three.js.
- Change skin, eye, hair and outfit colors.
- Hair presets: bob, long, twin tails and ponytail.
- Tune eye size, head size, hair volume, height, body proportions and leg length.
- Outfit presets: gothic combat dress, anime uniform, cyber streetwear and light armor.
- Add/remove accessory details.
- Change material gloss, key/rim lights, background and preview angle.
- Randomize, reset, download PNG screenshot, save JSON preset and export a static GLB.

## Important limits
- The character is assembled from editable parametric 3D geometry. It is a useful base-mesh builder, not a sculpting tool and not a professionally sculpted character at Genshin Impact quality.
- GLB export currently exports static geometry and materials. It does not create a humanoid skeleton, skin weights, or professional animation clips.
- A saved JSON preset records the chosen parameters; it does not modify the original Godot model until the exported GLB is manually integrated.
- Three.js is loaded from jsDelivr, so the builder requires an internet connection.
- Exported GLB can be downloaded in the browser, then committed to the repo and imported into Godot. Test its scale/materials in Godot before replacing the game's existing character.
- The Godot game workflows are retained. The workflow named `character-studio-pages.yml` deploys the builder; `web.yml` can separately build a Godot Web artifact.
