import bpy
import math

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder_optimized.glb")

scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.color_type = 'TEXTURE'
scene.display.shading.light = 'FLAT'
scene.render.resolution_x = 512
scene.render.resolution_y = 512

cam_data = bpy.data.cameras.new("Cam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 2.5
cam_obj = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

# 1. Front view (-Y in Blender, looking towards +Y)
cam_obj.location = (0, -3.0, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, 0)
scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_front_Yneg.png"
bpy.ops.render.render(write_still=True)

# 2. Back view (+Y in Blender, looking towards -Y)
cam_obj.location = (0, 3.0, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(180))
scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_back_Ypos.png"
bpy.ops.render.render(write_still=True)

# 3. Right view (+X in Blender, looking towards -X)
cam_obj.location = (3.0, 0, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(90))
scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_right_Xpos.png"
bpy.ops.render.render(write_still=True)

# 4. Left view (-X in Blender, looking towards +X)
cam_obj.location = (-3.0, 0, 0.9)
cam_obj.rotation_euler = (math.radians(90), 0, math.radians(-90))
scene.render.filepath = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_left_Xneg.png"
bpy.ops.render.render(write_still=True)

print("Rendered all 4 sides!")
