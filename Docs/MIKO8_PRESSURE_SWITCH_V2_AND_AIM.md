# Sealed pressure switch, charge guides and gravity — 4 November 2026

## Reusable 3D switch

The approved concept is saved as `Concepts/pressure_switch_sealed_v2.png`. Its exact built-in image-generation prompt and the approved green/purple follow-up are in `Source/Environment/PressureSwitchV2/design_prompt.md`.

`Game/scenes/reusable_pressure_switch.tscn` includes the exported 3D model for editor placement and adds runtime interaction. The GLB has independent base and plunger nodes, fewer than 1,800 triangles and approximately 130 KB. Editable source and the reproducible builder are in `Source/Environment/PressureSwitchV2`. No Trellis conversion is required. The previous supplied pressure GLB remains preserved.

The unit is 2.4 × 2.0 m, with a 1.7 × 1.28 m centre panel and 2 cm travel. A continuous backing and overlapping metal skirt close the moving seam at both heights. Broad collision slopes continue underneath the panel: there is no exposed pit or upright inner collision lip to catch a crate leaving a depressed plate. Contact margins are cleared on entry. Bolts, a pressure-arrow emblem, lit centre border and front/rear bevel indicators make the unit readable from the low gameplay camera.

**Ready is green; pressed is purple.** The centre symbol, border and indicator windows change together; a restrained purple perimeter glow pulses while weighted and fades on release. MIKO and movable crate weight activate it. Puzzle outputs remain unassigned. The Level 2 example is at X 12 m.

## Red/blue guide repair

The first width-only repair was incomplete: the user identified the guide being rendered behind painted scenery. Guides, halo and motes now explicitly disable depth testing and use elevated transparent render priorities, so the scenery cannot cover the aiming overlay. World raycasts still determine the first real collision and clip the guide endpoint. The camera-facing ribbon retains its stable screen width and live hand endpoints. Red and blue charge on actual projectile contact; release clears old guide state.

`verify_miko8_repeat_charge_guides.gd` exercises four alternating red/blue charges, holds and free aiming between them, endpoint validity, width, colour, depth-overlay flags, projectile contacts and release cleanup. A dedicated GPU case places an opaque-looking transparent scenery card in front of the shot and checks rendered pixels for the blue guide over it. Evidence: `guide_occlusion_test.log`, `repeat_guides.json`, and `guide_over_scenery.png` under `Builds/Validation/Level2Props`.

## Gravity rule

Ordinary continuous suit-to-crate and crate-to-crate magnetic forces act horizontally. Following the user's clarification, the initial upward/outward repulsion kick is retained: 2.97 m/s for side-by-side crates and 13.45 m/s for the upper crate in a stack. These are one-shot velocities with the existing breakaway cooldown, not sustained vertical forces. Gravity then brings the crates back to the floor, and the lateral speed cap does not reduce falling speed. Explicit downward-facing ceiling-pad `apply_lift()` remains the sustained vertical-lift exception; neutralising the pad or crate releases its load. Mutual nearest-neighbour connections and the R–B–R rule remain unchanged.

`verify_miko8_gravity_dominant.gd` covers raised ordinary attractors, falling under an elevated suit, initial side/stack repulsion kicks followed through their rise and landing, explicit ceiling lift and drop, and preservation of falling speed when horizontal velocity is capped. Results are in `repulsion_arc.log` and `gravity_dominant.json`. The ceiling lift reached approximately 3.176 m before release. `review_miko8_block_connections.gd` also passed after the continuous-force change.

## Verification and source preservation

The complete walk-on/drag-on/drag-off, stack, crouch and camera pass completed **36 checks, zero failures** in `pressure_v2_final_physics.log` / `walkon_stack_crouch.json`. GPU switch views are `pressure_v2_game_ready`, `pressure_v2_game_pressed`, `pressure_v2_asset_ready` and `pressure_v2_asset_pressed`. The tutorial banner is hidden in those captures to show the complete scene edge.

Pre-change runtime scripts are preserved in `Builds/Rollback/Before_Aim_And_PressureV2_2026-11-04`. The scene’s existing character shading, skyline tone, platform layout and crouch controls are retained.
