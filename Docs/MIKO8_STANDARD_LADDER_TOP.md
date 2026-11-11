# Standard facing-away ladder animations

Status: the user rejected these generated top transitions after visual review.
The numerical checks below establish contact/controller behavior only, and do
not establish acceptable animation quality. A direct publisher FBX pack with
16 clips has since been downloaded and inspected under
`Source/Character/MIKO8/LadderCandidates/BPG_FBX/`; it includes full-body top
entry/exit motion and does not require Unreal to import into Blender. It has
now replaced this generated pair in the scene. Current implementation and
controls are documented in `MIKO8_BPG_LADDER.md`. The rest of this document
records the superseded experiment.

The service-yard ladder now uses two new baked clips on MIKO's existing rig:

- `LadderTopOut`, 1.50 seconds: climb the last rungs, plant the left foot on the rear landing, bring the right foot up, release the rolled rails and turn right onto the walking platform.
- `LadderTopIn`, 1.60 seconds: turn back toward the rails, step onto the rear landing, take the hand grips and lower each foot onto the rungs. This uses the same fitted contact sequence in reverse, with separate timing and a separately baked clip.

The existing up/down loops still handle the ladder shaft. Bottom entry remains immediate. Holding up reaches the exit clip automatically. At the top, press down within 0.24 m of the worn landing mark to begin the return. Releasing input holds a rung once the top transition completes. Jump detaches; reset safely cancels either transition.

## Matched geometry

The example is a 3.20 m ladder at x18.30, with rolled handrails 0.95 m above the landing and no rungs above the floor. Its rear landing extends behind the ladder, leaving room for the feet to clear the edge. The main walking deck starts 0.40 m to its right. The exit finishes at x19.06, z0, on the original walking lane.

The pose and root-motion curve are authored together for this arrangement. Different shaft heights can reuse the pair by keeping the same top geometry and triggering it 0.95 m below the top. A different rail width, landing arrangement or mirrored exit needs a fitted variant; changing the whole ladder's scale is not an animation retargeting method.

## Editable sources and runtime

- `Source/Character/MIKO8/MIKO8_LadderTop_Animated.blend`: both editable bone actions on the actual character rig, baked at 30 fps. The object motion and pose correspond to the runtime curves.
- `Source/Character/MIKO8/MIKO8_LadderTop_Review.blend`: the same rig with a simple ladder/landing stage and review cameras.
- `Source/Character/MIKO8/build_ladder_top_transitions.py`: reproducible authoring, contact solving, baking and JSON export.
- `Source/Character/MIKO8/render_ladder_top_transitions.py`: renders the staged review angles.
- `Game/models/miko8/MIKO8_LadderTop.json`: baked bone samples, root motion, standard dimensions and diagnostic contacts.
- `Game/scripts/miko8_ladder_top_library.gd`: installs the bone clips into the existing AnimationPlayer.
- `Game/scripts/miko8_ladder_top_motion.gd`: synchronizes the root curve, facing and pose, and hands control back to climbing or walking.

Only ladders carrying `standard_top_transition` use the new top pair. The accepted character GLB and other character actions are unchanged.

## Preview and verification

Launch `Preview Ladder Top Animations.cmd`. It starts beside the ladder with a 7.5 m camera view for inspection. The normal side-on preview retains its 15 m framing.

`Game/scripts/review_miko8_ladder_top.gd` drives actual inputs in the real scene. It checks immediate bottom grab, both top clips, grounded walking, rejection of distant down input, rung hold, descent, reset/jump interruption and approach from either facing. It also compares animated bone positions with the authored contacts and casts rays onto the real landing collision beneath planted feet.

The OpenGL run passed with zero failures. Across 312 measured contacts the maximum hand deviation was 3.26 cm and foot deviation 1.11 cm. All 75 measured roof foot plants had supporting collision. The contact measurement excludes the short initial/final blending intervals. Reports, game captures and staged renders are in `Builds/Validation/LadderTransitions/`.
