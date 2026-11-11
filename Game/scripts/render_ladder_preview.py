import bpy
import math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder.glb")

# Setup camera and light to render a quick preview of the 4 sides
cam_data = bpy.data.cameras.new("Cam")
cam_obj = bpy.data.objects.new("Cam", cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

light_data = bpy.data.lights.new("Light", type='SUN')
light_obj = bpy.data.objects.new("Light", light_data)
bpy.context.scene.collection.objects.link(light_obj)
light_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(45))

bpy.context.scene.render.resolution_x = 512
bpy.context.scene.render.resolution_y = 512

# Look at -Y side (where ladder is)
cam_obj.location = (0, -2.5, 1.0)
cam_obj.rotation_euler = (math.radians(90), 0, 0)
bpy.context.scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\scripts\ladder_side_preview.png"
bpy.ops.render.render(write_still=True)
print("Rendered ladder_side_preview.png successfully")
