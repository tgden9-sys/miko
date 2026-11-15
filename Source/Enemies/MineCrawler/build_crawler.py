"""Level the Trellis chassis, separate its hatch, and export the runtime mesh."""

from math import radians
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector


def build_part(name, budget, hatch):
    part = bmesh.new()
    part.from_mesh(source.data)
    bmesh.ops.remove_doubles(part, verts=part.verts[:], dist=.00003)
    seam_point = Vector((.614, 0, 1.07))
    seam_normal = Vector((1, 0, .39)).normalized()
    bmesh.ops.bisect_plane(
        part, geom=part.verts[:] + part.edges[:] + part.faces[:],
        dist=.00001, plane_co=seam_point, plane_no=seam_normal,
        clear_inner=hatch, clear_outer=not hatch,
    )
    edges = [edge for edge in part.edges if edge.is_boundary and all(
        abs((vertex.co - seam_point).dot(seam_normal)) < .0001
        for vertex in edge.verts
    )]
    caps = bmesh.ops.holes_fill(part, edges=edges, sides=0)["faces"]
    for face in caps:
        face.material_index = 1
    bmesh.ops.triangulate(part, faces=part.faces[:])
    origin = fitted(Vector((.701, 0, 1.079))) if hatch else Vector()
    for vertex in part.verts:
        vertex.co = fitted(vertex.co) - origin
    mesh = bpy.data.meshes.new(name)
    for material in (paint, interior):
        mesh.materials.append(material)
    part.to_mesh(mesh)
    part.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = polygon.material_index == 0
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = origin
    bpy.context.view_layer.objects.active = obj
    reduction = obj.modifiers.new("Runtime triangle budget", "DECIMATE")
    reduction.ratio = min(1.0, budget / len(mesh.polygons))
    reduction.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=reduction.name)
    obj.data.calc_loop_triangles()
    print(name, len(obj.data.loop_triangles), "cap faces:", len(caps), "pivot:", tuple(origin), flush=True)


root = Path(__file__).resolve().parents[3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[sys.argv.index("--") + 1])
source = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bpy.context.view_layer.objects.active = source
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
source.data.calc_loop_triangles()
print("Source triangles:", len(source.data.loop_triangles), flush=True)

paint = source.data.materials[0]
paint.name = "CrawlerPaint"
nodes = paint.node_tree.nodes
shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
baked = shader.inputs["Base Color"].links[0].from_node
baked.image.name = "BakedTexture"
baked.image.scale(1024, 1024)
baked.image.pack()
for node in list(nodes):
    if node not in (baked, shader) and node.type != "OUTPUT_MATERIAL":
        nodes.remove(node)
shader.inputs["Metallic"].default_value = 0
shader.inputs["Roughness"].default_value = .78
interior = bpy.data.materials.new("HatchInterior")
interior.use_nodes = True
interior_shader = interior.node_tree.nodes.get("Principled BSDF")
interior_shader.inputs["Base Color"].default_value = (.035, .030, .024, 1)
interior_shader.inputs["Roughness"].default_value = .84

# Level the molded track mounts before aligning the underside to the wheels.
level = Matrix.Rotation(radians(12.5), 3, "Y")
scale = .83
bottom = min((level @ vertex.co).z for vertex in source.data.vertices)


def fitted(point):
    point = level @ point
    return Vector(((point.x - .065) * scale, point.y * scale, (point.z - bottom) * scale + .14))


build_part("CrawlerChassis", 1550, False)
build_part("CrawlerHatch", 360, True)
bpy.data.objects.remove(source, do_unlink=True)
bpy.ops.export_scene.gltf(
    filepath=str(root / "MovementLab/models/props/lab_mine_crawler.glb"),
    export_image_format="JPEG", export_jpeg_quality=90,
)
