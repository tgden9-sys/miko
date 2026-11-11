"""Render MIKO's magnetic platform attach and launch from the articulated rig."""
import bpy
import math
import sys
import json
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parent
GAME = ROOT.parents[1] / 'Game'
QA_ONLY = '--qa' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'robot_knockback_v32.blend'))
scene = bpy.context.scene
names = ('CTRL | ROBOT ROOT', 'CTRL | hover body',
         'HEAD | helmet, visor and antenna',
         *[f'CTRL | {side} {joint}' for side in ('L', 'R')
           for joint in ('shoulder', 'elbow', 'wrist')])
controls = {name: bpy.data.objects[name] for name in names}

def snapshot(frame):
    scene.frame_set(frame)
    return {name: (obj.location.copy(), obj.rotation_euler.copy())
            for name, obj in controls.items()}

rest = snapshot(401)
jump_pose = snapshot(485)
for obj in controls.values():
    obj.animation_data_clear()

scene.camera = bpy.data.objects['Sprite test camera']
scene.camera.data.ortho_scale = 2.0
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16 if not QA_ONLY else 10
scene.cycles.use_denoising = True
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.film_transparent = True
scene.render.threads_mode = 'FIXED'
scene.render.threads = 8
scene.render.use_border = False
body_mesh = bpy.data.objects['TORSO | sample 2 neckerchief and single rear chassis v27']
lowest = min(v.co.z for v in body_mesh.data.vertices)
rim = [v.co.copy() for v in body_mesh.data.vertices if v.co.z < lowest + .002]
rim_centre = Vector(((min(v.x for v in rim)+max(v.x for v in rim))/2,
                     (min(v.y for v in rim)+max(v.y for v in rim))/2, lowest))
new_anchors = {}

def project(matrix, point):
    view = world_to_camera_view(scene, scene.camera, matrix @ point)
    return Vector(((view.x-.5)*512, (.5-view.y)*512))

def capture_nozzle_anchor(path):
    matrix = body_mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()).matrix_world
    points = [project(matrix, vertex) for vertex in rim]
    centre = project(matrix, rim_centre)
    axis = project(matrix, rim_centre+Vector((0,0,-.05))) - centre
    tangent = Vector((axis.y,-axis.x)).normalized()
    widths = [point.dot(tangent) for point in points]
    new_anchors[path] = {'centre':[round(value,4) for value in centre],
                         'width':round(max(widths)-min(widths),4),
                         'angle':round(math.atan2(axis.y,axis.x)-math.pi/2,5)}

def smooth(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)

def set_rest():
    for name, obj in controls.items():
        obj.location = rest[name][0].copy()
        obj.rotation_euler = rest[name][1].copy()

def attach_pose(amount):
    set_rest()
    turn = smooth(amount / .52)
    lower = smooth((amount - .12) / .88)
    root = controls['CTRL | ROBOT ROOT']
    body = controls['CTRL | hover body']
    head = controls['HEAD | helmet, visor and antenna']
    # Facing the camera is a real root rotation in the 3D rig.
    root.rotation_euler.z -= math.radians(45 * turn)
    body.location.z -= .05 * lower
    body.rotation_euler.x += math.radians(14 * lower)
    head.rotation_euler.x -= math.radians(8 * lower)
    for side, sign in (('L', -1), ('R', 1)):
        shoulder = controls[f'CTRL | {side} shoulder']
        elbow = controls[f'CTRL | {side} elbow']
        wrist = controls[f'CTRL | {side} wrist']
        shoulder.rotation_euler.x += math.radians(8 * lower)
        shoulder.rotation_euler.y += math.radians(sign * 12 * lower)
        elbow.rotation_euler.x += math.radians(-16 * lower)
        wrist.rotation_euler.x += math.radians(32 * lower)
        wrist.location.z += .03 * lower

def launch_pose(amount):
    # Start at the exact braced pose. Keep hands low for the first instant,
    # then extend vertically and blend into the approved airborne rig pose.
    attach_pose(1.0)
    braced = {name: (obj.location.copy(), obj.rotation_euler.copy())
              for name, obj in controls.items()}
    release = smooth((amount - .16) / .84)
    lift = smooth(amount / .75)
    for name, obj in controls.items():
        obj.location = braced[name][0].lerp(jump_pose[name][0], release)
        for axis in range(3):
            obj.rotation_euler[axis] = (braced[name][1][axis] * (1-release)
                                        + jump_pose[name][1][axis] * release)
    # A short, deliberate body extension reads as a magnetic launch.
    body = controls['CTRL | hover body']
    body.location.z += .07 * math.sin(math.pi * lift)

def render(name, index, count, pose):
    frame = 1501 + index if name == 'charge_attach' else 1521 + index
    scene.frame_set(frame)
    pose(index / (count - 1))
    for obj in controls.values():
        obj.keyframe_insert(data_path='location', frame=frame)
        obj.keyframe_insert(data_path='rotation_euler', frame=frame)
    bpy.context.view_layer.update()
    out = GAME / 'sprites' / name
    out.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(out / f'{name}_{index:03d}.png')
    capture_nozzle_anchor(f'sprites/{name}/{name}_{index:03d}.png')
    bpy.ops.render.render(write_still=True)
    print('CHARGE_FRAME', name, index, flush=True)

if QA_ONLY:
    for name, pose in (('charge_attach', attach_pose), ('charge_launch', launch_pose)):
        for index in (0, 6, 13) if name == 'charge_attach' else (0, 5, 11):
            render(name, index, 14 if name == 'charge_attach' else 12, pose)
else:
    for i in range(14): render('charge_attach', i, 14, attach_pose)
    for i in range(12): render('charge_launch', i, 12, launch_pose)
    anchor_path = GAME / 'sprites' / 'nozzle_anchors_v29.json'
    anchors = json.loads(anchor_path.read_text(encoding='utf-8'))
    anchors.update(new_anchors)
    anchor_path.write_text(json.dumps(anchors, separators=(',', ':')), encoding='utf-8')
    scene['charge_platform_v33'] = 'Frames 1501-1514 attach, 1521-1532 launch; 30 fps.'
    scene.frame_end = 1532
    scene.frame_set(1501)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'robot_charge_platform_v33.blend'))
    print('CHARGE_PLATFORM_COMPLETE', flush=True)
