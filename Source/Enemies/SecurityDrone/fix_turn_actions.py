import bpy
from pathlib import Path
from math import pi

root = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root / 'security_drone_rig.blend'))
arm = bpy.data.objects['Security_Drone_Rig']
arm.animation_data_create()
for name in ('Patrol_Turn', 'Patrol_Turn_Home'):
    old = bpy.data.actions.get(name)
    if old is not None:
        bpy.data.actions.remove(old)
for name, keys in (
    ('Patrol_Turn', [(1, -pi / 2.0), (8, 0.0), (16, pi / 2.0)]),
    ('Patrol_Turn_Home', [(1, pi / 2.0), (8, 0.0), (16, -pi / 2.0)]),
):
    action = bpy.data.actions.new(name)
    arm.animation_data.action = action
    for frame, yaw in keys:
        arm.rotation_euler.z = yaw
        arm.keyframe_insert(data_path='rotation_euler', frame=frame)
    action.use_fake_user = True
arm.animation_data.action = None
arm.rotation_euler.z = 0.0
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'security_drone_rig.blend'))
print('UPDATED TURN ACTIONS')
