# Three levels — revised 4 November 2026

**New supplied tower course:** Level 2 now includes the [six-tower platforming course](MIKO8_PLATFORM_TOWER_COURSE.md) at X 40–54 m. It uses the new small/medium cel-style towers and is separate from the removed early tower/catwalk trial below.

**The tower/catwalk and mantle described in the historical notes below have been removed from the playable game at the user's request.** The comparison crate and tower preview launcher have also been removed. Current Level 2 platforms, pressure switch, canister, camera follow and district corrections are documented in [MIKO8_LEVEL2_PLATFORMS_AND_DISTRICTS.md](MIKO8_LEVEL2_PLATFORMS_AND_DISTRICTS.md).

The extra levels now use straight-sided scenery modules on a continuous forecourt, with an independently framed continuous mid-distance skyline. Level 2 contains the new supplied platform tests; Level 3 remains an empty flat route for future tutorial layout.

## Historical first pass (superseded)

The game now launches Level 1, the existing 80 m Service Yard. The top-left level selector opens Level 2 (Pump Works) or Level 3 (Freight District). Both new levels have continuous flat 80 m routes, the shared camera/ground/city/mid layers, 50% brightness, MIKO's existing shading and movement, and no tutorial obstacles. Near architecture is a new arrangement of reusable 3D buildings: tall separated pump houses in Level 2 and lower, broader freight warehouses in Level 3, using the established cel facade textures and roof equipment. These buildings sit behind the lane and their collisions are disabled. Roof-mounted atmosphere fixtures from Level 1 are not spawned into the empty levels.

The HUD shows level number, X and Y in metres, updated from MIKO's actual world position. Coordinates restart at the same origin in each level. Manual selection is available now; tutorial progression is deliberately left for later layout work.

## Level 1 test route

The supplied ladder tower and catwalk are retained as originals and editable Blender scenes under `Source/Environment/TowerCatwalk`. Each game mesh is reduced to about 64,000 triangles. Their new cel shader preserves surface detail while remapping bright yellow/orange to muted ochre.

Tower ladders: **X 8.0 and X 15.6**, height **3.45 m**. Catwalk centres: **X 9.8 and X 14.0**, with a roughly **1 m gap** between decks. The tower's own visible ladder is used; hidden gameplay ladder markers reuse the established BPG climb and exit animations. Imported deck height was ray-measured at .046635 source metres, so the visible grate aligns with its collision floor. The upper walking lane is Z -.7; this accommodates the existing ladder exit lane. The route is climb → walk → jump gap → walk → descend. Existing buildings, loader and ground route remain.

## Mantle

A separate **1 m crate at X 27.6** provides a size comparison with the existing .8 m crates. Existing puzzle crate sizes are retained. The mantle adjusts its initial body height for either size.

Press jump while pushing against a low crate. Detection requires a nearby rigid-body face, a top .45–1.05 m above MIKO and free capsule headroom. The action uses the existing **ClimbLedge** animation, with body rise delayed until after its hand-plant phase and a blend to standing at the finish. Source hip travel is cancelled before controlled root movement to avoid double movement. No new limb poses were generated. Both facing directions work. Movement of the supporting crate aborts the mantle; reset/interruption restores collision and pose state. Tall crates and obstructed tops reject the mantle and leave normal jumping available.

## Review

`Preview Three Levels.cmd` opens the game with the selector. `Preview Tower Catwalk.cmd` starts beside the first tower. `review_miko8_three_levels.gd` tests all three scenes, HUD coordinates, flat unobstructed new levels, both mantle directions, tower ascent, actual gap jump and landing, and descent. Logs and GPU captures are in `Builds/Validation/ThreeLevels`.

The pre-change runtime scripts and project settings are preserved in `Builds/Rollback/Before_Three_Levels_2026-11-04`. Original uploaded GLBs are unchanged in Downloads and preserved as source copies in the project.

