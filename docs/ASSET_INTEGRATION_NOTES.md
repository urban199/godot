# Asset Integration Notes

## New generated assets
`assets/generated_pack/items/` contains individual inventory icons for Medkit, Ammo, Battery, Keycard, Flashlight, Grenade, Herb, Document, Supply, Treasure, Pistol Ammo and Fuse. `item_icon_atlas.png` is a 4x3 atlas.

`assets/generated_pack/environment/` contains stylized placeholder surface images. Use them as prototype albedo textures, and configure roughness/normal maps separately where needed.

`assets/generated_pack/references/` contains generated concept sheets for the character and city, plus showcase boards for assets and UI. They are not production meshes, rigged characters, UV texture atlases or ready-made 3D buildings.

## Safe integration
- Import PNGs in Godot and create `Texture2D` references for inventory slots.
- Use `item_icon_atlas.png` with an `AtlasTexture` per cell or use the individual icons directly.
- Keep the existing gameplay scripts. Wire inventory icons only after confirming the project's current item data model.
- Use environment swatches on blockout props first; replace with authored PBR materials later.
- For the real smooth animated hero, add a licensed rigged humanoid GLB with skin weights and animation clips. The current mesh refinement does not create skinning or authored animation.
