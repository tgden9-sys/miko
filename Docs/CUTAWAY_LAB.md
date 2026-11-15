# Cutaway lab

Run `Play Cutaway Lab.cmd` to open the standalone prototype.

## Reading the references

The supplied Dread shots use thick dark cross sections around occupied spaces. Bright narrow edges describe collision surfaces. Interior architecture remains behind the player and can continue behind the solid foreground. This establishes a consistent distinction between reachable space and background detail.

The first shot uses a low entrance and a taller chamber with a break in the floor. The second uses overlapping floor and ceiling masses to direct the route upward. The third uses a central solid to create upper and lower routes. The fourth uses the same principle with irregular cave contours.

The prototype applies those relationships to an industrial lab. Its entrance corridor leads through a stepped climb into an upper chamber. The sealed white start door and blue exit field reuse Miko's existing polarity controls. Miko exits behind the end wall, then the scene fades. There is no network node. All three spaces belong to one continuous scene.

## Authoring

`MovementLab/scripts/lab_cutaway_layout.gd` defines open rectangles, solid inserts, background placements and lamp positions in metres. The current grid is half a metre.

`lab_cutaway_shell.gd` builds collision and dark foreground from the same occupancy map, then merges the exposed edges into continuous trim. Trim occupies the solid side of each boundary. Changing an opening or obstacle updates these three outputs together.

The room uses one cohesive custom backdrop, `lab_cutaway_wall.png`, behind the playable outline.

Camera zoom stays fixed. A perspective camera sits 32 metres from the playable plane and 1.35 metres above its target, revealing the textured tops and inner wall surfaces. The camera follows horizontally, eases upward through the climb and clamps at the outer level ends. Enclosed low areas intentionally show black structural mass above and below. A contrasting FPS panel sits at the top right.

New routes can reuse the builder with different rectangles, background selections and lights. Review headroom, jump distances, route visibility and silhouettes using the actual gameplay camera. The half-metre rectangle system currently supports orthogonal industrial rooms. Bevelled room outlines and independent room-to-room camera zones would require further development.

## Verification

The traversal exercise in `Builds/verify_cutaway.gd` moves Miko through the route, jumps the upper gap, checks the sealed start, crosses the blue shield and checks the concealed exit and fade. It also captures gameplay views for visual inspection.

## Doorway assembly

The supplied 10,000-triangle GLB remains the tunnel interior. Its reconstructed front lip is suppressed by the tunnel shader and replaced by a continuous bevelled mounting flange, gasket, throat, flush threshold and recessed electrode housings. The finish preserves UV detail, adds material-scale steel grain, and uses a dark charcoal/blue-green palette instead of the original pale baked lighting. The electrical effect is a translucent containment field with gently fading, emitter-anchored discharges. Field, indicator and material spill power follow the existing polarity state together.

`Layout.ENTRANCE` and `Layout.EXIT` drive doorway placement, camera end stops and exit travel. `foreground_solid()` adds the concealed tunnel cheeks to the shell's visual occupancy. The shell derives its black cut faces and continuous mitred trim from that map; collision still uses `solid()` so the tunnel remains traversable. No separate foreground patch or exposed side box is needed. Both door directions use the same assembly.

Mounting contract for subsequent rooms: a floor-level origin on the half-metre grid, a 2.5 m shell opening, the shared front cut plane at Z=.66, and room geometry above the doorway. The portal faces exactly along the X travel axis. Keep approximately 1.55 m of screen space beyond the exit plane in the clamped camera view. The prototype layout still requires floor/opening rectangles to be authored; the doorway constants are not a general room generator.

Run `res://scripts/verify_cutaway_doors.gd` with Godot's `--script` option to check the sealed entrance in all three suit states, matching/neutral rejection, opposite-polarity opening, recharge after retreat, concealed departure and reset. Visually inspect both ends at gameplay scale as well as a close view; check every join, effect readability, and Miko's disappearance before the fade. `Builds/review_door.gd` captures those views and an effect-motion contact sheet.

Nintendo describes the map as a foundation for exploration, and identifies doors and blocks as useful route landmarks. The interpretation of dark cut faces above comes from the supplied screenshots.

- https://metroid.nintendo.com/dread/news/metroid-dread-report-vol-3/
- https://metroid.nintendo.com/dread/news/metroid-dread-report-vol-11/
