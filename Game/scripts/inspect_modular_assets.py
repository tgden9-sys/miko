import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder_optimized.glb")
print("=== MOD02 OBJECTS ===")
for obj in bpy.context.scene.objects:
    print(obj.name, obj.type, "Dims:", obj.dimensions, "Loc:", obj.location)
    if obj.type == 'MESH':
        for s in obj.material_slots:
            if s.material and s.material.node_tree:
                for n in s.material.node_tree.nodes:
                    if n.type == 'TEX_IMAGE' and n.image:
                        print("  MOD02 Texture:", n.image.name, n.image.size[:])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod04_catwalk_deck_optimized.glb")
print("=== MOD04 OBJECTS ===")
for obj in bpy.context.scene.objects:
    print(obj.name, obj.type, "Dims:", obj.dimensions, "Loc:", obj.location)
    if obj.type == 'MESH':
        for s in obj.material_slots:
            if s.material and s.material.node_tree:
                for n in s.material.node_tree.nodes:
                    if n.type == 'TEX_IMAGE' and n.image:
                        print("  MOD04 Texture:", n.image.name, n.image.size[:])
