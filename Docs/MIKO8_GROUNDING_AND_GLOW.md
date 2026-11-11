# Ground connection and charge glow

Measured evaluated boot mesh in the canonical Blender scene at 9 phases per gait. Sole heights (metres) are in Builds/Validation/MIKO8/ladder_candidates/sole_heights.json. Idle within about 6mm of the floor; walking samples -26mm to +20mm. Run/sprint include genuine source flight phases; these have not been removed or forced onto the floor.

The controller previously ran looping gait animation at full speed during acceleration and could switch to Idle while still travelling. Looping Walk/Run/Sprint playback now follows horizontal speed / nominal source speed. Walk/Run stopping retains the slowing gait until velocity is zero, then blends to Idle. Native poses and steady-state gait speeds remain intact. Non-gait states reset the playback multiplier, preserving jump, ladder and spell timing.

A soft contact-shadow patch projects onto actual solid surfaces below the actor, fades/broadens with foot height, and hides during ladder/clip review. It improves floor readability over the unshaded grid without moving feet or collision geometry.

Charge visibility: masked accent emission increased to .65, matching-colour light energy .45, and a softly fading billboard halo added behind the body. All three states rendered and visually inspected.

Validation: verify_miko8_grounding_sync.gd checks rate changes through acceleration and stopping, no idle coasting, rate reset and suit-state halo renders. Barrier collision and jump/landing/aim checks rerun after integration. Visual feel still needs user review in motion.

User review correction: removed the body halo, OmniLight and all accent emission. Original sprite inspected (Game/sprites/idle/idle_000.png) and suit_eyes shader read: softly shaded ivory armour with local bright eyes, not a body aura. Muted red/blue/green accent recolours retained. Landing now resumes the chosen gait at .2m/s (60Hz) and uses normal 12m/s² ground acceleration with playback rate matched to speed; it no longer jumps to full gait speed. verify_miko8_landing_acceleration.gd verifies progressive run/sprint recovery and absence of glow nodes/emission.

Push-off revision: slowing the first frames of a running loop still produced a glide. Standing and post-landing run/sprint starts now use the existing authored SprintEnter weight-shift/push-off, played at normal progression over .65s for Run or .80s for Sprint. World travel stays zero through the first 30% (planted weight shift), then builds progressively and blends into the requested loop. Already-moving gait changes avoid restarting a standing sprint-enter pose. Walk starts remain short. verify_miko8_push_off.gd checks advancing start animation with no premature world travel and the post-landing path; plant/push captures inspected.


Moving-landing update: when the stick continues in the landing direction, preserve incoming capped air velocity and blend directly into the selected gait over .06s. Playback follows actual speed and normal ground acceleration restores running speed. This supersedes the standing push-off after moving landings; standing starts still use authored push-off. verify_miko8_light_hits_landing.gd passed for run and sprint; contact renders inspected. Visual feel remains subject to play review.

Controller gait correction: sprint threshold reduced from .88 to .78 of processed stick input, equally left/right, including the legacy SprintEnter exit check. Equal-input tests reproduced identical direction speeds before the change; hardware asymmetry is a suspected cause, not measured. verify_miko8_direction_symmetry.gd checks .65 Run and .80/1.0 Sprint in both directions.

Ladder handoff: top dismount now uses a smooth-start horizontal curve with walking-speed end velocity instead of easing to zero. Exit Walk uses native 1x playback; same-direction input blends directly into selected gait with speed-matched playback, neutral input settles through GroundStop, reverse input uses normal reversal. Bottom dismount retains planted standing-start behavior. verify_miko8_ladder_handoff.gd passed neutral, walk, run, sprint and reverse cases, collision restoration and terminal step-speed checks. Play feel still needs user review.
