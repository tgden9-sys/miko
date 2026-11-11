# MIKO8 — native animation review

Open **Play MIKO8 Native Animations.cmd** in the project root. This is a separate Godot scene; the original game and MIKO7 checkpoints are retained.

## Play

- Left stick horizontal: slight tilt walks, medium tilt runs, full tilt sprints.
- B on Xbox / Circle on PlayStation: jump, with start, airborne and landing clips.
- Reverse the stick: brake and turn. The menu selects either supplied 180-degree turn or two supplied 90-degree turns.
- Keyboard: A/D or arrows run, Ctrl walks, Shift sprints, Space jumps.
- R resets; P pauses; G or **Game size: 96 px** toggles close-up/game-size reference. Camera angle switches side/three-quarter; Escape closes.

The clip selector offers all 13 complete animations at their original 1× timing. Select **Controller play** to return to gameplay. Gameplay uses shorter transition windows through the jump clips; the complete source files remain intact.

## Rig and animation policy

The revised single mesh is fitted and skinned to the canonical Quaternius skeleton, including fingers. Its bind pose is adapted from A pose to the source T pose. The supplied normalized node animations require a coordinate-basis conversion into the canonical skeleton; their source joint motion is retained. No source keyframes have been rewritten.

Movement speeds are derived from the source foot trajectories: walk about 0.96 m/s, run 5.22 m/s and Sprint 7.87 m/s. Collision response, heading and transitions are game logic, separate from the animation data.

## Sequence update — 27 October

The normalized turn files do not contain the full final root heading. Gameplay now supplies a progressive 90/180-degree heading change synchronized with the clips' foot activity, with blended entry/exit. Two 90-degree clips accumulate heading continuously. Auto chooses the turn direction that shows the face to the camera. Turn previews in the selector include the same external heading and are labelled “1× + heading”; the source bone animation remains unchanged.

Jump now gathers briefly into the source crouch, launches near the initial extension, and blends the first 0.32 seconds of JumpStart into JumpAir. It preserves incoming horizontal momentum. A downward ray starts the landing blend shortly before contact; recovery returns to the requested gait after contact rather than waiting through the whole quiet tail of JumpLand. Jump anticipation and recovery are selected playback windows, not edited source animation. Sequence captures, the prior controller checkpoint and validation are under `Builds/Validation/MIKO8/sequence_v2`.

## Responsive controls and global head lift

Stick direction now takes priority during stopping and can cancel an unfinished turn. Gameplay turns play in about 0.30 seconds for a 180, or 0.18 seconds per 90; turn previews retain original 1× playback. Ground stopping uses stronger deceleration and a shortened exit window. Landing grips on contact and blends back to the requested gait sooner.

Air control now turns the visual toward the requested direction, accelerates/reverses at 24 m/s², and brakes at 28 m/s² on stick release. The jump pose clips remain in use during air steering; grounded turn footwork is not played in the air.

`miko8_head_offset.gd` adds a single 30-degree head lift through a SkeletonModifier3D after animation playback, in both play and clip review. It applies to every clip without baking changes into source files. The modifier is checked for accumulation while paused.

The Game size button (G) uses a 96-pixel reference height on the project's 1080p canvas; the camera zoom changes rather than the character/collider scale. Click **Detail view** to return to close-up.

`Builds/Validation/MIKO8/controls_v3` contains the current control, air steering, head lift and camera checks plus captures. The tested Run/Sprint stopping distances are about 0.44/1.17 m. Releasing the stick in the tested running jump produces no further horizontal slide after contact. Earlier source-fidelity reports remain the baseline for the unchanged animation assets; the global head lift is an intentional runtime offset.

## Files

- Editable rig and actions: `Source/Character/MIKO8/MIKO8_Native_Animated.blend`.
- Godot mesh, skeleton and clips: `Game/models/miko8/MIKO8_Native.glb`.
- Source provenance, timings and motion tracks: matching `.json`.
- Scene and controller: `Game/scenes/miko8_movement_test.tscn`, `Game/scripts/miko8_actor.gd`.
- Source-identity reports, engine comparison, captures and controller tests: `Builds/Validation/MIKO8`.

Animations are from [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html), CC0, including the seven ZIPs supplied in AnimationTemplates.

The model's generated topology required explicit anatomical skinning because automatic heat weighting failed. Numeric checks establish source motion and transform integrity; the character's appearance in motion still needs your review.

## Validation results

The six Standard actions match a fresh source import at 60 Hz, with maximum world-matrix element error below 0.000006. The seven supplied templates match their original joint transforms at every 30 Hz sample, below 0.000003 matrix error. Original durations are retained.

After disabling Godot's animation optimizer and compression for this asset, every joint position in all 13 imported clips matches the Blender export reference within 0.0000034 m at the sampled frames. Seek-history and unit-scale checks pass. Injected controller events verify the three gait speeds at 1× playback, stopping, all four turn options, and complete standing jumps in both directions (about 1.34 m physical height).

The transition test also passes jumps from Walk, Run and Sprint in both directions, landing on a raised block, and clip-selector/pause/return-to-play controls. Reports: `godot_validation.json` and `transition_validation.json` under `Builds/Validation/MIKO8`.
