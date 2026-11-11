# Wall-mounted mag pad

Current tuning: low mounting at x52.68, y.65, scaled to 75% of the original fitted size so its backing plate clears the footing. Its force on blocks is explicitly horizontal, irrespective of block height. Neutralising a movable block clears targeting/field state and persistent forces, restores normal gravity and wakes it so it falls if unsupported. `review_miko8_discharge_fall.gd` verifies horizontal pull without lift and an airborne block falling after discharge.

Source: `Source/Props/MagPad/original.glb` (unchanged copy of supplied asset). Editable Blender file and preparation script are alongside it. Gameplay GLB: `Game/models/props/mag_pad/mag_pad.glb`, 63,999 triangles / 7.9 MB versus 150,109 triangles / 20.4 MB originally. Colour atlas retained; normal and metallic/roughness textures omitted for the scene's cel treatment.

The pad is mounted facing left on the new reusable plain block's left wall at x52.68, y.65, close to the ground beside the existing approach crates. This block now occupies the old standalone workshop location. This side faces the normal gameplay camera. The current fitted face is roughly .89 m square and .26 m deep. A dark backing plate/gasket and four anchors join it to the wall. The tutorial crate remains at its original x24 position.

Green means neutral/no magnetic force. Hold/release Q or E (LB/RB) fires the usual red/blue charge. Opposite-charge blocks are pulled to the fixed pad; matching ones are repelled. The pad shares block field rings, connections, target brackets, charge refresh and 15-second expiry. Plasma or reset discharges to green. Green paint is preserved/recoloured using the existing loader shader and global cel pass.

It is a StaticBody3D charge target, never a movable crate or launcher. Existing movable-block forces respond to it; it never applies force to MIKO. Its collision hull follows the mounted casing. It does not alter ladder or movement tuning.

`review_miko8_wall_mag_pad.gd` tests an actual released red bolt, opposite attraction, matching repulsion, fixed pad position, no force on MIKO, blue state, expiry and actual plasma discharge. Logs and green/red/blue GPU captures are in `Builds/Validation/MagPad`. `Preview Wall Mag Pad.cmd` opens the yard beside it, facing the pad, with a crate to the right.

