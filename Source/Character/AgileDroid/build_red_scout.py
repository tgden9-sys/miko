"""Build the red scout mesh, fit the skeleton and bake Miko locomotion."""
from pathlib import Path
import sys

import bpy
import numpy as np
from mathutils import Vector

BASE = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE))
from red_scout_attacks import build_attacks

ROOT = BASE.parents[2]
MIKO = ROOT / "Source/Character/MIKO8"
OUT = ROOT / "MovementLab/models/RedScout.glb"

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
rig.name = "RedScoutRig"
scene.collection.objects.link(rig)

bpy.ops.import_scene.gltf(filepath=str(Path(sys.argv[sys.argv.index("--")+1])))
mesh = next(obj for obj in scene.objects if obj.type == "MESH")
mesh.name = "RedScoutMesh"
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
mesh.scale *= 1.9 / mesh.dimensions.z
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
original_triangles = sum(len(face.vertices) - 2 for face in mesh.data.polygons)
reduction = mesh.modifiers.new("Runtime triangle budget", "DECIMATE")
reduction.ratio = min(1.0, 3200 / original_triangles)
reduction.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=reduction.name)
for material in mesh.data.materials:
    nodes = material.node_tree.nodes
    for node in list(nodes):
        if node.type in {"NORMAL_MAP", "SEPARATE_COLOR"} or (
                node.type == "TEX_IMAGE" and node.image.name != "BakedTexture"):
            nodes.remove(node)
        elif node.type == "TEX_IMAGE" and max(node.image.size) > 1024:
            image = node.image
            factor = 1024 / max(image.size)
            image.scale(*(round(size * factor) for size in image.size))
            image.pack()
    shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Metallic"].default_value = 0
    shader.inputs["Roughness"].default_value = .82

# Measured against the imported A-pose, in Blender metres with -Y forward.
points = {
    "DEF-hips": (0, .050, .924),
    "DEF-spine.001": (0, .054, 1.079),
    "DEF-spine.002": (0, .051, 1.22),
    "DEF-spine.003": (0, .032, 1.378),
    "DEF-neck": (0, .020, 1.592),
    "DEF-head": (0, .016, 1.718),
}
next_bone = dict(zip(list(points)[:-1], list(points)[1:]))
for side, sign in [("L", 1), ("R", -1)]:
    limbs = {
        "shoulder": (.080, .036, 1.516),
        "upper_arm": (.240, .062, 1.518),
        "forearm": (.425, .122, 1.210),
        "hand": (.609, .050, .927),
        "thigh": (.161, .063, .889),
        "shin": (.248, .022, .515),
        "foot": (.287, .183, .187),
        "toe": (.309, -.125, .052),
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
        bone.tail = bone.head + Vector((.015 * sign, -.016, -.19))
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
arm = (np.abs(x) > np.interp(z, [.58, .96, 1.18, 1.42, 1.59], [.42, .39, .30, .196, .20])) & (z > .56) & (z < 1.61)
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
        valid = ~arm & (z > .81)
        if name == "DEF-head":
            valid &= z > 1.665
        else:
            valid &= z < 1.725
    weights[:, i] = np.where(valid, 1.0 / (distance + .0015) ** 4.5, 0)
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
skin = mesh.modifiers.new("Red Scout skin", "ARMATURE")
skin.object = rig
rig.animation_data_create()


# Retarget in armature space. Keep the fitted segment lengths and bake the root
# height from the soles for ground clips. The game owns the ballistic arc.
sole = np.flatnonzero(z < .075)
output_actions = []
for label in ["Idle", "Walk", "Run", "JumpStart", "JumpAir", "JumpLand"]:
    original = bpy.data.actions.get("MIKO8_" + label)
    if not original:
        raise RuntimeError(f"Missing source clip {label}: {list(bpy.data.actions.keys())}")
    source.animation_data.action = original
    source.animation_data.action_slot = original.slots[0]
    first, last = (round(frame) for frame in original.frame_range)
    action = bpy.data.actions.new("Scout_" + label)
    action.use_fake_user = True
    rig.animation_data.action = action
    previous = {}
    stance = []
    for sample, frame in enumerate(range(first,last+1)):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        world_rotations = {}
        for pose in rig.pose.bones:
            pose.rotation_mode = "QUATERNION"
            pose.location = (0,0,0)
            rest = pose.bone.matrix_local.to_quaternion()
            if pose.name == "root":
                rotation = rest
            elif pose.name in points:
                rotation = source.pose.bones[pose.name].matrix.to_quaternion()
                if pose.name == "DEF-head":
                    # Keep the flat visor level enough to read through the landing.
                    rotation = rotation.slerp(rest, .38)
            else:
                parent_rest = pose.parent.bone.matrix_local.to_quaternion()
                rotation = world_rotations[pose.parent.name] @ parent_rest.inverted() @ rest
            world_rotations[pose.name] = rotation
            if pose.parent:
                parent_rest = pose.parent.bone.matrix_local.to_quaternion()
                result = (parent_rest.inverted() @ rest).inverted() @ world_rotations[pose.parent.name].inverted() @ rotation
            else:
                result = rest.inverted() @ rotation
            if pose.name in previous:
                result.make_compatible(previous[pose.name])
            previous[pose.name] = result.copy()
            pose.rotation_quaternion = result

        bpy.context.view_layer.update()
        boot_points = np.zeros((len(sole),3))
        for i,name in enumerate(names):
            matrix = np.array(rig.pose.bones[name].matrix @ rig.data.bones[name].matrix_local.inverted())
            weight = np.where(indices[sole] == i,top[sole],0).sum(axis=1)
            boot_points += (verts[sole] @ matrix[:3,:3].T+matrix[:3,3])*weight[:,None]
        correction = -boot_points[:,2].min()
        stance.append(boot_points.copy())
        if label == "JumpAir":
            correction = min(correction,.045)
        root = rig.pose.bones["root"]
        root.location = root.bone.matrix_local.to_3x3().inverted() @ Vector((0,0,correction))
        root.keyframe_insert("location",frame=sample,group="root")
        for pose in rig.pose.bones:
            if pose.name in points:
                pose.keyframe_insert("rotation_quaternion",frame=sample,group=pose.name)
    print("SCOUT_CLIP",label,first,last,flush=True)
    if label == "Walk":
        # A planted boot moves backward relative to the character root.
        rates = []
        for before, after in zip(stance[:-1],stance[1:]):
            contact = (before[:,2] < before[:,2].min()+.035) & (after[:,2] < after[:,2].min()+.035)
            if contact.any():
                rates.append(np.median(after[contact,1]-before[contact,1])*scene.render.fps)
        print("SCOUT_WALK_METRES_PER_SECOND",np.median(rates),flush=True)
    output_actions.append(action)
    rig.animation_data.action = None

output_actions.extend(build_attacks(rig, scene, points))
bpy.data.objects.remove(source,do_unlink=True)
for pose in rig.pose.bones:
    pose.matrix_basis.identity()
for action in output_actions:
    track = rig.animation_data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name,0,action)
    strip.action_slot = action.slots[0]
scene.frame_set(0)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(OUT),use_selection=True,export_animations=True,
                          export_animation_mode="NLA_TRACKS",export_force_sampling=True,
                          export_skins=True,export_image_format="JPEG",export_jpeg_quality=92)
print("SCOUT_TRIANGLES",original_triangles,len(mesh.data.polygons),flush=True)
