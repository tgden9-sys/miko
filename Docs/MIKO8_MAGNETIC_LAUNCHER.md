# MIKO charge states and launcher

The side-on yard enables MIKO's existing suit polarity controls and movable metal crate physics. The fixed charge base stays anchored. Stationary objects never apply attraction or repulsion to MIKO; there is no magnetic wall attachment.

## Controls

- Hold Q / E (controller LB / RB) to aim a red / blue charge; release to fire the charge bolt at an object.
- 1 / 2 / 0 selects MIKO's red / blue / neutral suit. C cycles the states. Controller Y / X toggles red / blue, including neutral on a second press.
- Opposite charges attract movable crates toward MIKO. Matching charges repel them. Charged crates also interact with other charged targets through the original crate force code.
- Walk through the middle of a charged launcher with the opposite suit charge to brace both hands on its cap tops. No passive pull, forced approach or horizontal centering is applied to MIKO.
- Change the suit to match the launcher to perform the brief jump compression and upward release. Take-off speed is `6 * sqrt(2)` m/s, giving twice normal height under the existing 14 m/s² gravity.
- Neutral, movement or Space disengages the hold; Space transitions to a normal jump. The post-launch cooldown prevents repeated launches on landing.
- R restores crates to their authored positions and clears target/suit charges.

## Art and animation

The loader retains its length and height, with depth scaled to .56 (X/Y .8) so the robot can physically reach both cap tops. Hand targets were measured against the actual mesh, rather than the old approximate collision marker. The palms are planted using two-bone arm IK in a SkeletonModifier3D while the source idle and jump clips drive the body and legs. Both travel directions are supported. There are no mesh stretches or edited source clips. A short pair of energy rings marks take-off; MIKO has no trail.

Main runtime files: `miko8_launcher_motion.gd`, `miko8_launcher_pose.gd`, `miko8_loader_charge.gd`, `miko8_suit_polarity.gd`. The feature is enabled by the side-on scene; older movement test scenes retain their previous controls.

## Validation

`review_miko8_magnetic_launcher.gd` runs against the actual side-on scene. GPU validation: `Builds/Validation/Launcher/walk_in.log` and `walk_in_error.log` (empty). Final headless validation: `final_physics.log` / `final_physics_error.log`. Tests cover suit keyboard events, a released red projectile charging the loader, free-crate attraction and repulsion, fixed-base immobility, no passive force on MIKO from a base or launcher, walking into the brace, ground contact, cap reach, both directions, movement/neutral/jump detachment, launch height, no repeated launch and reset. Existing rooftop bridge and ladder regression also passes (`bridge_regression.log`, zero gaps, 33 painted ladder parts).

Measured world apex: normal 1.337 m, boosted 2.644 m; ground is approximately .1 m. Both follow the same gravity and source movement controller. Maximum right-hand/left-hand target error at the tested brace: .0152 m. GPU captures: `brace_right.png`, `brace_left.png`, `launch_right.png`. Close inspection views are temporary test cameras; normal gameplay remains at the approved 15 m orthographic size.
