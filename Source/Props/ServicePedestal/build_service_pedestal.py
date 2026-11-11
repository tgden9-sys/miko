"""Blender: rebuild the scan's socket and export the game mesh from original.glb."""
import math
from pathlib import Path
import tempfile

import bpy
from mathutils import Vector

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / "Game/models/props/service_pedestal/service_pedestal.glb"
ATLAS = ROOT / "Builds/Validation/ServicePedestal/pedestal_paint.png"
ATLAS.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(ATLAS.parent)
CENTER = (-.13, -.016)
SCALE = .87
BODY_TARGET = 10200


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Roughness"].default_value = .9
    mat.diffuse_color = (*color, 1)
    return mat


def ring(name, profile, paint, count=48, front_drop=0., groove=None, groove_paint=None):
    # The profile proceeds from the inner bottom up and over the rim.
    verts = [
        (CENTER[0]+r*math.cos(i*math.tau/count),
         CENTER[1]+r*math.sin(i*math.tau/count),
         z-front_drop*max(0., -math.sin(i*math.tau/count))**2 *
         min(1., max(0., (z-.997)/.08)))
        for r, z in profile for i in range(count)
    ]
    faces = []
    for j in range(len(profile)):
        a, b = j*count, ((j+1) % len(profile))*count
        for i in range(count):
            k = (i+1) % count
            faces.append((a+i, b+i, b+k, a+k))
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(paint)
    if groove_paint is not None:
        obj.data.materials.append(groove_paint)
        for face in data.polygons:
            if face.index//count in groove:
                face.material_index = 1
    return obj


def disc(name, radius, z, depth, paint):
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=depth,
                                       location=(*CENTER, z))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(paint)
    return obj


def bevel_box(name, dims, loc, angle, paint):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = obj.modifiers.new("Machined edges", "BEVEL")
    bevel.width = .006
    bevel.segments = 1
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.rotation_euler.z = angle
    obj.data.materials.append(paint)
    return obj


bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE / "original.glb"), merge_vertices=True)
shell = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
shell.name = "CastHousing"
source_faces = len(shell.data.polygons)
paint = shell.data.materials[0]
paint.name = "PedestalPaint"
nodes = paint.node_tree.nodes
principled = nodes.get("Principled BSDF")
base = principled.inputs["Base Color"].links[0].from_node
for node in list(nodes):
    if node not in (base, principled) and node.type != "OUTPUT_MATERIAL":
        nodes.remove(node)
atlas = base.image
atlas.scale(1280, 1280)
atlas.filepath_raw = str(ATLAS)
atlas.file_format = "PNG"
atlas.save()
base.image = bpy.data.images.load(str(ATLAS), check_existing=False)
principled.inputs["Metallic"].default_value = 0
principled.inputs["Roughness"].default_value = .9

# Remove the reconstructed ring and its torn inner walls. The new flange
# covers the perimeter of this cut, so the original shelf stays intact.
bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=.393, depth=.29,
                                   location=(*CENTER, 1.089))
cut = bpy.context.object
active(shell)
boolean = shell.modifiers.new("Clear scan socket", "BOOLEAN")
boolean.object = cut
boolean.operation = "DIFFERENCE"
boolean.solver = "EXACT"
bpy.ops.object.modifier_apply(modifier=boolean.name)
bpy.data.objects.remove(cut, do_unlink=True)

decimate = shell.modifiers.new("Game geometry", "DECIMATE")
decimate.ratio = min(1., BODY_TARGET / len(shell.data.polygons))
decimate.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=decimate.name)
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(48), keep_sharp_edges=False)

steel = material("SocketSteel", (.17, .19, .186))
rubber = material("SocketGasket", (.038, .047, .050))
copper = material("SocketCopper", (.56, .27, .085))
hardware = [
    disc("BackingPlate", .402, .990, .012, rubber),
    disc("RecessFloor", .251, 1.006, .022, rubber),
    ring("MachinedCollar", [
        (.234, .990), (.234, 1.083), (.250, 1.101), (.357, 1.101),
        (.385, 1.078), (.400, 1.036), (.400, 1.028), (.392, 1.023),
        (.392, 1.015), (.400, 1.010), (.400, .997),
    ], steel, front_drop=.036, groove={6, 7, 8}, groove_paint=rubber),
    ring("InsetGasket", [
        (.226, 1.012), (.226, 1.037), (.232, 1.046), (.245, 1.046),
        (.249, 1.014),
    ], rubber, 36),
]
for i in range(4):
    angle = math.tau*(i+.5)/4
    radial, tangent = Vector((math.cos(angle), math.sin(angle))), Vector((-math.sin(angle), math.cos(angle)))
    xy = Vector(CENTER) + radial*.256
    hardware.append(bevel_box("InsulatedContact", (.118, .145, .058),
                              (*xy, 1.057), angle, rubber))
    for offset in [-.037, 0., .037]:
        finger = xy - radial*.012 + tangent*offset
        hardware.append(bevel_box("CopperFinger", (.079, .022, .034),
                                  (*finger, 1.088), angle, copper))

active(hardware[0])
for piece in hardware:
    piece.select_set(True)
bpy.ops.object.join()
socket = bpy.context.object
socket.name = "MachinedSocket"

# Godot uses +Z for the front. Keep that orientation and a floor-level origin.
for obj in (shell, socket):
    active(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for v in obj.data.vertices:
        v.co *= SCALE
        if v.co.z < .0001:
            v.co.z = 0.
    obj.data.update()

active(shell)
socket.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB",
                         use_selection=True, export_image_format="JPEG",
                         export_jpeg_quality=93, export_tangents=False)
triangles = sum(len(p.vertices)-2 for obj in (shell, socket) for p in obj.data.polygons)
print(f"SERVICE_PEDESTAL source={source_faces} final={triangles} bytes={OUTPUT.stat().st_size}")
