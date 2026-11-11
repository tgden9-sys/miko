import bpy
from mathutils import Vector

BASE = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot"
bpy.ops.wm.open_mainfile(filepath=BASE + r"\security_robot_rig.blend")
rig = bpy.data.objects['Security_Robot_Rig']
mesh = bpy.data.objects['Security_Robot_Mesh']
assert len(rig.data.bones) == 12
assert len(mesh.vertex_groups) == 12

def set_pose(action, frame):
    rig.animation_data.action = bpy.data.actions[action]
    bpy.context.scene.frame_set(frame)

def axis_world(name):
    bone = rig.pose.bones[name]
    return bone.bone.matrix_local.to_3x3() @ bone.rotation_quaternion.axis

set_pose('Pivot_Left', 4)
far = axis_world('Far_Wheel')
near = axis_world('Near_Wheel')
assert far.dot(Vector((-1, 0, 0))) > 0.9, f'Far wheel did not drive forward: {far}'
assert near.dot(Vector((1, 0, 0))) > 0.9, f'Near wheel did not drive backward: {near}'
assert rig.pose.bones['Middle_Wheel'].rotation_quaternion.angle < 0.01
assert rig.pose.bones['Root'].rotation_quaternion.angle > 0.1

set_pose('Drive_Forward', 4)
assert all(rig.pose.bones[name].rotation_quaternion.angle > 1.4 for name in ('Far_Wheel', 'Middle_Wheel', 'Near_Wheel'))

set_pose('Head_Scan', 12)
assert rig.pose.bones['Head'].rotation_quaternion.angle > 0.5

set_pose('Raise_Weapon', 20)
assert all(rig.pose.bones[name].rotation_quaternion.angle > 0.1 for name in ('Weapon_Shoulder', 'Weapon_Elbow', 'Weapon_Wrist'))
print('SECURITY_RIG_OK')
