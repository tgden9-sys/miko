# Movement pass — 1 November 2026

Rollback snapshot: `Builds/Rollback/Movement_Before_2026-11-01`. The two original runtime scripts and their SHA-256 hashes were saved before edits. Close the game, run `Restore Previous Movement.cmd`, then reopen the preview to restore those exact scripts. This restores movement and ladder timing while retaining the current art, charge/block mechanics and foot correction. The restore script does not touch unrelated files.

## Changes

- Ladder rung clock 2.45 → 4.8; mount/exit clock 1.7 → 2.1. Source animation and root travel still share the clock. The accepted .45-second ladder exit turn remains intact.
- Run first-step ramp .65 → .28 seconds; sprint .8 → .4 seconds. Initial push is 22% of target speed, with a more immediate ramp. Top running/sprint speeds remain source matched.
- Ground 180° turn .20 → .18 seconds, retaining the authored planted-foot turn and current braking.
- A small smoothed forward lean under acceleration, and backward weight shift under braking. These use model rotation rather than changing the collision body; climbing, spell and launcher poses clear the lean.
- Air speed limit 3 → 6 m/s so running jumps preserve momentum. Air acceleration 24 → 18; neutral air braking 28 → 7, allowing a useful coast with steering.
- The existing tight/variable jump mode remains. Tight jumps descend with 1.25× gravity; ascent height and the existing apex treatment are retained. Landing compression scales with impact speed. Buffered jumps can carry through landing.

## Evidence

Follow-up tuning: the user requested a 25% reduction in climbing pace because the animation looked too fast. The current rung clock is **3.6** (4.8 × .75), for both ascent and descent. Mount/exit timing remains 2.1; the other movement-pass settings and rollback snapshot remain intact. The measurements below describe the initial 4.8 trial.

`review_miko8_movement_pass.gd`: run reaches 90% in .267 s, held jump apex 1.355 m, running airborne travel 4.44 m, immediate take-off, moving landing, stopping and reversal checks.

`review_miko8_ladder_pace.gd`: full 5.2 m ladder up/down 5.60 → 3.47 s; sampled rung travel 3.45 → 1.72 s. Supported landing at both ends is checked.

Logs and GPU captures: `Builds/Validation/MovementPass`. These checks cover function and timing; the playable pass is intended for the user's judgement of feel.
