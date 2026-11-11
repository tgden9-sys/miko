# VanillaLoop ladder trial

Source: https://www.fab.com/listings/5b737d10-b4cd-4294-8f6b-757b9088039d
User supplied freesampleanimationset.unitypackage, downloaded from the publisher after approving the Fab Standard License. Source A_Ladder_Up_Loop.fbx and SkeletonSettings.fbx extracted as data; no Unity code executed.

Run `Try MIKO Stock Ladder.cmd`. This is a separate Godot scene and does not replace gameplay animations. Pause, change camera and scrub with the slider. The candidate uses the source 1.3-second loop, rest-pose retargeting to MIKO's canonical skeleton and proportional root travel. No ladder IK or imposed limb spacing. Existing global 30-degree head lift remains active.

The preview ladder illustrates the movement; exact hand/foot contacts and entry/exit transitions are not integrated. The sampler contains the upward loop, not a complete ladder sequence. Four rendered phases were inspected; finite bone transforms and near-identical loop endpoints checked. Numerical checks do not establish visual quality; user review is the purpose of this trial.

Builder: Source/Character/MIKO8/LadderCandidates/VanillaLoop/build_ladder_trial.py
Sampled motion: Game/models/miko8/VanillaLoop_Ladder_Trial.json
Scene: Game/scenes/miko8_ladder_trial.tscn
Validation: Builds/Validation/MIKO8/ladder_candidates/vanilla_phase_0.png through vanilla_phase_3.png


## Movement demo integration

The approved motion is installed by miko8_stock_ladder.gd into the existing AnimationPlayer as StockLadderUp, StockLadderDown (reversed source loop), and StockLadderHold (mount pose). Gameplay uses phase-matched reversal and freezes the current pose on release. Old wall-climb clips remain for reference; gameplay ladder IK is disabled.

Climb speed comes from source rise/duration (about 0.368 m/s). Rungs use half the scaled cycle rise. Bottom mounting blends for 0.45 seconds. At the top, the character climbs to within 0.45 m of platform level, clears the lip, turns towards the dismount side and blends into Walk over a 1.1-second exit. Collision restores at the safe standing position. There is no dedicated top-exit motion in this sampler; this exit combines the approved climb and existing walk. Re-entry from the top, bottom exit, hold, reverse and jumping off remain supported.

Run Review MIKO8 Ladders and Spells.cmd. Controller: left stick up/down, B jumps off. Keyboard: W/S or arrows, Space jumps off. The Ladder button teleports to the test ladder.

Validation: verify_miko8_stock_ladder.gd exercises mount, climb, hold, reversal, top exit, grounded platform recovery, top re-entry, jump off and bottom exit. Captures demo_top_early/middle/late/standing were visually inspected. Full source animation and spell tests are in verify_miko8_abilities.gd.

Climb tuning: gameplay playback and vertical travel are both 3x source speed (about 1.10 m/s up and down). Bottom approaches use ClimbAlign in a walking pose until centred, then blend to the grab pose. Visual rails and rungs extend 1.5 m above platform level; top_y remains the actual platform floor. verify_miko8_ladder_alignment.gd checks both side approaches and matched ascent/descent speed.

