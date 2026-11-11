import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Downloads\mod02_modular_column_ladder_1793636742624_Textured_55524100578.glb")

mesh = bpy.context.scene.objects[0].data
print(f"MOD02 vertices: {len(mesh.vertices)}, polygons: {len(mesh.polygons)}")

# Let's inspect the vertices at different heights and depths:
# Find what parts exist:
# In the original 2D image `mod02_modular_column_ladder_1793636742624.jpg`, what was shown?
# Let's find rungs: rungs are horizontal elements at regular intervals in Z (height).
z_coords = sorted(list(set(round(v.co.z, 2) for v in mesh.vertices)))
print(f"Height range: Z={min(v.co.z for v in mesh.vertices):.3f} to {max(v.co.z for v in mesh.vertices):.3f}")
print(f"X range: {min(v.co.x for v in mesh.vertices):.3f} to {max(v.co.x for v in mesh.vertices):.3f}")
print(f"Y range: {min(v.co.y for v in mesh.vertices):.3f} to {max(v.co.y for v in mesh.vertices):.3f}")
