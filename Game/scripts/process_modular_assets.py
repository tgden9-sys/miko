import bpy
import os
import math
from mathutils import Vector, Matrix

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def process_mod04(input_path, output_path):
    clear_scene()
    print("Importing MOD04:", input_path)
    bpy.ops.import_scene.gltf(filepath=input_path)
    
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    if not mesh_objs:
        print("No mesh found in MOD04!")
        return
    
    bpy.context.view_layer.objects.active = mesh_objs[0]
    for obj in mesh_objs:
        obj.select_set(True)
    if len(mesh_objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object

    init_faces = len(obj.data.polygons)
    print(f"MOD04 initial faces: {init_faces}")
    
    ratio = min(1.0, 18000.0 / max(1, init_faces))
    mod = obj.modifiers.new("Decimate", type='DECIMATE')
    mod.ratio = ratio
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print(f"MOD04 decimated to: {len(obj.data.polygons)} faces (ratio {ratio:.4f})")
    
    mesh = obj.data
    verts = [v.co for v in mesh.vertices]
    dim_x = max(v.x for v in verts) - min(v.x for v in verts)
    dim_y = max(v.y for v in verts) - min(v.y for v in verts)
    dim_z = max(v.z for v in verts) - min(v.z for v in verts)
    print(f"MOD04 initial mesh dimensions: X={dim_x:.3f}, Y={dim_y:.3f}, Z={dim_z:.3f}")
    
    # In raw glTF: Y is 1.897m (long length), X is 0.795m (width), Z is 0.686m (height)
    # Rotate vertices 90 deg around Z directly on mesh:
    # X_new = -Y_old, Y_new = X_old
    rot_mat = Matrix.Rotation(math.radians(90.0), 4, 'Z')
    mesh.transform(rot_mat)
    
    verts = [v.co for v in mesh.vertices]
    dim_x = max(v.x for v in verts) - min(v.x for v in verts)
    dim_y = max(v.y for v in verts) - min(v.y for v in verts)
    dim_z = max(v.z for v in verts) - min(v.z for v in verts)
    print(f"MOD04 mesh dimensions after vertex rotation: X(length)={dim_x:.3f}, Y(width)={dim_y:.3f}, Z(height)={dim_z:.3f}")
    
    # Scale uniformly so X (length) = 2.40m:
    scale_factor = 2.40 / dim_x
    print(f"Scaling mesh uniformly by {scale_factor:.4f}...")
    scale_mat = Matrix.Scale(scale_factor, 4)
    mesh.transform(scale_mat)
    
    # Translate mesh so min_z = 0, center_x = 0, center_y = 0:
    verts = [v.co for v in mesh.vertices]
    min_x = min(v.x for v in verts)
    max_x = max(v.x for v in verts)
    min_y = min(v.y for v in verts)
    max_y = max(v.y for v in verts)
    min_z = min(v.z for v in verts)
    max_z = max(v.z for v in verts)
    
    trans_mat = Matrix.Translation(Vector((-(min_x + max_x) * 0.5, -(min_y + max_y) * 0.5, -min_z)))
    mesh.transform(trans_mat)
    mesh.update()
    
    verts = [v.co for v in mesh.vertices]
    size_x = max(v.x for v in verts) - min(v.x for v in verts)
    size_y = max(v.y for v in verts) - min(v.y for v in verts)
    size_z = max(v.z for v in verts) - min(v.z for v in verts)
    print(f"MOD04 final mesh size: length(X)={size_x:.3f}, width(Y)={size_y:.3f}, height(Z)={size_z:.3f}")
    print(f"MOD04 final bounds: X=[{min(v.x for v in verts):.3f}, {max(v.x for v in verts):.3f}], Y=[{min(v.y for v in verts):.3f}, {max(v.y for v in verts):.3f}], Z=[{min(v.z for v in verts):.3f}, {max(v.z for v in verts):.3f}]")
    
    print("Exporting optimized MOD04:", output_path)
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB', use_selection=True)

if __name__ == '__main__':
    base_dir = r"C:\Users\tgden\Desktop\miko\Game\models\environment\modular_platform"
    mod04_in = os.path.join(base_dir, "mod04_catwalk_deck.glb")
    mod04_out = os.path.join(base_dir, "mod04_catwalk_deck_optimized.glb")
    process_mod04(mod04_in, mod04_out)
    print("MOD04 OPTIMIZED SUCCESSFULLY!")
