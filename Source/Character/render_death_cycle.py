"""Render MIKO's powered-down fall from the approved v28 Blender rig."""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parents[1] / 'Game' / 'sprites' / 'death'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
scene.frame_set(401)
controls = {name: bpy.data.objects[name] for name in (
    'CTRL | ROBOT ROOT', 'CTRL | hover body',
    'HEAD | helmet, visor and antenna',
    *[f'CTRL | {side} {joint}' for side in ('L', 'R') for joint in ('shoulder', 'elbow', 'wrist')],
)}
eyes = [bpy.data.objects['EYE | screen left'], bpy.data.objects['EYE | screen right']]
rest = {name: (obj.location.copy(), obj.rotation_euler.copy()) for name, obj in controls.items()}
for obj in controls.values():
    obj.animation_data_clear()
for obj in eyes:
    obj.animation_data_clear()

scene.camera = bpy.data.objects['Sprite test camera']
scene.camera.data.ortho_scale = 2.0
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
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

def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)

count = 20
for i in range(count):
    frame = 1301 + i
    scene.frame_set(frame)
    drop = smooth((i - 2) / 6.0)
    tumble = smooth((i - 7) / 8.0)
    settle = smooth((i - 15) / 4.0)
    for name, obj in controls.items():
        obj.location = rest[name][0].copy()
        obj.rotation_euler = rest[name][1].copy()
    root = controls['CTRL | ROBOT ROOT']
    hover = controls['CTRL | hover body']
    head = controls['HEAD | helmet, visor and antenna']
    hover.location.z -= 0.14 * drop
    hover.location.y -= 0.08 * drop + 0.19 * tumble
    # Pitch the actual rig forward after its dead-weight drop.
    hover.rotation_euler.x += math.radians(8 * drop + 71 * tumble - 4 * settle)
    head.rotation_euler.x += math.radians(-13 * drop - 16 * tumble + 3 * settle)
    for side, sign in (('L', -1), ('R', 1)):
        shoulder = controls[f'CTRL | {side} shoulder']
        elbow = controls[f'CTRL | {side} elbow']
        wrist = controls[f'CTRL | {side} wrist']
        shoulder.rotation_euler.x += math.radians(20 * drop - 18 * tumble)
        shoulder.rotation_euler.y += math.radians(sign * (12 * drop + 12 * tumble))
        elbow.rotation_euler.x += math.radians(-15 * drop - 12 * tumble)
        wrist.rotation_euler.x += math.radians(8 * drop + 8 * tumble)
    for obj in controls.values():
        obj.keyframe_insert(data_path='location', frame=frame)
        obj.keyframe_insert(data_path='rotation_euler', frame=frame)
    for eye in eyes:
        eye.hide_render = (i >= 2)
        eye.keyframe_insert(data_path='hide_render', frame=frame)
    bpy.context.view_layer.update()
    scene.render.filepath = str(OUT / f'death_{i:03d}.png')
    bpy.ops.render.render(write_still=True)
    print('DEATH_FRAME', i, flush=True)

scene['death_cycle_v31'] = 'Frames 1301-1320: power loss, drop, forward tumble, settle. Rendered 20 fps.'
scene.frame_end = 1320
scene.frame_set(1301)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'robot_death_v31.blend'))
print('DEATH_CYCLE_COMPLETE', count, flush=True)
