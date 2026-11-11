# Substation player-plane and depth revision

User review: the first physical deck, rear service strip, railings, gap and green end door did not match the approved concept. Further feedback identified a dark far layer behind a hazy middle layer. The painted machinery's lighting was approved and retained.

## Current scene

- Nearest painted architecture is now two 1774px-wide panels spanning 14m each, approximately 127 source pixels/metre against 120 rendered pixels/metre at 1920x1080 / 9m camera height. The old single panel stretched over 32m is retained as a source but is no longer displayed. No bitmap upscaling was used.
- Platform fronts use dedicated painted chipped-concrete fascia; tops use individually placed slab caps with varied UV offsets/flips and small tone changes. The underlying render box is below the caps to prevent coplanar surface fighting; the accepted collision shapes and traversal heights are retained.
- Rear service deck is narrower and uses paving; the former green strip is removed. No water placeholder remains. The green exit-door geometry and little yellow marker blocks are removed.
- The maintenance opening has an opaque illustrated service wall, dark dressed jambs, a paved catch floor and a matching lower slab front. There is no distant skyline visible through its wall. Under-platform backing closes unintended dawn-coloured voids below the foreground pipe.
- Plain 3D rail primitives are replaced by detailed transparent painted rail modules behind MIKO: chipped metal, collars, bolts and foot plates. These are decorative rear rails, not player-plane collision objects. The old plain canopy, repeated straight utility poles and cable line were removed; the painted maintenance alcove supplies that architecture, with a warm real light spill on MIKO.
- Camera elevation reveals more of the platform tops. The instruction panel is tucked into the lower-left corner to avoid covering feet in the recess.
- Same dawn haze hue across depth: far skyline has both a new pale low-contrast source image and strong shader haze (.84) / mip softness (2.4); middle city uses .20 haze and its existing painted softness; nearest machinery stays crisp. Layer blur uses explicit mip sampling, not full-screen blur.
- Animated drifting haze, restrained warm light shafts and rising vent steam complement the existing dust and original quiet sound loop. The background lighting approved by the user is unchanged in this revision's final pass.

All new raster assets were generated with built-in image_gen using `Concepts/Tutorial/03_substation_courtyard.png` as the style reference. Originals and previous assets are retained. Saved files and prompt briefs are in `Game/art/tutorial/README.md`.

Validation: rendered at actual 1920x1080, opening/recess/end views inspected, and the movement/collision/jump/recovery/reset tutorial regression rerun. Evidence: `Builds/Validation/MIKO8/art_revision`; original pre-revision wake/end renders are saved there for comparison. A visual match to the concept remains a user judgement; passing traversal checks does not establish art approval.

Final depth pass replaces the mixed-distance city_dawn source with mid_apartments.png, containing only one middle-distance apartment row. Far layer uses far_skyline_haze.png. A separate red-material isolation probe verified that the far Sprite3D actually renders through the depth material; it is not only an inspector setting. Rail UVs join individual bays with complete end-post caps, removing doubled posts at module boundaries.

Final 1080p captures: room_8.0.png, room_17.7.png and room_29.0.png in the art_revision validation folder. These show the varied slab caps, complete dry recess, painted rails with joined bays, corner HUD, narrow textured rear deck and single-distance apartment layer. Completed traversal regression passed before the final background-only asset swap; final asset/material rendering smoke check passed afterward. Artwork changes have not been subjected to a new full uncapped performance comparison; the previous performance table is historical and F3 provides current live FPS.
