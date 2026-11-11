import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform\mod02_column_ladder.glb")
obj = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]

# Let's inspect the geometry distribution:
# A ladder typically has horizontal rungs (parallel lines of vertices with specific Y/X coordinates).
# Let's find vertices with different X, Y coordinates:
verts = [v.co for v in obj.data.vertices]
print(f"Total vertices: {len(verts)}")
# Count vertices by quadrant:
# +X, -X, +Y, -Y
for name, cond in [
    ("+X side (X > 0.15)", lambda v: v.x > 0.15),
    ("-X side (X < -0.15)", lambda v: v.x < -0.15),
    ("+Y side (Y > 0.15)", lambda v: v.y > 0.15),
    ("-Y side (Y < -0.15)", lambda v: v.y < -0.15),
]:
    count = sum(1 for v in verts if cond(v))
    print(f"{name}: {count} vertices")
