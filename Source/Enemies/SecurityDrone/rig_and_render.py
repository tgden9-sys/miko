"""Build rigid gun pivots from the supplied GLB and render 2D game layers."""
import bpy
import sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from visor_material import install as install_visor_material

root = Path(__file__).resolve().parent
out = Path(__file__).resolve().parents[3] / 'Game' / 'sprites' / 'security_drone'
out.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'security_drone_source.glb'))
body = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
body.name = 'Drone_Body'
mesh = body.data
n = len(mesh.vertices)
parents = list(range(n))
sizes = [1] * n

def find(i):
    while parents[i] != i:
        parents[i] = parents[parents[i]]
        i = parents[i]
    return i

for edge in mesh.edges:
    a, b = edge.vertices
    ra, rb = find(a), find(b)
    if ra != rb:
        if sizes[ra] < sizes[rb]:
            ra, rb = rb, ra
        parents[rb] = ra
        sizes[ra] += sizes[rb]

totals = {}
for v in mesh.vertices:
    r = find(v.index)
    x, y, z = v.co
    if r not in totals:
        totals[r] = [0, 0.0, 0.0, 0.0]
    s = totals[r]
    s[0] += 1
    s[1] += x
    s[2] += y
    s[3] += z

groups = {'Left_Blaster': [], 'Right_Blaster': []}
for v in mesh.vertices:
    count, sx, sy, sz = totals[find(v.index)]
    x, y, z = sx/count, sy/count, sz/count
    if abs(y) < 0.15 and z < 0.24:
        if x < -0.345:
            groups['Left_Blaster'].append(v.index)
        elif x > 0.345:
            groups['Right_Blaster'].append(v.index)
for name, indices in groups.items():
    vg = body.vertex_groups.new(name=name)
    for start in range(0, len(indices), 10000):
        vg.add(indices[start:start+10000], 1.0, 'REPLACE')
    print('GROUP', name, len(indices))

def separate_group(name):
    global body
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='DESELECT')
    body.vertex_groups.active = body.vertex_groups[name]
    bpy.ops.object.vertex_group_select()
    before = set(bpy.context.scene.objects)
    bpy.ops.mesh.separate(type='SELECTED')
    bpy.ops.object.mode_set(mode='OBJECT')
    pieces = [o for o in bpy.context.scene.objects if o not in before and o.type == 'MESH']
    assert len(pieces) == 1, (name, pieces)
    piece = pieces[0]
    piece.name = name
    print('SEPARATED', name, len(piece.data.vertices), len(body.data.vertices))
    return piece

left = separate_group('Left_Blaster')
right = separate_group('Right_Blaster')
for obj in (body, left, right):
    for vg in list(obj.vertex_groups):
        obj.vertex_groups.remove(vg)

arm_data = bpy.data.armatures.new('Drone_Rig_Data')
arm = bpy.data.objects.new('Security_Drone_Rig', arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for name, head, tail in [
    ('Body', (0, 0, -0.25), (0, 0, 0.25)),
    ('Left_Blaster', (-0.40, 0.0, 0.04), (-0.40, 0.0, 0.19)),
    ('Right_Blaster', (0.40, 0.0, 0.04), (0.40, 0.0, 0.19)),
]:
    bone = arm_data.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    if name != 'Body':
        bone.parent = arm_data.edit_bones['Body']
        bone.use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')
arm.show_in_front = True
body.parent = arm
for obj, bone_name in ((left, 'Left_Blaster'), (right, 'Right_Blaster')):
    obj.parent = arm
    vg = obj.vertex_groups.new(name=bone_name)
    for start in range(0, len(obj.data.vertices), 10000):
        vg.add(list(range(start, min(start+10000, len(obj.data.vertices)))), 1.0, 'REPLACE')
    modifier = obj.modifiers.new('Rigid_Bone_Deform', 'ARMATURE')
    modifier.object = arm
    modifier.use_vertex_groups = True
    arm.pose.bones[bone_name].rotation_mode = 'XYZ'

# A slim inset lens follows the supplied visor silhouette. Its red emission is
# animated as a material, while the shell remains one rigid body.
visor_mesh = bpy.data.meshes.new('Visor_Alert_Lens_Mesh')
verts = [
    (-0.215, -0.270, 0.145), (-0.110, -0.286, 0.132), (0.0, -0.291, 0.126),
    (0.110, -0.286, 0.132), (0.215, -0.270, 0.145),
    (-0.215, -0.270, 0.130), (-0.110, -0.286, 0.116), (0.0, -0.291, 0.110),
    (0.110, -0.286, 0.116), (0.215, -0.270, 0.130),
]
faces = [(i, i+1, i+6, i+5) for i in range(4)]
visor_mesh.from_pydata(verts, [], faces)
visor_mesh.update()
visor = bpy.data.objects.new('Visor_Alert_Lens', visor_mesh)
bpy.context.scene.collection.objects.link(visor)
visor.parent = arm
mat = bpy.data.materials.new('Visor_Red_Emission')
mat.diffuse_color = (0.35, 0.005, 0.01, 1.0)
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (0.20, 0.002, 0.005, 1.0)
bsdf.inputs['Emission Color'].default_value = (1.0, 0.01, 0.02, 1.0)
bsdf.inputs['Emission Strength'].default_value = 0.0
visor.data.materials.append(mat)
alert_node = install_visor_material(body)
visor.hide_render = True

def gun_action(name, keyframes):
    action = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = action
    for frame, left_angle, right_angle in keyframes:
        for bone_name, angle in (('Left_Blaster', left_angle), ('Right_Blaster', right_angle)):
            bone = arm.pose.bones[bone_name]
            bone.rotation_euler.y = angle
            bone.keyframe_insert(data_path='rotation_euler', frame=frame, group=bone_name)
    action.use_fake_user = True
    return action

hover = gun_action('Hover', [(1, 0, 0), (12, 0, 0)])
aim = gun_action('Track_And_Aim', [(1, 0, 0), (8, -0.45, 0.45), (14, -0.45, 0.45)])
fire = gun_action('Fire_Recoil', [(1, -0.45, 0.45), (3, -0.30, 0.30), (7, -0.45, 0.45)])
arm.animation_data.action = hover

arm.rotation_mode = 'XYZ'
for name, keys in {
    'Patrol_Turn': [(1, -1.5708), (8, 0.0), (16, 1.5708)],
    'Patrol_Turn_Home': [(1, 1.5708), (8, 0.0), (16, -1.5708)],
    'Scan': [(1, -0.10), (8, 0.10), (16, -0.10)],
}.items():
    action = bpy.data.actions.new(name)
    arm.animation_data.action = action
    for frame, yaw in keys:
        arm.rotation_euler.z = yaw
        arm.keyframe_insert(data_path='rotation_euler', frame=frame)
    action.use_fake_user = True
arm.animation_data.action = None
arm.rotation_euler.z = 0.0

for frame, strength in ((1, 0.0), (6, 0.0), (10, 5.0), (16, 5.0)):
    bsdf.inputs['Emission Strength'].default_value = strength
    bsdf.inputs['Emission Strength'].keyframe_insert(data_path='default_value', frame=frame)
bsdf.inputs['Emission Strength'].default_value = 0.0
bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'security_drone_rig.blend'))

scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 700
scene.render.resolution_y = 700
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.world.color = (0.07, 0.07, 0.09)

def light(name, loc, power, size):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (Vector((0, 0, 0)) - obj.location).to_track_quat('-Z', 'Y').to_euler()

light('Key', (1.5, -2.0, 2.0), 300, 3.0)
light('Fill', (-1.4, 1.0, 1.4), 190, 3.0)
light('Rim', (0.5, 1.5, 2.2), 240, 2.2)
camera_data = bpy.data.cameras.new('GameCamera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 1.45
camera = bpy.data.objects.new('GameCamera', camera_data)
scene.collection.objects.link(camera)
camera.location = (0, -2, 0.2)
camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
scene.camera = camera

def render(name, visible, red=False):
    for obj in (body, left, right, visor):
        obj.hide_render = obj not in visible or obj == visor
    alert_node.outputs[0].default_value = 1.0 if red else 0.0
    scene.render.filepath = str(out / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    print('RENDERED', scene.render.filepath)

render('body_idle', (body,))
render('body_alert', (body, visor), True)
render('left_blaster', (left,))
render('right_blaster', (right,))
render('drone_preview_idle', (body, left, right))
render('drone_preview_alert', (body, left, right, visor), True)
for i in range(10):
    arm.rotation_euler.z = 1.5708 - i / 9.0 * 3.14159
    render(f'turn_{i:02d}', (body, left, right))
arm.rotation_euler.z = 0.0
