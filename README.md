# SHINOBI ARENA 2D

Original anime-inspired 2D side-scrolling fighter foundation for Godot 4.5.1. The menus and arenas use code-drawn UI/scenery, while three original character atlases provide gameplay poses. This is not a finished commercial release.

## Current prototype

- Home, Quick Battle/Practice selection, character and arena selection, Collection, Settings, Credits, Battle, Pause, and Result screens.
- A fighter showcase on Home; Character Select places the chosen player and rival on opposite sides of a centered roster, with quick rival cycling.
- Three selectable fighters with distinct transparent sprite atlases, stats, and AI opponent selection. Atlas pose mapping is documented in [`assets/sprites/README.md`](assets/sprites/README.md).
- Three separate arena scenes with distinct illustrated selection previews, scenery, ground collision, boundaries, and spawn metadata.
- Movement, jump, guard, a three-step combo, dedicated hitbox/hurtbox areas, dash, Energy Bolt and Rising Strike usable while steering, AI/Practice modes, HP/energy HUD, round timer, pause, and KO/timeout/draw result. Running and jumping add eased body motion, with a soft landing squash.
- Thick health bars with numeric HP, separate Energy Bolt and Rising Strike cooldown indicators, and a temporary banner showing the fighter and skill whenever either fighter casts a skill.
- Touch buttons with Classic/Compact layouts, plus release on pause and app focus loss.
- Versioned local settings and win/loss/draw counters under `user://`; settings include master/music/SFX volume, movement sensitivity, touch layout, effects quality, screen shake, flash intensity, and reduced effects.
- On pushes to `main`, GitHub Actions validates the Godot project, then exports and deploys the Web build to GitHub Pages only if validation passes. Windows and Android exports remain manual or version-tag workflows.

## Controls

- Move: A/D or Left/Right
- Jump: W / Space / Up
- Attack: J
- Combo: press J within the combo window
- Energy Bolt: K
- Rising Strike: U
- Dash: L
- Guard: H / Shift
- Pause/back: Escape

Open `project.godot` in Godot 4.5.1 to inspect or run the project. Fighter atlases are generated prototype art and arena scenery is procedurally drawn; both still need visual polish and in-game alignment review before release. GitHub Actions workflow files exist for validation and platform exports; they were not run in this pass.

## PRD implementation status and static verification

This section maps [`PRD_SHINOBI_ARENA_2D.md`](PRD_SHINOBI_ARENA_2D.md) to the current implementation. Static checks confirmed that referenced `res://` paths in scripts/scenes exist, all three sprite atlases have the expected 1536×1024 dimensions, and `git diff --check` reports no whitespace errors. These checks do not parse Godot scripts or validate runtime behavior.

| PRD area | Current implementation | Status |
|---|---|---|
| Project and session | `project.godot` selects `scenes/main.tscn`, configures GL Compatibility, and registers `GameSession`. Session owns mode and selected IDs. | Implemented in code; runtime unverified |
| Home and navigation | `scripts/main.gd` builds Home, mode, character, arena, Collection, Settings, Credits, Battle, Pause, and Result screens with back routes. | Implemented in code; layout/runtime unverified |
| Character selection | `scripts/game_session.gd` defines three fighters with sprite paths and stats; Character Select previews atlas frames and stores player/opponent IDs. | Implemented with generated pose atlases; runtime unverified |
| Arena selection | `scenes/arenas/` has Forest Shrine, Training Dojo, and Ruined Outpost scenes. Data supplies scene path, collision bounds, and spawn points. | Implemented in code; visual/runtime inspection pending |
| Battle | `scripts/combat/hitbox.gd` and `hurtbox.gd` provide separate combat areas; fighter supports one-hit-per-swing combo hit confirmation, a three-step light/heavy chain, projectile, Rising Strike, and guard. `scripts/arena_stage.gd` supplies arena scenery and collision. | Core systems implemented; balance/runtime verification pending |
| HUD and match flow | `scripts/hud.gd` shows thick numeric health bars, energy, independent cooldowns for both skills, skill-use banners, timer, pause and touch controls. Match resolves once on KO/timeout/draw, then provides result routes and rematch. | Implemented in code; runtime unverified |
| Settings and progress | Versioned local saves cover master/music/SFX buses, sensitivity, touch layout, effects quality, shake/flash preferences, and match record. | Implemented in code; no audio tracks yet; language and unlock progression absent |
| Accessibility and platform adaptation | Keyboard focus, touch input, focus-loss release, reduced effects, and responsive canvas scaling are represented in code/config. | Needs runtime/device inspection; gamepad and safe-area behavior unverified |
| Assets and audio | Three generated transparent fighter atlases are in `assets/sprites/`; arenas are code-drawn. No music/SFX assets are included, though separate volume controls and buses are configured. | Prototype sprites integrated; final polish and audio assets remain |
| CI and exports | Pushes to `main` run validation; the Pages job depends on validation, exports the Web preset, then uploads and deploys it. Android export enables ETC2/ASTC texture import, prepares Java 17 and Android SDK components, then creates a debug APK from Godot's standard Android export template. Windows and Android exports are manual or `v*` tag workflows. | Workflow config inspected statically; enable **Settings → Pages → Build and deployment → Source: GitHub Actions** once; platform workflows remain unverified |

### Remaining implementation plan

1. **Validate the current flow in the editor/runtime**: confirm parsing, navigation, focus, collision, touch press/release, pause, timeout, KO, results, rematch cleanup, and local save behavior.
2. **Refine distinct arena scenes**: inspect layouts at runtime, tune visual layers, and adjust each ground/bound/spawn arrangement based on play.
3. **Complete combat polish**: tune combo and Rising Strike windows/damage, add difficulty options, hit-stun/invulnerability tuning, and test cooldown presentation and hitbox behavior at varied distances.
4. **Complete character animation**: refine atlas frame alignment, add dedicated hurt and fuller idle/run/skill cycles, and tune sprite size/anchors in-game. Current atlases use a single generated pose for idle, jump, guard, skills, and KO, with only short run and attack sequences.
5. **Complete settings and accessibility**: verify audio-bus routing, touch layouts and safe areas, and add language selection if it remains in release scope.
6. **Complete CI and release configuration**: enable GitHub Pages with **Settings → Pages → Build and deployment → Source: GitHub Actions**; then pushes to `main` will publish Web after validation. Use version tags or manual runs for Windows/Android artifacts; configure Android signing outside the repository and document asset licenses.
7. **Verify target platforms**: inspect browser, Windows, and physical Android exports, profile performance, and complete the PRD acceptance checklist before release.

### Static review limits

Static inspection does not prove scripts parse, UI fits target devices, input works at runtime, local saves behave correctly, workflows succeed, or exports work. Those checks belong to a later editor/runtime/platform verification pass. No game, build, export, or automated test was run, and no tools were installed or updated for this work.
