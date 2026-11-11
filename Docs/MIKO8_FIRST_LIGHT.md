# First Light — Substation 04

27 October 2026. Current default game scene: `Game/scenes/miko8_tutorial.tscn`. Play with `Play MIKO.cmd` or `Play MIKO Tutorial.cmd`. The existing movement/ladder/spell review remains separately available.

One enclosed 32-metre tutorial room, two 16-metre screen widths at the target 16:9 aspect ratio and orthographic camera height 9m. Side-on movement stays in Z=0, with a slight camera elevation revealing platform tops. Camera eases horizontally and clamps to the room. Other aspect ratios show a different horizontal span.

## Opening and lesson

MIKO starts in the native GroundSitIdle in the painted maintenance alcove. Movement input starts GroundSitExit at its source duration, then hands back to existing locomotion. No new sleep/get-up motion is synthesized. GroundSitEnter is also installed, playable with V in the movement review; V again or movement leaves the seated idle. All three clips are in the review dropdown. Native seated head pose is used during the sit sequence, with the accepted gameplay head lift restored afterward.

The lesson tracks gentle walking distance, running/sprinting distance and jumping. A 1.4m maintenance opening and a 0.55m service housing teach two jumps. The opening has a solid shallow catch recess with a jumpable exit; it is not a water/death hazard. Completion requires the recorded movement lessons, passing the opening and reaching the far end. The former green door has been removed; this remains a single room. No charge puzzle or substitute magnetic crate has been added while the final cube is being prepared.

Controller: left stick gentle walk, medium run, full sprint; B / Circle jump; View / Select restart. Keyboard: Ctrl+A/D walk, A/D run, Shift+A/D sprint, Space jump, R restart, M mute. Tutorial limits interactions to movement; the full abilities are preserved in the movement review.

## Depth and atmosphere

1. Dawn sky gradient, stationary relative to camera.
2. Distant painted skyline, parallax factor .10.
3. Nearer painted apartment layers, factor .28.
4. Painted substation rear wall/equipment and rear lamps/pipes, factor .70.
5. Physical player lane, platforms, canopy, service housing, rails and character, factor 1.
6. Sparse foreground pipes, factor 1.15, kept below/outside the playable silhouette.

Original generated art is stored in `Game/art/tutorial`: far_skyline.png, city_dawn.png, substation_rear.png and weathered_surface.png. Full image prompts and generation method are documented in that folder's README. The three approved environment concepts remain in `Concepts/Tutorial`. No concept painting is being used as collision geometry.

Warm practical lamps, cool morning ambient light, shallow rising maintenance steam and drifting dust support the dawn mood. The water placeholder has been removed; the maintenance recess is dry. An original 16-second wind/electrical hum loop plays quietly; it contains no downloaded audio. Weathered surface texture is applied to physical structures through a material shader.

## Character assets and checks

The three ground-sit ZIPs were converted using the existing canonical skeleton pipeline. 14 supplemental reaction/crawl/sit/death clips, 48 clips total including base and ladder libraries. Bone data: `Game/models/miko8/MIKO8_Reactions.json`. Editable animation-only source: `Source/Character/MIKO8/MIKO8_Reactions_Rig.blend`; builder: `build_reaction_library.py`. Source transform errors are in `Builds/Validation/MIKO8/reactions/source_conversion.json`.

`verify_miko8_tutorial.gd` checks seated opening, full sit cycle, walking/running lesson progress, channel clearance, service-housing collision/jump clearance, safe catch-recess recovery, completion, camera clamp and relative parallax. Rendered wake/courtyard/end frames inspected. `verify_miko8_light_hits_landing.gd` rerun with the 48-clip library; light-hit recovery and moving landing momentum checks passed. Validation logs and captures are in `Builds/Validation/MIKO8/reactions`.

The older industrial_city scene and its sprite controller are retained as historical game references; they are no longer the default launch scene. The step-up template is not required for this walk/run/jump room and has not been integrated as an automatic traversal mechanic.

1080p optimization update: the tutorial now uses a separate 76,123-triangle gameplay character, retaining the original in the detailed movement review. Tiny dust/bulb meshes also simplified. Tutorial launcher runs at 1920x1080; F3 shows live FPS and window size. See MIKO8_1080P_PERFORMANCE.md for measured results, variability and evidence.
