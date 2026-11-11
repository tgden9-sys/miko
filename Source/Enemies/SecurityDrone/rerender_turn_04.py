import bpy
import sys
from pathlib import Path
from math import pi

root = Path(__file__).resolve().parent
frame_index = int(sys.argv[-1]) if '--' in sys.argv else 4
out = root.parents[2] / 'Game' / 'sprites' / 'security_drone' / f'turn_{frame_index:02d}.png'
bpy.ops.wm.open_mainfile(filepath=str(root / 'security_drone_rig.blend'))
scene = bpy.context.scene
arm = bpy.data.objects['Security_Drone_Rig']
arm.animation_data.action = None
arm.rotation_euler.z = pi / 2.0 - pi * frame_index / 9.0
for name in ('Drone_Body', 'Left_Blaster', 'Right_Blaster'):
    bpy.data.objects[name].hide_render = False
bpy.data.objects['Visor_Alert_Lens'].hide_render = True
bpy.data.objects['Drone_Body'].data.materials[0].node_tree.nodes['Visor_Alert_Amount'].outputs[0].default_value = 0.0
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 700
scene.render.resolution_y = 700
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.filepath = str(out)
bpy.ops.render.render(write_still=True)
print('RENDERED', out)
