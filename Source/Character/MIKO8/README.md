# MIKO8 native Quaternius rig

Revised source mesh supplied 26 October 2026: `MIKO8_source.glb`. Original download preserved separately. Earlier MIKO7 builds are unchanged.

The mesh is bound to the canonical 53-bone Quaternius Standard skeleton, including articulated fingers. The mesh's A pose, limb placement and boot soles are fitted to that skeleton's T pose during binding. The delivered skeleton retains the source bone names, hierarchy, rest positions, rotations and scale. This is a fitted bind mesh, not a collection of individually repaired animations.

`MIKO8_Native_Animated.blend` is the editable master. `Game/models/miko8/MIKO8_Native.glb` is the Godot export; the matching JSON records source files, original durations and foot/root trajectories.

Included clips: Idle, Walk, Run (Jog), SprintEnter, Sprint, SprintExit, JumpStart, JumpAir, JumpLand, Turn90Left/Right and Turn180Left/Right. Six clips come from the previously downloaded Standard library; seven come from the user's AnimationTemplates ZIPs. Animations by Quaternius, CC0: https://quaternius.com/packs/universalanimationlibrary.html . Template README files are retained as provenance data.

Source keyframes retain their original poses and timing. The supplied normalized node animations are converted into the canonical bone coordinate basis. Their evaluated joint transforms are checked against the source at each 30 Hz sample. Standard actions are checked against a fresh import at 60 Hz, including duration identity. Runtime head, turning and ladder adjustments are described below.

Controller update 27 October: gameplay supplies the missing turn heading progressively and uses anticipation/takeoff/air/landing transition windows through the unchanged jump clips. Full source clips remain available in the selector; turn previews include external heading. See `Docs/MIKO8_NATIVE_ANIMATIONS.md` and `Builds/Validation/MIKO8/sequence_v2` in the project root.

The latest controller also provides faster turns, stick-priority direction changes, tighter ground/landing braking and mid-air facing/steering. A global post-animation SkeletonModifier3D lifts the head 30 degrees in every clip. Source keyframes remain unchanged. G toggles the 96-pixel game-size camera reference. Current checks are under `Builds/Validation/MIKO8/controls_v3`.

The action library now includes 31 clips, with single/double spells and ladder mechanics. `MIKO8_Actions_Animated.blend` is the expanded editable master. A ladder-only IK modifier narrows the wall-climb stance, tucks elbows and points boots into the rungs. Both fitted-ladder and original-wall previews are available. See `Docs/MIKO8_ABILITIES.md` and `Builds/Validation/MIKO8/actions_v4`.

Rebuild order with Blender 5.2: `inspect_source.py`, `build_native_rig.py`, `export_native_clips.py`. `validate_native.py` independently checks Standard source identity. `render_native_review.py` creates pose renders. Validation reports and Godot captures are in `Builds/Validation/MIKO8`.

The generated mesh has irregular topology: Blender's automatic heat weighting failed, so the rig uses explicit anatomical weights and an individually fitted finger layout. The binding and visual silhouette still deserve artistic review; numeric source identity does not certify the appearance of every deformed surface.
