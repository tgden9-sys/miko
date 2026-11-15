"""Split the Trellis hopper at its piston and decimate the runtime parts."""
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector

root = Path(__file__).resolve().parents[3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[sys.argv.index("--") + 1])
source = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bpy.context.view_layer.objects.active = source
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
source.data.calc_loop_triangles()
print("SOURCE", len(source.data.loop_triangles), flush=True)
material = source.data.materials[0]
nodes = material.node_tree.nodes
shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
baked = shader.inputs["Base Color"].links[0].from_node
for node in list(nodes):
    if node.type in {"NORMAL_MAP", "SEPARATE_COLOR"} or (node.type == "TEX_IMAGE" and node != baked):
        nodes.remove(node)
baked.image.scale(1024, 1024)
baked.image.pack()
shader.inputs["Metallic"].default_value = 0
shader.inputs["Roughness"].default_value = .82

joint = Vector((-.048, .155, .603))
scale = .86 / 1.6254
for name, upper, budget in [("MagnetFoot", False, 540), ("HopperShell", True, 960)]:
    part = bmesh.new()
    part.from_mesh(source.data)
    bmesh.ops.bisect_plane(part, geom=part.verts[:] + part.edges[:] + part.faces[:],
                           dist=.00001, plane_co=joint, plane_no=Vector((0, 0, 1)),
                           clear_inner=upper, clear_outer=not upper)
    # A slight taper allows the lower piston to slide inside the upper sleeve.
    if not upper:
        for vertex in part.verts:
            taper = min(max((vertex.co.z-.49)/.09, 0), 1)*.15
            for axis in (0, 1):
                vertex.co[axis] += (joint[axis]-vertex.co[axis])*taper
    seam = [edge for edge in part.edges if edge.is_boundary
            and all(abs(v.co.z-joint.z) < .0001 for v in edge.verts)]
    bmesh.ops.holes_fill(part, edges=seam, sides=0)
    bmesh.ops.triangulate(part, faces=part.faces[:])
    origin = joint if upper else Vector((0, 0, 0))
    for vertex in part.verts:
        vertex.co = (vertex.co-origin)*scale
    mesh = bpy.data.meshes.new(name)
    mesh.materials.append(material)
    part.to_mesh(mesh)
    part.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = origin*scale
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    reduction = obj.modifiers.new("Runtime triangle budget", "DECIMATE")
    reduction.ratio = min(1.0, budget/len(mesh.polygons))
    reduction.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=reduction.name)
    print(name, len(obj.data.polygons), flush=True)

bpy.data.objects.remove(source, do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(root/"MovementLab/models/props/lab_magnetic_hopper.glb"),
                          export_image_format="JPEG", export_jpeg_quality=92)
