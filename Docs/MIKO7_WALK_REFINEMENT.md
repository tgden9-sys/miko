Current build: **v6** includes global head correction, faster walking, smooth jump preparation and rebuilt Sprint. See `Docs/MIKO7_REVIEW_V6.md` in the project root. Earlier details below describe preserved checkpoints.

# MIKO7 walk refinement — v4

Open **Review MIKO7 Walk.cmd**. The left stick walks at any tilt, including full tilt; Sprint is disabled only in this focused review. A/D and the arrow keys also walk. Reset, camera angle, pause, turns and jump remain available.

The regular **Play MIKO7 Movement Test.cmd** now uses the refined walk too. Sprint, jump and turn animation poses are unchanged from v3. Sprint's bounce and movement speed are deliberately left for a separate pass.

## What changed

- Replaced the walk's per-frame whole-body floor correction with a steady pelvis and two-bone leg solves.
- Lowered the swing-foot clearance to 26 mm, with gentle heel/toe rolls and explicit planted-foot intervals.
- Reduced torso sway while retaining the arm swing and average posture.
- Matched a one-second gait cycle to a nominal 0.45 m/s walk. Controller speed scales the cadence by the same ratio, including deceleration.

Measured in Blender: hip vertical travel reduced from 30.3 mm to 2.0 mm; head travel from 30.8 mm to 2.3 mm. The rendered Godot walk measured approximately 2.0 mm at the head and less than 0.05 mm of planted-foot drift per physics frame. These are technical checks; the walk's sense of weight still needs visual judgement.

## Files and checks

- Editable master: `Source/Character/MIKO7/MIKO7_Locomotion_v4.blend`.
- Engine model and data: `Game/models/miko7/walk_v4/MIKO7_Locomotion_v4.glb` and `.json`.
- Build: `Source/Character/MIKO7/refine_walk_v4.py` (starts from the preserved v3 master).
- Checks: `validate_walk_v4.py`, `Game/scripts/verify_miko7_walk.gd`, and the existing movement regression check.
- Measurements and engine captures: `Builds/Validation/MIKO7/v4`.

The bake validation confirms that the other nine animation poses match v3 exactly, and that the walk's bone lengths, attachments and loop remain valid.
