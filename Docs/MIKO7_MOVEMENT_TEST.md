Current build: **v6** includes global head correction, faster walking, smooth jump preparation and rebuilt Sprint. See `Docs/MIKO7_REVIEW_V6.md` in the project root. Earlier details below describe preserved checkpoints.

# MIKO7 controller movement test

Latest update: the movement test now uses the **v4 walk refinement**. For a focused walk-only review, open **Review MIKO7 Walk.cmd**. See `MIKO7_WALK_REFINEMENT.md`. Sprint's motion and 1.30 m/s maximum speed remain unchanged for the next pass.

Open **Play MIKO7 Movement Test.cmd** from the desktop MIKO folder. This runs a separate side-scrolling 3D movement test inside the existing Godot project. The normal Play MIKO.cmd launcher still opens the original game.

## Controls

| Input | Action |
|---|---|
| Left stick left/right, lightly | Walk |
| Left stick pushed fully | Sprint |
| Reverse the stick | Brake, perform a planted turn, then move the other way |
| B (Xbox) / Circle (PlayStation) | Full jump: anticipation/take-off, airborne pose, collision-triggered landing and recovery |
| A/D or left/right arrows | Keyboard walk |
| Shift + movement keys | Keyboard sprint |
| Space | Keyboard jump |
| R / Reset | Return to the starting position |
| P / Pause | Pause/resume |
| Escape | Close the test |

The left stick's vertical axis is unused in this side-scrolling test. The input map has a controller deadzone and supports any mapped joypad device.

## Turns

All four supplied clips are included. **Auto** uses the appropriate 180-degree turn through the front-facing direction. The **Reversal turn** menu also lets you compare the left/right 180-degree clips and two successive left/right 90-degree clips.

Turn yaw and horizontal root travel are sampled from the supplied motion. They are removed from the skeleton bake and applied once by Godot's controller. Horizontal travel goes through collision-aware movement, and the side-scrolling depth remains fixed. Physics owns jump height; the animated soles are aligned to the character's floor reference so animation and physics do not add two separate jumps.

## Animation set

Idle, Walk, Sprint, JumpStart, JumpAir, JumpLand, Turn180Left, Turn180Right, Turn90Left and Turn90Right. Sprint has a **12-degree backward head adjustment** to lift his gaze. Other clips retain their head motion.

The jump's start and recovery clips play faster than their source timings to fit the playable jump. The complete clips are retained in the asset. Walk and Sprint cadence respond to movement speed; transitions blend between poses. The test includes low raised blocks for checking real landings.

## Files

- Scene: `Game/scenes/miko7_movement_test.tscn` (open it in Godot and press F6).
- Current Godot model and motion data: `Game/models/miko7/walk_v4/MIKO7_Locomotion_v4.glb` and `.json`. The v3 pack remains as a checkpoint.
- Editable Blender master and source metadata: `Source/Character/MIKO7/MIKO7_Locomotion_v3.blend` and `.json`.
- Rebuild: `Source/Character/MIKO7/build_locomotion_v3.py`.
- Visual review: `Builds/Validation/MIKO7/v3/review_*.jpg`.
- Godot checks and actual engine captures: `Builds/Validation/MIKO7/v3/godot_*`.

This remains a detailed animation/controls prototype, rather than a replacement for the original game's sprite player or its combat and magnetic abilities.

## Sources

Walk, Sprint, Idle and jump poses: the preserved Quaternius Standard library. Turn clips: the four user-provided ZIPs, preserved as extracted GLBs and their README files under `Source/Character/MIKO7/Turns`. The provided README files identify them as Quaternius CC0 normalized humanoid clips.

- https://quaternius.com/packs/universalanimationlibrary.html
- https://quaternius.com/packs/universalanimationlibrary2.html

The corrected deterministic bake keys complete transforms from independent parent matrices, samples every source frame at 30 fps, and verifies bone lengths, attachments and frame-order independence. Godot's test injects actual joypad axis and B-button events and checks walk, Sprint, the complete moving/standing jump sequence, raised-platform landing, all four reversal options, deadzone and pause behavior.
