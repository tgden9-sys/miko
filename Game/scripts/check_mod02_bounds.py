import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Downloads\mod02_modular_column_ladder_1793636742624_Textured_55524100578.glb")

mesh_obj = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
print(f"MOD02 dimensions: {mesh_obj.dimensions}")
print(f"MOD02 bounds: min={mesh_obj.bound_box[0]} max={mesh_obj.bound_box[6]}")
