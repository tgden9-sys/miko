import bpy
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'security_drone_source.glb'))
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

camera_data = bpy.data.cameras.new('InspectionCamera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 1.45
camera = bpy.data.objects.new('InspectionCamera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera

for name, loc in {'front_neg_y': (0, -2, 0.2), 'back_pos_y': (0, 2, 0.2), 'side_pos_x': (2, 0, 0.2), 'side_neg_x': (-2, 0, 0.2)}.items():
    camera.location = loc
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(root / f'{name}.png')
    bpy.ops.render.render(write_still=True)
    print('RENDERED', scene.render.filepath)
