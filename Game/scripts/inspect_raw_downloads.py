import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Downloads\mod02_modular_column_ladder_1793636742624_Textured_55524100578.glb")

print("=== RAW MOD02 IN DOWNLOADS ===")
for obj in bpy.context.scene.objects:
    print(f"Object: {obj.name}, type={obj.type}, dim={obj.dimensions}")
    if obj.type == 'MESH':
        print(f"  Materials: {[m.name for m in obj.data.materials if m]}")
        verts = [v.co for v in obj.data.vertices]
        print(f"  Bounds: X=[{min(v.x for v in verts):.3f}, {max(v.x for v in verts):.3f}], Y=[{min(v.y for v in verts):.3f}, {max(v.y for v in verts):.3f}], Z=[{min(v.z for v in verts):.3f}, {max(v.z for v in verts):.3f}]")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Downloads\mod04_catwalk_deck_isolated_1793637019957_Textured_55525100581.glb")

print("=== RAW MOD04 IN DOWNLOADS ===")
for obj in bpy.context.scene.objects:
    print(f"Object: {obj.name}, type={obj.type}, dim={obj.dimensions}")
    if obj.type == 'MESH':
        print(f"  Materials: {[m.name for m in obj.data.materials if m]}")
        verts = [v.co for v in obj.data.vertices]
        print(f"  Bounds: X=[{min(v.x for v in verts):.3f}, {max(v.x for v in verts):.3f}], Y=[{min(v.y for v in verts):.3f}, {max(v.y for v in verts):.3f}], Z=[{min(v.z for v in verts):.3f}, {max(v.z for v in verts):.3f}]")
