import bpy
import math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Downloads\mod02_modular_column_ladder_1793636742624_Textured_55524100578.glb")

obj = bpy.context.scene.objects[0]
print("Object name:", obj.name)
print("Dimensions:", obj.dimensions)

# Render a quick viewport preview of the front ladder face using Workbench (instant, no cycles)
cam_data = bpy.data.cameras.new("Cam")
cam_obj = bpy.data.objects.new("Cam", cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# Position camera looking directly at the ladder face (-Y in Blender)
cam_obj.location = (0, -2.2, 0.95)
cam_obj.rotation_euler = (math.radians(90), 0, 0)

bpy.context.scene.render.engine = 'BLENDER_WORKBENCH'
bpy.context.scene.display.shading.color_type = 'TEXTURE'
bpy.context.scene.display.shading.light = 'FLAT'
bpy.context.scene.render.resolution_x = 512
bpy.context.scene.render.resolution_y = 512
bpy.context.scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\scripts\raw_mod02_workbench.png"

bpy.ops.render.render(write_still=True)
print("Rendered raw_mod02_workbench.png with Workbench engine!")
