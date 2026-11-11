# Supplied FBX ladder set on MIKO

The service-yard and movement-review ladders now use BP Games' supplied FBX
animations. The rejected generated top pair is no longer installed on MIKO.
The older VanillaLoop remains loaded for legacy clip comparison, but these
two gameplay ladders select the BP Games controller.

## Included motion

All 16 source clips are retargeted and available in the movement-review clip
selector: bottom entry; bottom exit left/right; climb up left/right; climb down
left/right; idle left/right; top entry; top exit left/right; and four look poses
(centre, down, left, up). Runtime uses the closest left/right starting pose for
each step or exit. It uses the actual separate descending clips.

Hold W/up to mount, climb and get off onto the upper floor. At the ladder's
landing mark, hold S/down to get back on and descend. Releasing input lets the
current short step finish, then plays the matching idle. Space detaches.
While holding a rung, I/K/J or the right stick chooses the supplied up/down/left
look pose; neutral returns to centre. The look selection applies neck/head
motion while retaining the supported lower-body pose. Reset cancels safely.

The pack plays at 1.70 times source speed, with root movement using the same
clock. Step travel and vertical acceleration come from the FBX curves. No new
limb choreography or procedural ladder IK is added. The global head lift is
disabled during these motions and restored afterwards.

After either dismount, MIKO uses his existing left/right 90-degree turn clip
for a 0.45 s planted turn before walking. The held movement direction selects
left or right; neutral uses the ladder's dismount side. Heading follows the
turn clip's foot activity, and the pose and heading share the same timing.
`verify_miko8_ladder_exit_turn.gd` checks both directions and neutral, the
continuous heading, synchronized pose clock and grounded collision.

## Upper-floor access

The upper floor is still at 3.20 m. The ladder ends at that height, without
additional climbable rungs above it. The supplied top exit pulls the body over
the edge and steps forward onto the rear landing. The source transition adds
about 1.63 m of vertical root travel; it begins before the body reaches the
upper floor, rather than making MIKO climb above the roof first.

The rails are fitted to the imported grips (0.43 m apart). Rungs use a 0.2648 m
pitch with an -0.08 m offset to fit the retargeted boots. The roof landing has
real collision beneath both final feet. The source's forward step places the
upper walking lane at z -0.818 m; the lower lane is z0. Horizontal movement on
either floor stays level. Descent returns through the original depth movement;
falling off the upper floor eases the depth back to the lower lane. The small
rear landing and broad deck must be retained when reusing this arrangement.

## Source and implementation

Publisher: https://www.patreon.com/BPGame/posts/free-fbx-first-151481680

- `Source/Character/MIKO8/LadderCandidates/BPG_FBX/Source/`: original 16 FBXs.
- `Source/Character/MIKO8/LadderCandidates/BPG_FBX/build_miko_library.py`:
  rest-pose retargeting, bone mapping, baking and export.
- `Source/Character/MIKO8/MIKO8_BPG_Ladder.blend`: editable MIKO actions.
- `Game/models/miko8/MIKO8_BPG_Ladder.json`: baked poses and source root curves.
- `Game/scripts/miko8_bpg_ladder_library.gd`: installs all 16 clips.
- `Game/scripts/miko8_bpg_ladder_motion.gd`: input, step selection and handoff.

Use `Preview Ladder Top Animations.cmd` for the close-up playable yard view.
`Review MIKO8 Ladders and Spells.cmd` also uses the new set and exposes all clips.

## Verification

`Game/scripts/review_miko8_bpg_ladder.gd` drives the actual game inputs and checks
all clip registrations, climbing out at the floor height, standing foot support,
walking away, rejection of distant down input, top re-entry, descending, holding,
reversal, look selection, jump detachment and reset. It also checks the second
ladder review scene. Reports and GPU captures are in
`Builds/Validation/BPGLadder/`. Numerical source comparisons establish import and
playback accuracy; the user still judges the animation's visual quality.

The final OpenGL run passed with zero failures in both ladder scenes and no
stderr errors. Across 1,696 measured hand/foot positions, the largest difference
from the baked retargeted source was 5.21 mm. This measurement excludes the
short initial alignment blend. The upper-floor handoff was grounded at y3.2004;
descent finished grounded at y0.0004 and z0. The standing feet each had landing
collision beneath them.
