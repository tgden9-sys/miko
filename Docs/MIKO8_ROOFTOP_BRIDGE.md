# Rooftop bridge and building integration

The playable yard now includes two 5.2 m buildings at x=32.8 and 46.5, connected by three supplied platform sections. The original 2.83364 m ladder building and end workshop remain in place. The tall building ladder is at x=30.5.

## Final assets

| Asset | Original | Game GLB | Triangles |
|---|---:|---:|---:|
| cawami / deck | 26.9 MB | 6.11 MB | 328,566 → 64,000 |
| cawawa / cantilever | 30.3 MB | 6.12 MB | 375,948 → 64,000 |

Game models are `Game/models/environment/bridge_platforms/deck.glb` and `cantilever.glb`. The final version retains more rail/grate geometry and uses lossless cel-painted colour atlases. Unused normal and metal/roughness maps are excluded. Original Downloads files are untouched. Editable high-detail Blender files with non-destructive reduction modifiers and the preparation script are in `Source/Environment/BridgePlatforms`.

The bridge uses cantilever–deck–cantilever, with the right cantilever reversed. Section widths/depths are fitted independently so the grates and rails meet. Thin joint covers bridge the deck seams. The arrival building's mesh and collision are reflected in X, placing its solid side against the bridge. The reflected mesh reverses triangle winding and normals without negative collision scaling. Bolted receiver plates attach the braces to the walls at both ends.

Both buildings have custom full-height front art: `Game/art/cel_scene/tall_departure_facade_v1.png` and `tall_arrival_facade_v1.png`. Source fixtures retain their intended scale. The arrival facade is mapped to its reflected main wall. Bridge paint is in `bridge_deck_atlas_v2.png` and `bridge_cantilever_atlas_v2.png`, embedded in the exported game models. Generation used built-in image_gen; prompts and input references are in `Source/Environment/BridgePlatforms/finish_prompts.md`.

## Grounding and ladder

The ladder buildings and workshop now have chamfered concrete footing plinths, dark lower contact, drain channels and tighter ground shadows. L-shaped footprints follow the open ladder bays; the arrival footprint follows the reflected layout.

Both the original and taller ladders use reusable 3D modules in `Game/models/environment/industrial_ladder`: shaped steel rails, anti-slip rungs, wall stand-offs with bolts, and rounded roof returns. Their palette is authored as vertex colours, with cel lighting applied at assembly. `IndustrialLadder.blend` and its builder remain editable in the source folder. Rung spacing, height fitting, root motion, faster climbing and accepted entry/exit turns are retained.

Climbing pace is now 2.45 in both directions (previously 2.04), while entry/exit/idle stay at 1.7. Runtime timing on the 5.2 m ladder is 5.60 seconds up or down versus 6.25 seconds previously, excluding the final turn. Rung travel alone is 3.45 seconds versus 4.10 seconds. `ladder_pace.log` and `ladder_pace_pose.log` pass; 1,064 hand/foot samples retain maximum source-motion error under 0.00456 m. Holding, reversal, jump-off, reset, floor support and the movement-review ladder pass as well.

MIKO's energy wake and its control are removed from the playable scene. His approved shader is unchanged. The trial source files remain available but are not loaded. The new cel city and F9 comparison remain available.

## Validation and launch

`review_miko8_rooftop_bridge.gd` passes in `Builds/Validation/BridgePlatforms/finished_physics.log`: 185 roof/deck support samples with no gaps, wall support at all eight receiver locations, tall-ladder ascent, crossing to the arrival roof, return crossing, descent, and original ladder ascent. It also checks removal of the wake, preservation of MIKO's shader and the ladder vertex palette. The GPU visual review passes with no runtime/shader errors in `finished_visual_error.log`; images were inspected for the bridge, fronts, mounting and footing details.

Run `Preview Rooftop Bridge.cmd` to start on the bridge using the normal wider camera. Existing yard launchers also contain the new route.
