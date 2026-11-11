# Platforms and district corrections — 4 November 2026

**New tower course:** Level 2 now has six matched small/medium/large towers at X 40–54.5 m, with normal-jump gaps, heights 2.8/3.55/4.3 m, and front ladders only at the two ends. See [current tower art/layout and validation](MIKO8_TOWER_ART_REVISION.md). This is separate from the removed historical ladder-tower/catwalk trial mentioned below.

**Latest switch revision:** the supplied recessed switch is now replaced by the approved sealed 3D plate, with green ready / purple pressed indicators and no exposed recess. See [current switch, aim-guide and gravity follow-up](MIKO8_PRESSURE_SWITCH_V2_AND_AIM.md) for current dimensions and validation. Earlier supplied-switch details below are retained as iteration history.

Three levels remain accessible from the top-left selector. All routes are flat, 80 metres long. X/Y coordinates remain in the HUD and scenery brightness defaults to 50%.

## District scenery

Levels 2 and 3 now use exact rectangular wall geometry instead of stretching the generated bevelled building mesh. All wall bases overlap the ground slightly. A continuous paved forecourt extends from the walkway beneath the scenery, including Level 3's previously exposed gap. Corner piers, coping, textured roof surfaces and roof exhausts complete the modules. Existing cel facade artwork is retained. Pump Works has taller separated units; Freight District has lower, broader warehouses.

The mid-distance image is replaced by a continuous industrial skyline, with its own dimensions and vertical framing. It spans the camera travel and remains visible above the near buildings. Its shader repeats horizontally, clamps vertically to avoid a line across the sky, and extends the opaque lower wall band below courtyard sightlines. The far bokeh artwork is retained. Floating foreground cable cutouts are no longer spawned into Levels 2 and 3.

Follow-up: the two unsupported overhead cable cutouts have now also been removed from Level 1; the three ground-mounted foreground fixtures remain. The mid-distance shader reduces blue saturation by blending 42% towards a near-neutral luminance, adds a subtle warm bias, and lowers its gain to .78. The 50% scenery control remains independent. Camera checks at ground, 2.83 m and 5.2 m confirm the floating cable is absent; captures are `toned_level*_height*.png` in the validation directory.

## Level 2 layout

| Part | X position | Details |
| --- | --- | --- |
| Pressure switch | 12 m | Enlarged floor installation, approximately 2 m wide, with a 1.09 m centre. Shallow approach slopes let MIKO walk and crates slide onto it. Centre travels 2.6 cm, activates purple panel light/perimeter pulse, and returns/fades when unloaded. Housing stays fixed. No puzzle output assigned yet. |
| Switch test crate | 14 m | Existing neutral movable magnetic crate. |
| Two solid-end lower platforms | 25 m and 30 m | Adjacent 5 m sections, 2.2 m deep, deck support at 2.63 m. Actual end-wall collision retained. |
| Two open upper platforms | 25 m and 30 m, base at 2.63 m | Directly stacked over the lower units, roof support at 5.26 m. Both long-axis passages on the middle storey are clear. All four modules use cooler steel-grey cel materials. |
| Crate steps | 20/21.05 m | A single .8 m crate followed by a double stack. Standard jumps reach the middle landing without mantling. The upper roofs are retained for future traversal/puzzle layout. |
| Canister | 30 m, middle storey | Turned upright 90° and reduced to half its previous linear size (.24 source scale). Bobs 7.5–16.5 cm above the deck, with turquoise energy bands, soft middle glow, orbiting motes and a grounding shadow. Collection hides all effects; R restores them. No reward rules assigned yet. |

Runtime meshes are approximately 64k triangles each. Originals, inspection/preparation scripts and editable Blender scenes are preserved under `Source/Environment/Level2Platforms`. The pressure asset's actual centre has been separated from the original mesh; it is not a replacement cube or a moving whole housing. All runtime props receive the shared cel material conversion.

## Movement and camera

Mantling and the tower/catwalk test route are disconnected from the actor and level. Original source assets remain preserved. Jumping is the normal jump animation.

Ground framing places the feet row at 86% of the viewport height, closing the exposed bottom gap without relying on the tutorial banner. The first 3.1 m of height fit within this low framing: a single-storey ladder retains the visible ground. Above that allowance, the camera tracks actual feet height through ladder root travel and higher jumps with a .35 m deadband and damped follow. The basis that keeps the walkway horizontal is retained.

Holding Down for more than a short tap eases the view up to 1.5 m lower from higher floors. It clamps to the established ground framing, so it cannot reveal space beneath the level. Releasing returns the camera smoothly. Ladder travel takes precedence over the look-down input.

## Crouch

Hold **S / Down / left-stick down** to enter crouch. Move horizontally while holding it for the supplied forward loop; release to play the exit. Near an upper ladder landing, Down descends instead. A 1.2 m crouched capsule restores to 1.8 m only with standing headroom; if blocked, MIKO remains crouched and can move clear. Reset restores the standing collision.

The three uploaded Quaternius crouch ZIPs are preserved in `AnimationTemplates`, with extracted GLBs under `Source/Character/MIKO8/Templates/Crouch`. `build_crouch_library.py` uses the existing native coordinate conversion, with source pose matrix checks below 4e-6. Outputs are `MIKO8_Crouch_Rig.blend` and runtime `MIKO8_Crouch.json`; the accepted character meshes and existing clips were not re-exported. Idle holds the source enter clip's final pose because no idle clip was supplied. Enter and exit play at 1.5×; movement uses the source-derived .713 m/s foot travel, up to 1.25×, with analogue pacing and matching animation speed.

## Review and rollback

`Preview Three Levels.cmd` opens the selector. `Preview Level 2 Platforms.cmd` starts beside the first crate steps. The obsolete tower preview launcher has been removed.

`verify_miko8_walkon_stack_crouch.gd` checks walking onto the switch from either direction, magnetic crate dragging, purple activation/release, all four stack units and both floor heights, natural crate-step jumps, middle-storey passage and collection, crouch entry/movement/exit, blocked standing, camera look-down boundaries and return, first-storey ground visibility and both real ladder climbs. Results are in `Builds/Validation/Level2Props/walkon_stack_crouch.json`. The previous test entry point delegates to this updated pass. GPU captures hide the tutorial banner to verify the entire lower edge; key views are `ground_no_banner`, `first_landing_ground_visible`, `switch_walkon_purple`, `two_storey_stack`, `crouch_hold`, `crouch_forward` and `stack_upper_look_down` in the same directory.

The pre-pass actor and level script backups are in `Builds/Rollback/Before_Level2_Props_2026-11-04`. Earlier three-level source backups remain separately preserved.

The updated functional pass completed all 34 checks with zero failures. It caught and resolved a small collision-margin lip that could stop a slowly dragged crate at the plunger. The crate now crosses the recessed approach and holds the switch without being lifted or pulling MIKO. Previous 32-check evidence is retained as historical data for the earlier layout.

This pass is backed up under `Builds/Rollback/Before_Switch_Stack_Framing_2026-11-04`; restoring those scripts returns the prior platform/switch/camera layout and removes crouch runtime wiring.

Performance isolation on the earlier two-unit layout initially recorded low frame rates in unfocused capture runs. Its foreground repeat (low-processor mode disabled for measurement) measured approximately 60.5 FPS for Level 2 and the existing Level 1 at 1600×900 window / 1334×750 render size. Logs: `performance.log` and `performance2.log`. The later four-unit follow-up varied with desktop state: 27.5 FPS for both the full scene and with all four props hidden, versus 14.5 FPS for Level 1 (`stack_performance.log`). These short samples do not establish a locked frame rate or isolate a new prop-related regression. No permanent uncapped or low-processor setting was added to gameplay.
