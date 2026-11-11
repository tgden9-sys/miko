import bpy
import math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder_optimized.glb")

scene = bpy.context.scene
scene.render.resolution_x = 800
scene.render.resolution_y = 800

# Add Camera
cam_data = bpy.data.cameras.new("TestCam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 3.0
cam_obj = bpy.data.objects.new("TestCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj
cam_obj.location = (0, -4, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

# Add Sun light
light_data = bpy.data.lights.new(name="Sun", type='SUN')
light_data.energy = 4.0
light_obj = bpy.data.objects.new(name="Sun", object_data=light_data)
scene.collection.objects.link(light_obj)
light_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(45))

scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_render_preview.png"
bpy.ops.render.render(write_still=True)
print("Rendered MOD02 preview")
