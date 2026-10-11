# Neko Nightfall

An original 3D survival-horror game built with Godot 4.5.1. The current playable slice follows a survivor through a rain-darkened alley and minimarket: retrieve a fuse, restore power, survive one infected, and reach the locked gate.

## Play the webview

After the `Deploy Godot Webview` workflow succeeds, play the browser build at:

https://urban199.github.io/game/

If Pages is not enabled yet, open **Settings → Pages** and choose **GitHub Actions** as the source once. Future pushes to `main` deploy automatically.

## Controls

- WASD: move
- Shift: sprint
- Mouse: aim
- Left click: fire
- R: reload / restart after win or death
- F: flashlight
- Space: jump
- E: interact
- Q: use a first-aid kit
- Tab: inventory
- Escape: pause / resume

This is an original survival-horror project and does not use Resident Evil characters, names, story, or assets.

## Mobile and Android preview

The game is configured for sensor landscape (orientation=4) and includes touch buttons for movement, flashlight, reload, fire, interaction, healing, inventory, and pause. Desktop controls remain WASD, mouse, F, R, E, Q, Tab, and Escape. Preview the Pages build at https://urban199.github.io/game/; add a query such as ?v=mobile-landscape after a deployment to bypass an old browser cache.

Android export is intentionally not run yet: first validate the Web preview, then use the existing Android workflow/export preset on a machine with the Android SDK configured.


The playable scene currently uses a compact procedural alley/shop environment to keep the first mission slice light. The wider city generator remains in `scripts/game.gd` but is not spawned in this slice. The authored `anime-model.glb` remains static until the rigging workflow runs successfully; its vertex colors are not a substitute for imported textures or verified animation.
