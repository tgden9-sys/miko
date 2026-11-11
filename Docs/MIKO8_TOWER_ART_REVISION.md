# Matched tower set — 5 November 2026

This supersedes the first tower art/layout pass in `MIKO8_PLATFORM_TOWER_COURSE.md`. The supplied small, medium and large bodies now form one matched course, with common manufactured caps, feet and ladder dimensions. Only the first and last ladders face the playable lane; the four middle models are rotated 180 degrees.

## Current course

| Tower | X | Model | Deck | Front ladder |
| --- | --- | --- | --- | --- |
| 1 | 40.0 m | Small | 2.80 m | Yes |
| 2 | 42.9 m | Medium | 3.55 m | No; reversed |
| 3 | 45.8 m | Large | 4.30 m | No; reversed |
| 4 | 48.7 m | Large | 4.30 m | No; reversed |
| 5 | 51.6 m | Medium | 3.55 m | No; reversed |
| 6 | 54.5 m | Small | 2.80 m | Yes |

All rises are .75 m and the centre spacing is 2.9 m. The cap bodies are 2.0 by 1.6 m on every model, with identical trim/splice overhangs. Smooth support is 1.92 by 1.54 m. Ladder rail centres are .43 m apart, with .2648 m rung spacing and the existing -.08 m rung offset. Footplates sit at ground level with no raised concrete base. Native BPG mounts, exits, turns and climb speeds are retained.

## Geometry and finish

The original reconstructions differed in ladder/cap proportions, baked illumination, white/beige steel hues and irregular internal surfaces. `Source/Environment/PlatformTowers/build_matched_set.py` preserves the originals as inputs and produces an editable matched Blender scene for each height plus runtime GLBs in `Game/models/environment/platform_towers_v2`.

The existing side/post details and service panels are retained and fitted to a shared body footprint. The centre corridor is cut on straight planes, with clean steel closure faces; this removes both the old ladders and ambiguous internal rung fragments. New rear bracing uses actual X-shaped steel beams, not a painted ladder pattern. The supplied post-coupling plates remain; a duplicate newly authored row was removed during visual review.

The cap is authored once by the same procedure for all three sizes: bevelled perimeter beam, flush panel seams, countersunk roof fixings, corner splice plates/bolts, restrained edge chips, amber fascia, and underside gussets. The front ladder is a named separate mesh with the same rail/rung geometry across sizes. Reversed middle towers hide that mesh and have no invisible ladder interaction marker. The end ladders remain visible and usable from ground and roof.

`miko8_matched_tower_cel.gdshader` supplies one neutral graphite/steel and muted amber palette, controlled light/mid/shadow bands, local recess relief and shared dark outlines. Imported colour supplies a restricted paint/ink/detail mask, removing the reconstruction-specific hue and uncontrolled baked-light changes. The first flat-colour revision was rejected during our own visual review because it lost structural depth; controlled recess shading and real open bracing replaced that result. MIKO's approved shading and the far city art are unchanged.

## Validation and preview

Open `Preview Tower Course.cmd`, or select Level 2 and walk to X 40 m. Up/W climbs, Space jumps, and Down near either end ladder descends. The last ladder exits facing back into the course by default.

`verify_miko8_platform_tower_course.gd` covers the revised course: consistent measured cap dimensions and ladder widths, exactly two ladder interactions, all four 180-degree rotations, no invisible middle-ladder grabs, support on each roof, native ladder use at both ends, all five gaps in both directions, descending-jump depth continuity, ground recovery and highest-deck camera framing. Structured results and logs are in `Builds/Validation/TowerArtRevision`.

The final functional run passed **88 checks, zero failures**. The headless test reports two retained objects/one resource during process shutdown; there are no script/runtime errors in the route checks. The GPU visual review exits without errors. Reusable shader/material caches remain application-wide. Ladder mounting crossbars connect the visible end-ladder standoffs to both side posts; these decorative receivers do not add gameplay collision.

GPU review uses the actual scene and its normal camera, plus close views of the end ladder and reversed centre pair. `review_miko8_platform_tower_course.gd -- --finish-only` writes `course_overview.png`, `finish_end_close.png` and `finish_reversed_close.png` there. Full review also captures the climb and top exit. Capture FPS figures include image readback/saving and warm-up; they do not measure steady gameplay.

Rollback of the previous tower component/course/test/review scripts is in `Builds/Rollback/Before_Tower_Art_Revision_2026-11-04`; the earlier `platform_towers` assets remain intact. Downloads originals, including the new large file `ChatGPT Image 4 Nov 2026, 23_21_35_Textured_55873101209.glb`, are untouched.
