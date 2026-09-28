# Neko Nightfall

An original 3D survival-horror game built with Godot 4.5.1. Explore the dark mansion courtyard, conserve ammunition, defeat the infected, collect supplies, and reach the blue exit door.

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
- Escape: release/capture mouse

This is an original survival-horror project and does not use Resident Evil characters, names, story, or assets.

## Mobile and Android preview

The game is configured for sensor landscape (orientation=4) and includes touch buttons for movement, flashlight, reload, and fire. Desktop controls remain WASD, mouse, F, R, and left click. Preview the Pages build at https://urban199.github.io/game/; add a query such as ?v=mobile-landscape after a deployment to bypass an old browser cache.

Android export is intentionally not run yet: first validate the Web preview, then use the existing Android workflow/export preset on a machine with the Android SDK configured.


The current map is a larger city district with an open central road, perimeter buildings, alleys, an exit gate, and procedural placeholder architecture. Upload optional character/environment assets into assets/characters and assets/environment manually.
