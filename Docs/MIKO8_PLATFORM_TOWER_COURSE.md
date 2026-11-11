# Platform tower course — 4 November 2026

**Superseded art/layout:** the [matched three-size revision](MIKO8_TOWER_ART_REVISION.md) now includes the large model, equal cap/ladder dimensions, common cel materials and reversed middle towers with ladders visible only at the two ends. The first-pass evidence below is retained as history.

Level 2 (Pump Works) now includes a six-tower climbing/jumping course beyond the existing platform stacks. Start it directly with `Preview Tower Course.cmd`, or select Level 2 and walk to X 40 m.

## Layout

| Tower | X | Supplied model | Deck height |
| --- | --- | --- | --- |
| 1 | 40.0 m | Small | 2.80 m |
| 2 | 42.8 m | Small | 2.80 m |
| 3 | 45.6 m | Medium | 3.65 m |
| 4 | 48.4 m | Medium | 3.65 m |
| 5 | 51.2 m | Small | 2.80 m |
| 6 | 54.0 m | Small | 2.80 m |

The visible cap width is 1.8 m; smooth deck support is 1.65 m wide, leaving approximately 1.15 m gaps between collision edges. The step up/down is .85 m, within the existing normal jump. All towers have their own ladder, allowing recovery from a missed jump. There is no invisible bridge across the gaps and no mantle or powered jump is required.

Use W/Up to climb and Space to jump. Down near the upper ladder entry descends. The existing ladder animation, speed and exit-turn timing are retained.

## Assets and style

The two uploaded GLBs were identified by proportions rather than attachment order:

- Small: `ChatGPT Image 4 Nov 2026, 23_20_56_Textured_55872101207.glb`.
- Medium: `ChatGPT Image 4 Nov 2026, 23_18_27_Textured_55870101204.glb`.

Downloads originals are untouched. Copies, editable Blender files and the reproducible preparation script are in `Source/Environment/PlatformTowers`. Runtime copies are in `Game/models/environment/platform_towers`.

The source cel-painted grey steel and amber details are retained. Shared three-tone scene lighting and the existing restrained ochre remap integrate them with the yard. The small reconstruction had a roughly 2.7-degree front/back pitch in its cap; a local upper-cap correction levels the landing while leaving its feet upright. Static smooth deck collision follows the resulting painted top; decorative screws, rough edges and rung holes do not snag MIKO. A soft ground contact patch sits beneath each tower.

The small model reduced from 190,075 to 49,999 triangles and 20.07 MB to 7.39 MB. Medium reduced from 274,918 to 50,000 triangles and 22.69 MB to 7.50 MB. The original 2048 px base-colour maps remain, while unused normal and metallic/roughness maps are removed from runtime copies. Models and materials are reused between instances, and the existing camera visibility budget culls off-screen tower visuals.

## Interaction and collision

`miko8_platform_tower.gd` assembles each asset, deck/body collision, contact patch and interaction marker. The imported visible ladder remains the only visible ladder. `miko8_tower_course_ladder.gd` inherits ladder properties and registers interaction without constructing a second ladder.

`miko8_platform_tower_course.gd` contains the six placements. MIKO's elevated walking depth must persist when jumping from the high pair onto the lower pair: within the course, the ground-return threshold is the lowest deck height. Passing below all decks still restores the ordinary ground depth through the existing actor logic. This does not change MIKO's global movement or animation scripts.

## Validation

`verify_miko8_platform_tower_course.gd` passed **71 checks, zero failures**: ground approaches without jumping, three deck-support samples on every tower, real native ladder ascent/descent on all six towers, all five normal-jump gaps in both directions, elevated depth continuity, missed-jump ground recovery, highest-deck camera framing, and presence of the existing platform/switch/canister content.

Results: `Builds/Validation/PlatformTowers/course_checks.json`. Asset counts/measurements: `asset_report.json` in the same directory. `review_miko8_platform_tower_course.gd` produced GPU captures of the overview, ground approach, both climbing poses, top exits and standing foot support; these were inspected. Capture frame-rate figures include loading/image-saving overhead and do not establish steady gameplay performance.

The existing `verify_miko8_walkon_stack_crouch.gd` regression pass also completed **36 checks, zero failures**, covering the earlier switch/crate/platform/crouch/camera interactions. Run logs are `existing_interactions.log` and `existing_interactions_err.log` in the tower validation directory; the structured result remains `Builds/Validation/Level2Props/walkon_stack_crouch.json`.

Rollback of the level hook: `Builds/Rollback/Before_Platform_Tower_Course_2026-11-04/miko8_side_on_mockup.gd`. The new course scripts/assets can remain unreferenced when that file is restored. Existing MIKO shading, jump settings, ladder speed, far city artwork, scenery brightness, pressure switch, canister and earlier platform stacks were preserved.
