# Security drone prototype

The source model is `security_drone_source.glb`. The editable Blender rig is
`security_drone_rig.blend`. Its body and two side blasters are separate rigid
meshes. The blasters have their own bones and rotate at their mounts. Blender
actions include `Hover`, `Track_And_Aim`, `Fire_Recoil`, `Scan`, `Patrol_Turn`,
and `Patrol_Turn_Home`.

Godot uses transparent renders of that rig in the 2D game. The scene is
`Game/scenes/security_drone.tscn`; the controlling script is
`Game/scripts/security_drone.gd`. The body stays rigid while the two blasters
turn around their pivots. The underside thruster has a separate exhaust effect.

Patrol sequence: fly left 310 pixels while facing left, stop and scan, turn
180 degrees on the spot, fly right to the start while facing right, turn back,
repeat. When MIKO is visible within 430 pixels, the drone turns to face the
camera. Its visor then changes red, the blasters aim, and they fire in sequence.
If MIKO leaves range, the drone turns back toward its patrol direction.

The current drone is placed near the far end of
`Game/scenes/industrial_city.tscn` for testing. Patrol speed, distance,
detection range and bolt speed are editable on the scene instance. This is a
first combat prototype; health, damage reactions and destruction have not yet
been designed for this enemy.
