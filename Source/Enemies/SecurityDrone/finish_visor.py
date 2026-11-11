import bpy
import sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from visor_material import install

root = Path(__file__).resolve().parent
out = root.parents[2] / 'Game' / 'sprites' / 'security_drone'
bpy.ops.wm.open_mainfile(filepath=str(root / 'security_drone_rig.blend'))
scene = bpy.context.scene
body = bpy.data.objects['Drone_Body']
left = bpy.data.objects['Left_Blaster']
right = bpy.data.objects['Right_Blaster']
visor = bpy.data.objects['Visor_Alert_Lens']
visor.hide_render = True
if body.data.materials[0].name.startswith('Drone_Visor_State'):
    material = body.data.materials[0]
    alert = material.node_tree.nodes['Visor_Alert_Amount']
    bsdf = material.node_tree.nodes['Principled BSDF']
    mix = next(n for n in material.node_tree.nodes if n.type == 'MIX_RGB')
    mix.inputs[2].default_value = (0.40, 0.004, 0.008, 1.0)
    mix.inputs[0].links[0].from_node.inputs[1].default_value = 0.65
    bsdf.inputs['Emission Color'].default_value = (0.80, 0.004, 0.01, 1.0)
    bsdf.inputs['Emission Strength'].links[0].from_node.inputs[1].default_value = 1.2
else:
    alert = install(body)
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
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'security_drone_rig.blend'))

def render(name, shown, red):
    for obj in (body, left, right, visor):
        obj.hide_render = obj not in shown or obj == visor
    alert.outputs[0].default_value = 1.0 if red else 0.0
    scene.render.filepath = str(out / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    print('RENDERED', scene.render.filepath)

render('body_alert', (body,), True)
render('drone_preview_alert', (body, left, right), True)
