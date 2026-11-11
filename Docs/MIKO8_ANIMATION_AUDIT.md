# Animation and interaction audit — 27 October 2026

Changes: each new plasma preparation starts at zero elevation in MIKO's current body-facing direction. Subsequent stick input controls aim normally. The test platform's left edge is 18.35 m, clearing the right ladder rail and its radius; floor level is unchanged at 3.2 m. Top entry still walks to the ladder before beginning vertical descent.

Validation completed:
- 34 animation clips, five sampled phases each: finite bone transforms. Contact sheet all_animation_audit.png visually inspected.
- Source import comparisons for 18 climbing/spell clips retained, maximum measured hand/foot error under .000051 m.
- Walk, run and sprint jump/land cycles in both directions; raised-platform landing; clip selector and pause.
- Midair reversal in both directions, neutral braking and landing without drift.
- Jump interruption during a turn: maximum observed heading step 3.72 degrees.
- Ladder climb, hold, reversal, top exit, top re-entry, jump off, bottom exit.
- Top entry: walking first, no lateral translation during descent; walking/grab/descending captures inspected.
- Red targeting releases produce no damaging projectile; plasma releases one travelling bolt and hits once in either direction.
- Plasma start test seeds stale opposite-facing downward aim, then starts R2 facing right and confirms level forward aim.
- Collision probe confirms clear space beside the upper ladder rail.

Logs and captures: Builds/Validation/MIKO8/ladder_candidates/audit_*, audit2_*, final_abilities2.*, all_animation_audit.png, top_entry_*.png.

The older wall-climbing source clips remain as reference previews. Gameplay ladders use the approved VanillaLoop motion.

Landing handoff update: contact plants horizontal movement. Walk/run/sprint starts after 0.05 seconds of contact, and ground speed is restored with that gait rather than during the landing pose. Neutral recovery is .18 seconds. verify_miko8_landing_aim.gd checks no travel during the planted pose and recovery under .09 seconds. Fresh red/blue/plasma targeting now all reset level to body-facing direction; a live red-blue colour swap retains its existing pose and aim.


Current movement handoff: MoveStart plays the authored push-off for run and sprint from rest and after a planted landing. It advances the pose before world travel, then accelerates into the gait. The previously added body glow effects have been removed. Latest validation: verify_miko8_push_off, verify_miko8_wall_block and verify_miko8_landing_acceleration passed. Review via Play MIKO8 Native Animations.cmd or Review MIKO8 Ladders and Spells.cmd.

