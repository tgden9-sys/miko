"""Make the runtime hover shell from the textured Trellis export."""
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

root = Path(__file__).resolve().parents[3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[sys.argv.index("--") + 1])
shell = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
bpy.context.view_layer.objects.active = shell
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bvh = BVHTree.FromPolygons([v.co for v in shell.data.vertices],
                           [p.vertices[:] for p in shell.data.polygons])
for x in (0, .11, .17, .21, .25):
    print("SOCKET", x, bvh.ray_cast(Vector((x, -2, .385)), Vector((0, 1, 0)))[0], flush=True)

# Centre the body on its hover pivot. The socket faces Blender -Y / Godot +Z.
for vertex in shell.data.vertices:
    vertex.co = (vertex.co - Vector((0, 0, .42))) * .86
shell.name = "HoverShell"
shell.data.calc_loop_triangles()
original = len(shell.data.loop_triangles)
modifier = shell.modifiers.new("Runtime triangle budget", "DECIMATE")
modifier.ratio = min(1, 1800 / original)
modifier.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=modifier.name)
for material in shell.data.materials:
    if not material:
        continue
    nodes = material.node_tree.nodes
    shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
    baked = shader.inputs["Base Color"].links[0].from_node
    for node in list(nodes):
        if node.type in {"NORMAL_MAP", "SEPARATE_COLOR"} or (node.type == "TEX_IMAGE" and node != baked):
            nodes.remove(node)
    baked.image.scale(1024, 1024)
    baked.image.pack()
    shader.inputs["Metallic"].default_value = 0
    shader.inputs["Roughness"].default_value = .83
shell.data.calc_loop_triangles()
print("TRIANGLES", original, len(shell.data.loop_triangles), flush=True)
bpy.ops.export_scene.gltf(filepath=str(root / "MovementLab/models/props/lab_hover_drone.glb"),
                          export_image_format="JPEG", export_jpeg_quality=92)
