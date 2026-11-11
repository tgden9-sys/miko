# Charge-box test area

Three placeholder RigidBody3D boxes are in the movement demo at x=-3, 3 and 5.6 m. Their .8m visible boxes match .8m BoxShape3D colliders. Continuous collision detection is enabled; rotation and Z motion are locked for the side-view test area. Plasma now uses a swept .09m sphere instead of a centre-only ray.

L1 red and R1 blue target assistance follows the original forward cone (dot >= .45), nearest-first selection and unobstructed line of sight. The original 200px game-world reach is converted at the demo's 96px-per-1.9m character reference: 3.958m. It stays constant when switching camera zoom.

Aiming highlights the selected box; releasing commits its red/blue charge. Charge lasts 15 seconds, refreshed by targeting. Matching poles repel, opposite poles attract, for both suit/box and box/box. Y/X still control MIKO's suit separately. Plasma neutralises a charged box on impact.

Validation:
- verify_miko8_charge_boxes.gd: lock/highlight, red and blue release charging, out-of-range rejection, real attraction/repulsion displacement, neutralisation.
- verify_miko8_box_collisions.gd: settled floor contact, character blocked by the box face, landing on the box top, grazing plasma hit using the projectile volume, wall-blocked aim assist.

This is a placeholder physics test area. The original wall/ceiling magnetic anchors and launch fixtures have not yet been ported to 3D.

Global solid-obstacle pass: actor capsule radius .28m, height1.8m. WallBlocked stops movement and changes running to Idle on obstruction; it releases when the route clears or the player turns away and permits jumping/targeting. Tested on floating sphere targets (now matching solid sphere colliders), low raised blocks, platform sides and both end barriers. Hand/plasma origins are clipped to intervening solids so projectiles cannot spawn through walls. Logs: all_solids_wall, solid_verify_miko8_all_solids, solid_verify_miko8_box_collisions, emitter_obstruction. Suit accents have masked emission .16 and a low-energy matching-colour local light .12, verified in all suit states.

