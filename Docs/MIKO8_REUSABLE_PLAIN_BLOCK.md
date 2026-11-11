# Reusable plain building/block

Supplied file: `exec-f8ca6a09-2bab-43ad-ae69-04bfe0cc1d74_Textured_5509899690.glb`. An unchanged copy is preserved in `Source/Environment/PlainBlock/original.glb`, with the editable Blender scene, preparation script and optimisation report alongside it. Reduced from 399,996 to 63,999 triangles for the game.

Prefab: `Game/scenes/reusable_plain_block.tscn`, script `miko8_plain_block.gd`. Instance `dimensions` sets width, height and depth independently. The pivot is ground-centre; the supplied mesh is fitted from its bounds and the collision box uses those same dimensions. Each instance has its own skin material and building origin. `facade_art` is an exported texture choice for future skins.

The first instance replaces the older raised-rim workshop at x55.4, z-.6. Size: 5.44 × 2.83364 × 2.55 m, preserving the crate route's footprint and roof height. The original workshop asset and scene remain available. The new roof has flat block collision and no legacy raised-rim colliders.

Skin: existing approved cel service facade (`ladder_facade_v2.png`), complete pipe terminations, concrete roof and metre-scaled side-panel textures. The shared three-tone material pass provides the front/side contrast. Shared neutral architecture light, rectangular footing/drain and additional contact shadow ground it in the yard. The source colour atlas is preserved in the editable asset; runtime skin replaces it without modifying the original file.

The wall mag pad is mounted on this block's left wall at x52.68, y.65, facing the gameplay camera. Existing approach crates are preserved. The low pad applies horizontal forces only, so it cannot magnetically lift blocks. Opposite-charge crates are drawn toward it; matching ones repel. MIKO receives no magnetic force.

Preview: `Preview Wall Mag Pad.cmd`. GPU captures and validation logs are in `Builds/Validation/PlainBlock` and `Builds/Validation/MagPad`. The pad's physics test temporarily moves other approach crates away to isolate its test body; normal gameplay retains the crate arrangement.

