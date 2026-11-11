"""Build the Gate Warden game mesh and adapt Miko's locomotion to its proportions."""
import json
import struct
import tempfile
from pathlib import Path
from zipfile import ZipFile

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
MIKO = ROOT / "Source/Character/MIKO8"
OUT = ROOT / "MovementLab/models/AgileDroid_Rigged.glb"

bpy.ops.wm.open_mainfile(filepath=str(MIKO / "MIKO8_Native_Animated.blend"))
scene = bpy.context.scene
source = next(obj for obj in scene.objects if obj.type == "ARMATURE")
for obj in list(scene.objects):
    if obj != source:
        bpy.data.objects.remove(obj, do_unlink=True)
source.animation_data.use_nla = False
rig = source.copy()
rig.data = source.data.copy()
rig.animation_data_clear()
rig.name = "GateWardenRig"
scene.collection.objects.link(rig)

bpy.ops.import_scene.gltf(filepath=str(Path(r"C:\Users\tgden\Downloads\bot_Textured_56791102900.glb")))
mesh = next(obj for obj in scene.objects if obj.type == "MESH")
mesh.name = "GateWardenMesh"
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh.scale *= 1.9 / mesh.dimensions.z
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
original_triangles = sum(len(face.vertices) - 2 for face in mesh.data.polygons)
reduction = mesh.modifiers.new("Runtime triangle budget", "DECIMATE")
reduction.ratio = min(1.0, 6000 / original_triangles)
reduction.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=reduction.name)
for material in mesh.data.materials:
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image and max(node.image.size) > 1024:
            image = node.image
            factor = 1024 / max(image.size)
            image.scale(*(round(size * factor) for size in image.size))
            image.pack()

# Measured against the imported A-pose, in Blender metres with -Y forward.
points = {
    "DEF-hips": (0, .026, .917),
    "DEF-spine.001": (0, .022, 1.045),
    "DEF-spine.002": (0, .02, 1.174),
    "DEF-spine.003": (0, .018, 1.338),
    "DEF-neck": (0, .003, 1.548),
    "DEF-head": (0, .001, 1.638),
}
next_bone = dict(zip(list(points)[:-1], list(points)[1:]))
for side, sign in [("L", 1), ("R", -1)]:
    limbs = {
        "shoulder": (.058, .007, 1.479),
        "upper_arm": (.218, .008, 1.458),
        "forearm": (.401, .015, 1.217),
        "hand": (.536, -.014, .985),
        "thigh": (.117, .029, .89),
        "shin": (.157, .052, .51),
        "foot": (.177, .071, .153),
        "toe": (.177, -.126, .06),
    }
    for name, (x, y, z) in limbs.items():
        points[f"DEF-{name}.{side}"] = (x * sign, y, z)
    for parent, child in [("shoulder", "upper_arm"), ("upper_arm", "forearm"),
                          ("forearm", "hand"), ("thigh", "shin"), ("shin", "foot"), ("foot", "toe")]:
        next_bone[f"DEF-{parent}.{side}"] = f"DEF-{child}.{side}"

reference = {bone.name: bone.matrix_local.copy() for bone in source.data.bones}
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for bone in rig.data.edit_bones:
    bone.use_connect = False
    if bone.name not in points:
        continue
    old = bone.matrix.to_3x3()
    bone.head = points[bone.name]
    if bone.name in next_bone:
        bone.tail = points[next_bone[bone.name]]
    elif bone.name == "DEF-head":
        bone.tail = bone.head + Vector((0, 0, .23))
    elif "hand" in bone.name:
        sign = 1 if bone.name.endswith(".L") else -1
        bone.tail = bone.head + Vector((.075 * sign, 0, -.105))
    else:
        bone.tail = bone.head + Vector((0, -.08, -.01))
    correction = old.col[1].rotation_difference((bone.tail - bone.head).normalized())
    bone.align_roll(correction @ old.col[2])
# Keep the finger hierarchy for later idle clips. Patrol gloves use hand weights.
for side in ("L", "R"):
    hand = rig.data.edit_bones[f"DEF-hand.{side}"]
    transform = hand.matrix @ reference[hand.name].inverted()
    for bone in rig.data.edit_bones:
        if bone.name.endswith("." + side) and ("DEF-f_" in bone.name or "DEF-thumb." in bone.name):
            bone.matrix = transform @ reference[bone.name]
bpy.ops.object.mode_set(mode="OBJECT")

verts = np.empty(len(mesh.data.vertices) * 3, dtype=np.float32)
mesh.data.vertices.foreach_get("co", verts)
verts = verts.reshape(-1, 3)
names = [name for name in points if not name.startswith("DEF-shoulder")]
weights = np.zeros((len(verts), len(names)), dtype=np.float32)
x, y, z = verts.T
arm = (np.abs(x) > np.interp(z, [.8, 1.18, 1.39, 1.58], [.33, .30, .245, .21])) & (z > .76) & (z < 1.59)
for i, name in enumerate(names):
    bone = rig.data.bones[name]
    head = np.array(bone.head_local)
    axis = np.array(bone.tail_local) - head
    fraction = np.clip((verts - head) @ axis / (axis @ axis), 0, 1)
    distance = np.sum((verts - head - fraction[:, None] * axis) ** 2, axis=1)
    if name.endswith((".L", ".R")):
        valid = x > 0 if name.endswith(".L") else x < 0
        valid &= arm if any(label in name for label in ("arm", "hand")) else (~arm & (z < 1.01))
    else:
        valid = ~arm & (z > .79)
        if name == "DEF-head":
            valid &= z > 1.58
        else:
            valid &= z < 1.65
    weights[:, i] = np.where(valid, 1.0 / (distance + .0015) ** 3.5, 0)
empty = weights.sum(axis=1) == 0
weights[empty, names.index("DEF-hips")] = 1.0
indices = np.argpartition(weights, -3, axis=1)[:, -3:]
top = np.take_along_axis(weights, indices, axis=1)
top /= top.sum(axis=1, keepdims=True)
top[top < .02] = 0
top /= top.sum(axis=1, keepdims=True)
for i, name in enumerate(names):
    group = mesh.vertex_groups.new(name=name)
    quantized = np.rint(np.where(indices == i, top, 0).sum(axis=1) * 255).astype(int)
    for value in np.unique(quantized):
        if value:
            group.add(np.flatnonzero(quantized == value).tolist(), value / 255, "REPLACE")
mesh.parent = rig
skin = mesh.modifiers.new("Gate Warden skin", "ARMATURE")
skin.object = rig
rig.animation_data_create()

# Sample the original Miko clips in armature space, preserving the Warden's
# fitted joint locations. Shift the root vertically so the lowest boot stays grounded.
IDLES = {
    "LookAround": "idle-look-around-loop-alternate-2-1.0.5.zip",
    "FoldArms": "idle-fold-arms-loop-1.0.6.zip",
}
TEMPLATES = {**IDLES, "Death": "death02-1.0.5.zip", "Guard": "sword-block-alternate-2-1.0.6.zip", "Slash": "sword-regular-a-1.0.5.zip"}
JOINT_MAP = dict(zip(list(points)[:6], ["hips", "spine", "chest", "upperChest", "neck", "head"]))
for side, prefix in [("L", "left"), ("R", "right")]:
    for name, joint in zip(limbs, ["Shoulder", "UpperArm", "LowerArm", "Hand", "UpperLeg", "LowerLeg", "Foot", "Toes"]):
        JOINT_MAP[f"DEF-{name}.{side}"] = prefix + joint


def import_template(label):
    """Sample the template's rest-relative joint motion on the canonical axes."""
    with ZipFile(ROOT / "AnimationTemplates" / TEMPLATES[label]) as archive:
        raw = archive.read(next(name for name in archive.namelist() if name.endswith(".glb")))
    document = json.loads(raw[20:20 + struct.unpack_from("<I", raw, 12)[0]])
    nodes = document["nodes"]
    parents = {child: i for i, node in enumerate(nodes) for child in node.get("children", [])}
    to_blender = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

    def rest_world(index):
        node = nodes[index]
        x, y, z, w = node.get("rotation", [0, 0, 0, 1])
        local = Matrix.LocRotScale(Vector(node.get("translation", [0, 0, 0])),
                                   Quaternion((w, x, y, z)), Vector(node.get("scale", [1, 1, 1])))
        return rest_world(parents[index]) @ local if index in parents else local

    by_name = {node["name"]: i for i, node in enumerate(nodes)}
    correction = {}
    for bone, joint in JOINT_MAP.items():
        if joint in by_name:
            rest = to_blender @ rest_world(by_name[joint]) @ to_blender.inverted()
            correction[bone] = rest.inverted() @ reference[bone]
    before = set(bpy.data.objects)
    with tempfile.TemporaryDirectory(dir=BASE) as temp:
        clip = Path(temp) / "idle.glb"
        clip.write_bytes(raw)
        bpy.ops.import_scene.gltf(filepath=str(clip))
    objects = set(bpy.data.objects) - before
    controls = {obj.name.split(".")[0]: obj for obj in objects}
    duration = max(document["accessors"][sampler["input"]]["max"][0]
                   for sampler in document["animations"][0]["samplers"])
    return objects, controls, correction, round(duration * scene.render.fps)


sole = np.flatnonzero(z < .085)
output_actions = []
for label in ["Idle", "Walk", "Turn180Right", *TEMPLATES]:
    template = label in TEMPLATES
    if template:
        objects, controls, correction, last = import_template(label)
        first = 0
    else:
        original = bpy.data.actions["MIKO8_" + label]
        source.animation_data.action = original
        if original.slots:
            source.animation_data.action_slot = original.slots[0]
        first, last = (round(frame) for frame in original.frame_range)
    action = bpy.data.actions.new("Warden_" + label)
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    grounding_vertices = np.arange(len(verts)) if label == "Death" else sole
    first_hip_position = None
    for sample, frame in enumerate(range(first, last + 1)):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        current = {}
        for pose in rig.pose.bones:
            pose.rotation_mode = "QUATERNION"
            pose.location = (0, 0, 0)
            rest = pose.bone.matrix_local.to_quaternion()
            if pose.name == "root":
                rotation = rest
            elif pose.name not in points:
                parent_rest = pose.parent.bone.matrix_local.to_quaternion()
                rotation = current[pose.parent.name] @ parent_rest.inverted() @ rest
            elif template and pose.name in correction:
                rotation = (controls[JOINT_MAP[pose.name]].matrix_world @ correction[pose.name]).to_quaternion()
            elif not template:
                rotation = source.pose.bones[pose.name].matrix.to_quaternion()
            else:
                rotation = current[pose.parent.name] @ pose.parent.bone.matrix_local.to_quaternion().inverted() @ rest
            current[pose.name] = rotation
            if pose.parent:
                parent_rest = pose.parent.bone.matrix_local.to_quaternion()
                result = (parent_rest.inverted() @ rest).inverted() @ current[pose.parent.name].inverted() @ rotation
            else:
                result = rest.inverted() @ rotation
            if pose.name in previous:
                result.make_compatible(previous[pose.name])
            previous[pose.name] = result.copy()
            pose.rotation_quaternion = result

        bpy.context.view_layer.update()
        grounded = np.zeros((len(grounding_vertices), 3))
        for i, name in enumerate(names):
            matrix = np.array(rig.pose.bones[name].matrix @ rig.data.bones[name].matrix_local.inverted())
            weight = np.where(indices[grounding_vertices] == i, top[grounding_vertices], 0).sum(axis=1)
            grounded += (verts[grounding_vertices] @ matrix[:3, :3].T + matrix[:3, 3]) * weight[:, None]
        root_bone = rig.pose.bones["root"]
        offset = Vector((0, 0, -grounded[:, 2].min()))
        if label == "Death":
            hip = (controls["hips"].matrix_world @ correction["DEF-hips"]).translation
            if first_hip_position is None:
                first_hip_position = hip.copy()
            offset.x = hip.x - first_hip_position.x
            offset.y = hip.y - first_hip_position.y
        root_bone.location = root_bone.bone.matrix_local.to_3x3().inverted() @ offset
        for pose in rig.pose.bones:
            pose.keyframe_insert("rotation_quaternion", frame=sample, group=pose.name)
        root_bone.keyframe_insert("location", frame=sample, group="root")
    print("WARDEN_CLIP", label, first, last, flush=True)
    output_actions.append(action)
    rig.animation_data.action = None
    if template:
        for obj in objects:
            bpy.data.objects.remove(obj, do_unlink=True)

bpy.data.objects.remove(source, do_unlink=True)
for pose in rig.pose.bones:
    pose.matrix_basis.identity()
for action in output_actions:
    track = rig.animation_data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, 0, action)
    if action.slots:
        strip.action_slot = action.slots[0]
scene.frame_set(0)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.wm.save_as_mainfile(filepath=str(BASE / "AgileDroid_Rigged.blend"))
bpy.ops.export_scene.gltf(filepath=str(OUT), use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_force_sampling=True, export_skins=True)
count = sum(len(face.vertices) - 2 for face in mesh.data.polygons)
print("WARDEN_EXPORT_COMPLETE", original_triangles, count, flush=True)



