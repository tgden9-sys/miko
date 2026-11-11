import bpy
from pathlib import Path
from math import pi

root = Path(__file__).resolve().parent
out = root.parents[2] / 'Game' / 'sprites' / 'security_drone'
bpy.ops.wm.open_mainfile(filepath=str(root / 'security_drone_rig.blend'))
scene = bpy.context.scene
arm = bpy.data.objects['Security_Drone_Rig']
arm.animation_data.action = None
body = bpy.data.objects['Drone_Body']
left = bpy.data.objects['Left_Blaster']
right = bpy.data.objects['Right_Blaster']
visor = bpy.data.objects['Visor_Alert_Lens']
visor.hide_render = True
for obj in (body, left, right):
    obj.hide_render = False
alert = body.data.materials[0].node_tree.nodes['Visor_Alert_Amount']
alert.outputs[0].default_value = 0.0
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 700
scene.render.resolution_y = 700
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'

def render(name, yaw):
    arm.rotation_euler.z = yaw
    scene.render.filepath = str(out / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    print('RENDERED', scene.render.filepath)

render('patrol_right', pi / 2.0)
for i in range(10):
    render(f'turn_{i:02d}', pi / 2.0 - pi * i / 9.0)
render('patrol_left', -pi / 2.0)
arm.rotation_euler.z = 0.0
