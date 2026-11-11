import bpy
from mathutils import Vector

SOURCE = r"C:\Users\tgden\Downloads\replicate-prediction-k1d4hp77rnrne0d1ecnbtg4vkc.glb"
OUT_DIR = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot"

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=SOURCE)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.world.color = (0.16, 0.16, 0.16)

camera_data = bpy.data.cameras.new('Inspection Camera')
camera = bpy.data.objects.new('Inspection Camera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 1.35

for name, location, power, size in [
    ('Key', (2.0, -3.0, 3.0), 500, 3.0),
    ('Fill', (-2.0, 1.0, 1.5), 250, 3.0),
]:
    light_data = bpy.data.lights.new(name, 'AREA')
    light_data.energy = power
    light_data.shape = 'DISK'
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = location

for name, location in [
    ('front_neg_y', (0.0, -2.0, 0.35)),
    ('back_pos_y', (0.0, 2.0, 0.35)),
    ('side_pos_x', (2.0, 0.0, 0.35)),
    ('side_neg_x', (-2.0, 0.0, 0.35)),
    ('three_quarter', (1.5, -1.8, 0.65)),
]:
    camera.location = location
    direction = Vector((0.0, 0.0, 0.0)) - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = OUT_DIR + '\\' + name + '.png'
    bpy.ops.render.render(write_still=True)
