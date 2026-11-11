# MIKO8: spells and ladders

The current review uses a 3D model and world with side-on X/Y movement (Z remains on the gameplay plane). This is the proposed 2.5D direction: retain the platformer's simple navigation while using the live rig, turning and lighting. The original sprite-based industrial-city scene is preserved; this pass ports its ladder interaction to the revised character's review scene.

Open **Review MIKO8 Ladders and Spells.cmd** to start beside the ladder, or use **Play MIKO8 Native Animations.cmd** for the normal starting position. The existing movement, B jump, global head lift and G game-size option remain available.

## Ladder

Click **Ladder** to move to the review ladder, or travel right to x=18. The ladder leads to a 3.2 m platform.

- Left stick up/down, or W/S / arrow up/down: mount, climb and descend.
- Release vertical input: hold position with ClimbIdle.
- Continue upward: pull onto the upper platform.
- Stand near the platform edge and press down: reverse the ledge transition to mount from above.
- B / Space: jump away, retaining air steering.
- Descend to the bottom: release the ladder and return to walking.

The actor uses explicit mount/hold/climb/dismount states. Scripted ledge transitions temporarily suspend world collision, then restore the normal mask when safely on the platform or ground. Source hip displacement is consumed during the scripted transitions so it is not applied twice. The original 2D ladder's mount, hold, ascent/descent and jump-off behaviours are retained in the 3D version.

The source loops have a wide wall-climb stance. A ladder-only SkeletonModifier3D now solves narrower hand/foot targets: feet approximately 0.23 m apart, hands 0.51 m apart, tucked elbows and knees bending forward rather than outwards. Boots point into the rungs. It blends in/out at mounting and dismounting; it does not change walking or source keyframes. The review menu includes both “ladder fit” and “original wall climb” versions. Sampled up/down/idle poses keep knee spacing below 0.22 m and joint attachment error below 0.000001 m.

Ascent speed matches the loop's planted-foot travel (about 0.815 m/s). Descent slows both the animation and movement to 75%, keeping them synchronized.

## Spells

- LT / Q: single-hand spell.
- RT / E: double-hand spell.
- Hold to enter and prepare; release to shoot and recover.
- B cancels preparation into a jump.
- The stick chooses facing while preparing a spell.

Single casts emit one projectile from the forward hand; double casts emit one from each hand. Both use the rig's actual hand positions. The blue targets at x=-10 and x=10 register projectile hits without blocking movement. The review HUD displays shot and hit counts.

## Assets

The 18 new Quaternius template clips are appended to the accepted 13-clip rig. The review selector exposes all 31 clips, including additional 1 m / 2 m climbing and root-motion variants for later use. Ladder gameplay uses ClimbEnter/Idle/Up/Down/Exit and ClimbLedge; mounting and dismounting use responsive playback windows. Source keyframes remain unchanged.

Editable master: `Source/Character/MIKO8/MIKO8_Actions_Animated.blend`. The earlier native master remains as a checkpoint. The Godot model and metadata retain the existing `Game/models/miko8/MIKO8_Native` paths. Rebuild with `extend_action_library.py` after the accepted native rig exists.

Source conversion reports, engine tests and captures are in `Builds/Validation/MIKO8/actions_v4`.

All 18 additions pass source-basis conversion and engine hand/foot trajectory checks (maximum imported deviation about 0.05 mm). Controller tests pass single/double casting and target hits in both directions, ascent/hold/descent, top mount/dismount, bottom release, jump-off, charge cancellation, collision restoration after reset, and the existing movement/jump regression. The ladder-specific pose solver also passes reach/attachment and stance-width checks across sampled idle/up/down cycles.
