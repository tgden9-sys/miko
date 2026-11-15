"""Prepare the supplied Relay Core and rail gun GLBs for Movement Lab."""
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector


OUTPUT = Path(__file__).resolve().parents[2] / "MovementLab/models/props"


def load_model(path, texture_size):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    source = next(obj for obj in bpy.context.scene.objects if obj.type == 'MESH')
    bpy.context.view_layer.objects.active = source
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    source.data.calc_loop_triangles()
    print(path, len(source.data.loop_triangles), 'source triangles', flush=True)
    material = source.data.materials[0]
    nodes = material.node_tree.nodes
    shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
    baked = shader.inputs['Base Color'].links[0].from_node
    for node in list(nodes):
        if node.type in {'NORMAL_MAP', 'SEPARATE_COLOR', 'SEPRGB'} or (
                node.type == 'TEX_IMAGE' and node != baked):
            nodes.remove(node)
    width, height = baked.image.size
    factor = min(1.0, texture_size / max(width, height))
    if factor < 1.0:
        baked.image.scale(round(width * factor), round(height * factor))
    baked.image.pack()
    shader.inputs['Metallic'].default_value = .0
    shader.inputs['Roughness'].default_value = .83
    return source


def part(source, name, origin, scale, budget, barrel=None):
    geometry = bmesh.new()
    geometry.from_mesh(source.data)
    if barrel is not None:
        # In the reconstruction only the arm protrudes past this depth.
        cut = Vector((0, -.113, 0))
        bmesh.ops.bisect_plane(geometry, geom=geometry.verts[:] + geometry.edges[:] + geometry.faces[:],
                               dist=.00001, plane_co=cut, plane_no=Vector((0, 1, 0)),
                               clear_inner=not barrel, clear_outer=barrel)
        seam = [edge for edge in geometry.edges if edge.is_boundary and
                all(abs(vertex.co.y - cut.y) < .0001 for vertex in edge.verts)]
        bmesh.ops.holes_fill(geometry, edges=seam, sides=0)
    bmesh.ops.triangulate(geometry, faces=geometry.faces[:])
    for vertex in geometry.verts:
        vertex.co = (vertex.co - origin) * scale
    mesh = bpy.data.meshes.new(name)
    mesh.materials.append(source.data.materials[0])
    geometry.to_mesh(mesh)
    geometry.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('Runtime triangle budget', 'DECIMATE')
    modifier.ratio = min(1.0, budget / len(mesh.polygons))
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    print(name, len(mesh.polygons), 'runtime triangles', flush=True)
    return obj


def export(source, filename):
    bpy.data.objects.remove(source, do_unlink=True)
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT / filename),
                              export_image_format='JPEG', export_jpeg_quality=91)


rail_path, core_path = sys.argv[sys.argv.index('--') + 1:]
rail = load_model(rail_path, 1024)
axles = Vector((0, .346, 1.724))
joint = Vector((.021, -.109, .644))
part(rail, 'RailCarriage', axles, 1.10, 1780, barrel=False)
barrel = part(rail, 'RailBarrel', joint, 1.10, 640, barrel=True)
barrel.location = (joint - axles) * 1.10
export(rail, 'lab_rail_gun.glb')

core = load_model(core_path, 512)
part(core, 'RelayCore', Vector((0, 0, .347)), .44, 680)
export(core, 'lab_relay_core.glb')
