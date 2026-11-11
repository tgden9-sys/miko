import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder_optimized.glb")
obj = bpy.context.scene.objects[0]
mesh = obj.data

# Find which face (+X, -X, +Y, -Y) has the ladder
# The ladder protrudes out from one face
# Let's count vertices near each face bound
for axis, name in [(0, 'X'), (1, 'Y')]:
    min_v = [v for v in mesh.vertices if v.co[axis] < -0.25]
    max_v = [v for v in mesh.vertices if v.co[axis] > 0.25]
    print(f"Axis {name}: negative_count={len(min_v)}, positive_count={len(max_v)}")
