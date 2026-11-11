"""Build a rigid articulated rig from the supplied single-mesh GLB."""
import bpy
import json
import math
from array import array
from collections import defaultdict
from mathutils import Quaternion, Vector

BASE = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot"
SOURCE = BASE + r"\security_robot_source.glb"
BLEND = BASE + r"\security_robot_rig.blend"
GLB = BASE + r"\security_robot_rig.glb"
REPORT = BASE + r"\rig_report.json"

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=SOURCE)
mesh_obj = next(obj for obj in bpy.data.objects if obj.type == 'MESH')
mesh_obj.name = 'Security_Robot_Mesh'
mesh_obj.parent = None
for obj in list(bpy.data.objects):
    if obj != mesh_obj:
        bpy.data.objects.remove(obj, do_unlink=True)
mesh = mesh_obj.data

# The generated GLB uses one mesh and thousands of disconnected hard-surface
# islands. Assign every island rigidly to one joint so armour never bends.
n = len(mesh.vertices)
parent = array('i', range(n))
size = array('i', [1]) * n

def find(a):
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    return a

for edge in mesh.edges:
    a, b = edge.vertices
    ra, rb = find(a), find(b)
    if ra != rb:
        if size[ra] < size[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        size[ra] += size[rb]

islands = defaultdict(list)
for vertex in mesh.vertices:
    islands[find(vertex.index)].append(vertex.index)

groups = defaultdict(list)
for indices in islands.values():
    x = sum(mesh.vertices[i].co.x for i in indices) / len(indices)
    y = sum(mesh.vertices[i].co.y for i in indices) / len(indices)
    z = sum(mesh.vertices[i].co.z for i in indices) / len(indices)
    low_z = min(mesh.vertices[i].co.z for i in indices)
    high_z = max(mesh.vertices[i].co.z for i in indices)
    width_x = max(mesh.vertices[i].co.x for i in indices) - min(mesh.vertices[i].co.x for i in indices)

    if low_z < -0.32 and high_z < -0.185 and width_x < 0.17:
        group = 'Far_Wheel' if x < -0.155 else ('Near_Wheel' if x > 0.155 else 'Middle_Wheel')
    elif z > 0.295 and low_z > 0.215 and abs(x) < 0.145:
        group = 'Head'
    elif x < -0.14 and z > -0.16:
        group = 'Open_Wrist' if x < -0.375 else ('Open_Elbow' if x < -0.275 else 'Open_Shoulder')
    elif x > 0.16 and z > -0.16:
        # The barrel and cable extend forward in -Y and follow the wrist.
        group = 'Weapon_Wrist' if x > 0.385 or (x > 0.34 and y < -0.08) else ('Weapon_Elbow' if x > 0.29 else 'Weapon_Shoulder')
    elif z < -0.17:
        group = 'Root'
    else:
        group = 'Torso'
    groups[group].extend(indices)

for name, indices in groups.items():
    vertex_group = mesh_obj.vertex_groups.new(name=name)
    for start in range(0, len(indices), 20000):
        vertex_group.add(indices[start:start + 20000], 1.0, 'REPLACE')

arm_data = bpy.data.armatures.new('Security_Robot_Armature')
rig = bpy.data.objects.new('Security_Robot_Rig', arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')

def bone(name, head, tail, parent_name=None):
    item = arm_data.edit_bones.new(name)
    item.head = head
    item.tail = tail
    if parent_name:
        item.parent = arm_data.edit_bones[parent_name]
    item.use_connect = False
    return item

bone('Root', (0.02, 0.12, -0.47), (0.02, 0.12, -0.34))
bone('Torso', (0.02, 0.12, -0.17), (0.02, 0.12, 0.22), 'Root')
bone('Head', (0.025, 0.095, 0.275), (0.025, 0.095, 0.42), 'Torso')
bone('Far_Wheel', (-0.24, 0.135, -0.34), (-0.19, 0.135, -0.34), 'Root')
bone('Middle_Wheel', (0.025, 0.135, -0.34), (0.075, 0.135, -0.34), 'Root')
bone('Near_Wheel', (0.25, 0.135, -0.34), (0.30, 0.135, -0.34), 'Root')
bone('Open_Shoulder', (-0.13, 0.11, 0.17), (-0.25, 0.11, 0.10), 'Torso')
bone('Open_Elbow', (-0.275, 0.105, 0.095), (-0.37, 0.08, 0.035), 'Open_Shoulder')
bone('Open_Wrist', (-0.375, 0.07, 0.03), (-0.47, 0.06, -0.02), 'Open_Elbow')
bone('Weapon_Shoulder', (0.15, 0.105, 0.18), (0.28, 0.08, 0.105), 'Torso')
bone('Weapon_Elbow', (0.295, 0.08, 0.105), (0.385, 0.035, 0.075), 'Weapon_Shoulder')
bone('Weapon_Wrist', (0.39, 0.025, 0.075), (0.46, -0.19, 0.06), 'Weapon_Elbow')
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True
arm_data.display_type = 'STICK'

mesh_obj.parent = rig
modifier = mesh_obj.modifiers.new('Rigid joint deformation', 'ARMATURE')
modifier.object = rig
modifier.use_deform_preserve_volume = False

for pose_bone in rig.pose.bones:
    pose_bone.rotation_mode = 'QUATERNION'

rig.animation_data_create()

def set_axis_rotation(name, axis, degrees):
    pose_bone = rig.pose.bones[name]
    local_axis = pose_bone.bone.matrix_local.to_3x3().inverted() @ Vector(axis)
    pose_bone.rotation_quaternion = Quaternion(local_axis, math.radians(degrees))

def keyframe(frame, rotations=None):
    rotations = rotations or {}
    for pose_bone in rig.pose.bones:
        pose_bone.rotation_quaternion = Quaternion((1.0, 0.0, 0.0, 0.0))
        pose_bone.location = (0.0, 0.0, 0.0)
    for name, (axis, degrees) in rotations.items():
        set_axis_rotation(name, axis, degrees)
    for pose_bone in rig.pose.bones:
        pose_bone.keyframe_insert(data_path='rotation_quaternion', frame=frame, group=pose_bone.name)

actions = {}

def make_action(name, poses):
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    for frame, rotations in poses:
        keyframe(frame, rotations)
    action.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 1, action)
    strip.action_frame_start = poses[0][0]
    strip.action_frame_end = poses[-1][0]
    track.mute = True
    actions[name] = action
    rig.animation_data.action = None

make_action('Idle', [(1, {}), (24, {})])
make_action('Drive_Forward', [
    (1 + 3 * step, {wheel: ((1, 0, 0), -90 * step) for wheel in ('Far_Wheel', 'Middle_Wheel', 'Near_Wheel')})
    for step in range(9)
])
for name, angle in [('Pivot_Left', 90), ('Pivot_Right', -90)]:
    make_action(name, [
        (1 + 3 * step, {'Root': ((0, 0, 1), angle * step / 8),
                        'Far_Wheel': ((1, 0, 0), (-90 if angle > 0 else 90) * step),
                        'Near_Wheel': ((1, 0, 0), (90 if angle > 0 else -90) * step)})
        for step in range(9)
    ])
make_action('Head_Scan', [
    (1, {}), (12, {'Head': ((0, 0, 1), 35)}),
    (24, {'Head': ((0, 0, 1), -35)}), (36, {}),
])
make_action('Raise_Weapon', [
    (1, {}),
    (10, {'Weapon_Shoulder': ((0, 1, 0), -12), 'Weapon_Elbow': ((0, 1, 0), 8), 'Weapon_Wrist': ((1, 0, 0), -6), 'Head': ((0, 0, 1), -8)}),
    (20, {'Weapon_Shoulder': ((0, 1, 0), -25), 'Weapon_Elbow': ((0, 1, 0), 16), 'Weapon_Wrist': ((1, 0, 0), -12), 'Head': ((0, 0, 1), -12)}),
])
make_action('Fire_Recoil', [
    (1, {'Weapon_Shoulder': ((0, 1, 0), -25), 'Weapon_Elbow': ((0, 1, 0), 16), 'Weapon_Wrist': ((1, 0, 0), -12)}),
    (3, {'Weapon_Shoulder': ((0, 1, 0), -22), 'Weapon_Elbow': ((0, 1, 0), 12), 'Weapon_Wrist': ((1, 0, 0), 2)}),
    (7, {'Weapon_Shoulder': ((0, 1, 0), -25), 'Weapon_Elbow': ((0, 1, 0), 16), 'Weapon_Wrist': ((1, 0, 0), -12)}),
])
make_action('Open_Arm_Test', [
    (1, {}),
    (20, {'Open_Shoulder': ((0, 1, 0), 25), 'Open_Elbow': ((0, 1, 0), 20), 'Open_Wrist': ((1, 0, 0), 25)}),
])

rig.animation_data.action = actions['Idle']
bpy.context.scene.frame_set(1)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=BLEND)

bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
mesh_obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(
    filepath=GLB,
    export_format='GLB',
    use_selection=True,
    export_animations=True,
    export_animation_mode='ACTIONS',
)

with open(REPORT, 'w', encoding='utf-8') as stream:
    json.dump({
        'vertices': n,
        'islands': len(islands),
        'bones': [bone.name for bone in arm_data.bones],
        'group_vertices': {name: len(indices) for name, indices in groups.items()},
        'actions': list(actions),
        'blend': BLEND,
        'glb': GLB,
    }, stream, indent=2)
print('RIG_DONE', BLEND, GLB)
