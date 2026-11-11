# Security robot rig

The supplied model is preserved as `security_robot_source.glb`. The editable rig is `security_robot_rig.blend`; the game-ready export is `security_robot_rig.glb`.

This experiment has been removed from the Godot game. The supplied model and Blender rig are retained here as source files only.

The GLB arrived as one mesh with many disconnected hard-surface islands. The Blender build script assigns each island entirely to a joint, keeping the armour, wheels, head, and weapon rigid during animation.

## Controls

The armature is `Security_Robot_Rig`. Pose these named bones in Blender:

| Joint | Use |
|---|---|
| `Root` | Rotate the whole robot in place; game movement should drive its position |
| `Far_Wheel` / `Near_Wheel` | Counter-rotate for a spot turn; both roll forward for travel |
| `Middle_Wheel` | Rolls for travel; stays free during a spot turn |
| `Head` | Swivels independently above the neck |
| `Open_Shoulder`, `Open_Elbow`, `Open_Wrist` | Three-joint non-weapon arm |
| `Weapon_Shoulder`, `Weapon_Elbow`, `Weapon_Wrist` | Bring up and aim the gun |

## Included animations

`Idle`, `Drive_Forward`, `Pivot_Left`, `Pivot_Right`, `Head_Scan`, `Raise_Weapon`, `Fire_Recoil`, and `Open_Arm_Test`.

All clips are in-place except the root's rotation during pivot clips. The game should translate the character body during travel. `Raise_Weapon` is a base aiming pose; weapon tracking can add joint rotations at runtime. The three wheel rolls use quarter-turn keys so rotation survives glTF quaternion export.

## Files

- `rig_security.py`: reproducible Blender build script.
- `refine_tread.py`: adds a regular, bone-driven rubber tread over the source model's irregular generated tyre surface. Run after `rig_security.py` if rebuilding from source.
- `rig_report.json`: joint, animation, and island counts.
- `rig_idle.png`, `rig_weapon_raised.png`, `rig_pivot_mid.png`, `rig_head_scan.png`, `rig_open_arm.png`: render checks.
