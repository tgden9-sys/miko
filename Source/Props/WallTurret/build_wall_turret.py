"""Split the textured turret at its hinge and export the two rigid game meshes."""
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
source_path = Path(sys.argv[sys.argv.index("--") + 1])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source_path))
source = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bpy.context.view_layer.objects.active = source
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
source.data.calc_loop_triangles()
print("SOURCE_TRIANGLES", len(source.data.loop_triangles), flush=True)

# Measured in Blender coordinates. +X is the muzzle direction.
backplate = Vector((-.572, .0, .9515))
pivot = Vector((-.044, .109, .956))
planes = [(0, -.178), (2, .526), (2, 1.397)]
scale = 1.34 / 1.9033
material = source.data.materials[0]
nodes = material.node_tree.nodes
for node in list(nodes):
    if node.type in {"NORMAL_MAP", "SEPARATE_COLOR"} or (
            node.type == "TEX_IMAGE" and node.image.name != "BakedTexture"):
        nodes.remove(node)
    elif node.type == "TEX_IMAGE":
        node.image.scale(1024, 1024)
        node.image.pack()
shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
shader.inputs["Metallic"].default_value = 0
shader.inputs["Roughness"].default_value = .84

split = bmesh.new()
split.from_mesh(source.data)
for axis, distance in planes:
    point = Vector((0, 0, 0))
    normal = point.copy()
    point[axis] = distance
    normal[axis] = 1
    bmesh.ops.bisect_plane(split, geom=split.verts[:] + split.edges[:] + split.faces[:],
                           dist=.00001, plane_co=point, plane_no=normal)

for name, origin, moving, budget in [
    ("WallMount", backplate, False, 1050),
    ("Emitter", pivot, True, 750),
]:
    part = split.copy()
    discard = []
    for face in part.faces:
        x, _, z = face.calc_center_median()
        is_emitter = x > -.178 and .526 < z < 1.397
        if is_emitter != moving:
            discard.append(face)
    bmesh.ops.delete(part, geom=discard, context="FACES")
    loose = [vert for vert in part.verts if not vert.link_faces]
    bmesh.ops.delete(part, geom=loose, context="VERTS")
    bmesh.ops.triangulate(part, faces=part.faces[:])
    for vert in part.verts:
        vert.co = (vert.co - origin) * scale
    mesh = bpy.data.meshes.new(name)
    mesh.materials.append(material)
    part.to_mesh(mesh)
    part.free()
    for face in mesh.polygons:
        face.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (origin - backplate) * scale
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    reduce = obj.modifiers.new("Triangle budget", "DECIMATE")
    reduce.ratio = min(1.0, budget / len(mesh.polygons))
    reduce.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=reduce.name)
    obj.data.calc_loop_triangles()
    print(name, len(obj.data.loop_triangles), flush=True)

split.free()
bpy.data.objects.remove(source, do_unlink=True)
output = ROOT / "MovementLab/models/props/lab_wall_turret.glb"
bpy.ops.export_scene.gltf(filepath=str(output), export_image_format="JPEG", export_jpeg_quality=92)
