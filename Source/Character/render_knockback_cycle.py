"""Render MIKO's non-lethal hit reaction from the approved articulated rig."""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parents[1] / 'Game' / 'sprites' / 'knockback'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
scene.frame_set(401)
names = (
    'CTRL | ROBOT ROOT', 'CTRL | hover body',
    'HEAD | helmet, visor and antenna',
    *[f'CTRL | {side} {joint}' for side in ('L', 'R') for joint in ('shoulder', 'elbow', 'wrist')],
)
controls = {name: bpy.data.objects[name] for name in names}
rest = {name: (obj.location.copy(), obj.rotation_euler.copy()) for name, obj in controls.items()}
for obj in controls.values():
    obj.animation_data_clear()
eye_open_nodes = []
for side in ('left', 'right'):
    material = bpy.data.objects[f'EYE | screen {side}'].data.materials[0]
    material.node_tree.animation_data_clear()
    eye_open_nodes.append(material.node_tree.nodes['EYE OPENNESS'].outputs[0])

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

# Quick recoil followed by a longer, increasingly small recovery. The first
# and last poses are the exact approved neutral pose, with no sprite scaling.
recoil = [0.0, 0.25, 0.65, 1.0, 0.94, 0.81, 0.68, 0.55, 0.44,
          0.35, 0.27, 0.20, 0.14, 0.09, 0.05, 0.025, 0.0, 0.0]
eye_openness = [1.0, 0.55, 0.12, 0.12, 0.35, 0.75] + [1.0] * 12
for i, weight in enumerate(recoil):
    frame = 1401 + i
    scene.frame_set(frame)
    for name, obj in controls.items():
        obj.location = rest[name][0].copy()
        obj.rotation_euler = rest[name][1].copy()
    hover = controls['CTRL | hover body']
    head = controls['HEAD | helmet, visor and antenna']
    # Both pitch axes together produce a sideways lean in this 3/4 camera.
    hover.rotation_euler.x += math.radians(-20 * weight)
    hover.rotation_euler.y += math.radians(-20 * weight)
    head.rotation_euler.x += math.radians(5 * weight)
    head.rotation_euler.y += math.radians(5 * weight)
    for side in ('L', 'R'):
        shoulder = controls[f'CTRL | {side} shoulder']
        elbow = controls[f'CTRL | {side} elbow']
        wrist = controls[f'CTRL | {side} wrist']
        angles = (90, 35, 0) if side == 'L' else (-65, -25, -35)
        for axis, angle in enumerate(angles):
            shoulder.rotation_euler[axis] += math.radians(angle * weight)
        elbow.rotation_euler.x += math.radians((22 if side == 'L' else -12) * weight)
        wrist.rotation_euler.x += math.radians(-12 * weight)
    for obj in controls.values():
        obj.keyframe_insert(data_path='location', frame=frame)
        obj.keyframe_insert(data_path='rotation_euler', frame=frame)
    for output in eye_open_nodes:
        output.default_value = eye_openness[i]
        output.keyframe_insert(data_path='default_value', frame=frame)
    bpy.context.view_layer.update()
    scene.render.filepath = str(OUT / f'knockback_{i:03d}.png')
    bpy.ops.render.render(write_still=True)
    print('KNOCKBACK_FRAME', i, flush=True)

scene['knockback_cycle_v32'] = 'Frames 1401-1418: backward recoil, eye blink, arms flail, and return to neutral pose. Rendered 20 fps.'
scene.frame_end = 1418
scene.frame_set(1401)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'robot_knockback_v32.blend'))
print('KNOCKBACK_CYCLE_COMPLETE', len(recoil), flush=True)
