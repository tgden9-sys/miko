"""Build and animate the rigid pieces of the fused walker export.

blender --background --python build_walker.py -- original.glb [review directory]
"""
from math import cos, pi, sin, sqrt
from pathlib import Path
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Quaternion, Vector


ROOT = Path(__file__).resolve().parents[3]
ARGS = sys.argv[sys.argv.index("--") + 1:]
OUTPUT = ROOT / "MovementLab/models/props/lab_armored_walker.glb"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ARGS[0])
source = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
WAIST_HEIGHT = .723
bpy.context.view_layer.objects.active = source
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def prepare_paint(material):
    material.name = "Walker slate and copper"
    nodes = material.node_tree.nodes
    shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
    baked = shader.inputs["Base Color"].links[0].from_node
    original = baked.image
    original.scale(1024, 1024)
    pixels = np.empty(1024 * 1024 * 4, dtype=np.float32)
    original.pixels.foreach_get(pixels)
    image = pixels.reshape(-1, 4)
    rgb = image[:, :3].copy()
    luma = rgb @ np.array((.26, .57, .17), dtype=np.float32)
    low = np.min(rgb, axis=1)
    high = np.max(rgb, axis=1)
    saturation = (high - low) / np.maximum(high, .045)
    # Desaturate the blue painted plates more than the steel and baked creases.
    cleaned = luma[:, None] + (rgb-luma[:, None]) * (.62-.44*saturation[:, None])
    cleaned *= np.array((.98, 1.0, 1.02), dtype=np.float32)
    copper = np.clip((rgb[:, 0]-rgb[:, 2]-.10)*2.75, 0, 1)
    copper *= np.clip((rgb[:, 1]-rgb[:, 2]-.018)*6, 0, 1)
    copper_luma = luma*.81+.018
    copper_rgb = copper_luma[:, None]*np.array((1.21,.96,.76), dtype=np.float32)
    cleaned = cleaned*(1-copper[:, None]) + copper_rgb*copper[:, None]
    image[:, :3] = np.clip(cleaned, 0, 1)
    albedo = bpy.data.images.new("Walker_Slate_Copper", 1024, 1024, alpha=False)
    albedo.pixels.foreach_set(pixels)
    albedo.update()
    albedo.pack()
    baked.image = albedo
    for node in list(nodes):
        if node not in (baked, shader) and node.type != "OUTPUT_MATERIAL":
            nodes.remove(node)
    shader.inputs["Metallic"].default_value = .18
    shader.inputs["Roughness"].default_value = .73


def finish_material(name, color, roughness):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color,1)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color,1)
    shader.inputs["Roughness"].default_value = roughness
    return material


paint = source.data.materials[0]
prepare_paint(paint)
joint_metal = finish_material("Recessed joint steel", (.032,.038,.042), .64)


def empty(name, parent=None, location=(0,0,0)):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.location = location
    node.empty_display_size = .08
    return node


root = empty("ArmoredWalker")
body = empty("Chassis", root)
gun_mounts = [
    ("Cannon_L", Vector((-.50,.135,.995)), Vector((-.78,-.59,.81))),
    ("Cannon_R", Vector(( .50,.135,.995)), Vector(( .83,-.58,.81))),
    ("Cannon_Front", Vector((.0,-.565,.765)), Vector((.0,-.777,.723))),
]
legs = {}
for front, y_sign in (("Front",-1),("Rear",1)):
    for side, x_sign in (("L",-1),("R",1)):
        name = f"{front}_{side}"
        hip = Vector((.267*x_sign, .277*y_sign, .565))
        knee = Vector((.521*x_sign, (.430 if y_sign < 0 else .403)*y_sign, .412))
        foot = Vector((.675*x_sign, (.531 if y_sign < 0 else .570)*y_sign, .044))
        legs[(x_sign,y_sign)] = (name,hip,knee,foot)

# Separate the cannon mounts. Keep the chassis and all four legs continuous
# so the original armor, creases and texture survive across the knee and hip.
raw = bmesh.new()
raw.from_mesh(source.data)
bmesh.ops.remove_doubles(raw, verts=raw.verts[:], dist=.00003)
planes = [
    ((.525,0,0),(1,0,0)), ((-.525,0,0),(1,0,0)), ((0,0,.697),(0,0,1)),
    ((.137,0,0),(1,0,0)), ((-.137,0,0),(1,0,0)),
    ((0,-.573,0),(0,1,0)), ((0,0,.868),(0,0,1)), ((0,0,.605),(0,0,1)),
    ((0,0,WAIST_HEIGHT),(0,0,1)),
]
for point, normal in planes:
    bmesh.ops.bisect_plane(raw, geom=raw.verts[:]+raw.edges[:]+raw.faces[:],
                           dist=.000008, plane_co=point, plane_no=normal)
raw.verts.index_update()
uv_layer = raw.loops.layers.uv.active


def segment(point):
    x,y,z = point
    if abs(x) > .525 and z > .697:
        return "Cannon_R" if x > 0 else "Cannon_L"
    if abs(x) < .137 and y < -.573 and .605 < z < .868:
        return "Cannon_Front"
    return "LowerBody" if z < WAIST_HEIGHT else "UpperBody"


labels = {face: segment(face.calc_center_median()) for face in raw.faces}
# The reconstruction has tiny fused flecks at some cut planes. Keep each
# fleck with its longest adjoining surface so it does not float when posed.
unchecked = set(raw.faces)
while unchecked:
    first = unchecked.pop()
    group_label = labels[first]
    patch, nearby, queue = [first], {}, [first]
    while queue:
        face = queue.pop()
        for edge in face.edges:
            for other in edge.link_faces:
                if labels[other] != group_label:
                    nearby[labels[other]] = nearby.get(labels[other],0)+edge.calc_length()
                elif other in unchecked:
                    unchecked.remove(other)
                    patch.append(other)
                    queue.append(other)
    if len(patch) < 180 and nearby and sum(face.calc_area() for face in patch) < .006:
        destination = max(nearby,key=nearby.get)
        for face in patch:
            labels[face] = destination
groups = {}
for face,label in labels.items():
    groups.setdefault(label, []).append(face)


def export_skin(label, parent, pivot, target_count):
    points, faces, uvs, remap = [], [], [], {}
    for face in groups[label]:
        indices = []
        for loop in face.loops:
            vertex = loop.vert
            if vertex.index not in remap:
                remap[vertex.index] = len(points)
                points.append(vertex.co-pivot)
            indices.append(remap[vertex.index])
            uvs.append(loop[uv_layer].uv.copy())
        faces.append(indices)
    mesh = bpy.data.meshes.new(label)
    mesh.from_pydata(points, [], faces)
    mesh.materials.append(paint)
    mesh.materials.append(joint_metal)
    layer = mesh.uv_layers.new(name="AlbedoUV")
    for index, uv in enumerate(uvs):
        layer.data[index].uv = uv
    mesh.validate(clean_customdata=False)
    part = bmesh.new()
    part.from_mesh(mesh)
    # Fill only the relatively small openings exposed at joints.
    boundary = [edge for edge in part.edges if edge.is_boundary]
    for face in bmesh.ops.holes_fill(part, edges=boundary, sides=0)["faces"]:
        if face.calc_area() < .18:
            face.material_index = 1
        else:
            bmesh.ops.delete(part, geom=[face], context="FACES_ONLY")
    bmesh.ops.recalc_face_normals(part, faces=part.faces[:])
    bmesh.ops.triangulate(part, faces=part.faces[:])
    part.to_mesh(mesh)
    part.free()
    for face in mesh.polygons:
        face.use_smooth = face.material_index == 0
    obj = bpy.data.objects.new(label+"Skin", mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    bpy.context.view_layer.objects.active = obj
    simplify = obj.modifiers.new("Runtime triangles", "DECIMATE")
    simplify.ratio = min(1, target_count/len(mesh.polygons))
    simplify.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=simplify.name)
    obj.data.validate(clean_customdata=False)
    obj.data.update()
    print(label,len(obj.data.polygons),flush=True)
    return obj


def joint(name, parent, at, axis, radius, length):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=radius, depth=length)
    obj = bpy.context.object
    obj.name = name
    obj.parent = parent
    obj.location = at
    obj.rotation_euler = Vector(axis).to_track_quat("Z","Y").to_euler()
    obj.data.materials.append(joint_metal)
    for face in obj.data.polygons:
        face.use_smooth = len(face.vertices) == 4


def create_leg_rig():
    skeleton = bpy.data.armatures.new("WalkerLegs")
    rig = bpy.data.objects.new("WalkerLegRig",skeleton)
    bpy.context.collection.objects.link(rig)
    rig.parent = body
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    anchor = skeleton.edit_bones.new("Body")
    anchor.head = (0,0,0)
    anchor.tail = (0,.16,0)
    for name,hip,knee,foot in legs.values():
        parent = anchor
        for name_suffix, pivot in (("_Hip",hip),("_Knee",knee),("_Foot",foot)):
            bone = skeleton.edit_bones.new(name+name_suffix)
            # Parallel rest axes let each joint use the same mechanical axes.
            bone.head = pivot
            bone.tail = pivot+Vector((0,.13,0))
            bone.parent = parent
            parent = bone
    bpy.ops.object.mode_set(mode="OBJECT")
    for bone in rig.pose.bones:
        bone.rotation_mode = "QUATERNION"
    return rig


def eased(t, start, end):
    s = min(1,max(0,(t-start)/(end-start)))
    return s*s*(3-2*s)


def weight_body(mesh, rig):
    weights = {bone.name: mesh.vertex_groups.new(name=bone.name) for bone in rig.data.bones}
    for vertex in mesh.data.vertices:
        point = vertex.co
        x,y,z = point
        side,end = (1 if x >= 0 else -1), (1 if y >= 0 else -1)
        name,_,knee,_ = legs[side,end]
        edge = eased(abs(x),.34,.57)
        leg = eased(abs(x),.207,.385)*eased(abs(y),.154,.322)
        leg *= 1-eased(z,.583+edge*.076,WAIST_HEIGHT-.004)
        # Blend only near the steel hinge. The outer knee plate stays with the shin.
        across_hinge = (point-knee).dot(Vector((-1.92*side,-.22*end,1)).normalized())
        below_knee = 1-eased(across_hinge,-.046,.063)
        shoe = 1-eased(z,.072,.151)
        assignments = (
            ("Body",1-leg),
            (name+"_Hip",leg*(1-below_knee)),
            (name+"_Knee",leg*below_knee*(1-shoe)),
            (name+"_Foot",leg*below_knee*shoe),
        )
        for name, weight in assignments:
            if weight > .00001:
                weights[name].add([vertex.index],weight,"REPLACE")
    deform = mesh.modifiers.new("Four articulated legs","ARMATURE")
    deform.object = rig


leg_rig = create_leg_rig()
export_skin("UpperBody",body,Vector(),1680)
armor = export_skin("LowerBody",leg_rig,Vector(),2800)
weight_body(armor,leg_rig)
gun_nodes = []
for name,pivot,muzzle in gun_mounts:
    swivel = empty(name+"_Yaw",body,pivot)
    pitch = empty(name+"_Pitch",swivel)
    slide = empty(name+"_Recoil",pitch)
    export_skin(name,slide,pivot,230 if name.endswith("Front") else 530)
    axis = (0,1,0) if name.endswith("Front") else (1,0,0)
    joint(name+"_Socket",swivel,Vector(),axis,.070 if name.endswith("Front") else .085,.13)
    empty(name+"_Muzzle",slide,muzzle-pivot)
    gun_nodes.append((swivel,pitch,slide))
leg_nodes = [
    (signs,hip,knee,foot,*[leg_rig.pose.bones[name+suffix] for suffix in ("_Hip","_Knee","_Foot")])
    for signs,(name,hip,knee,foot) in legs.items()
]
bpy.data.objects.remove(source,do_unlink=True)
raw.free()


def leg_pose(leg, target, sole_angle=0):
    _,hip,knee,foot,upper,lower,shoe = leg
    rest_upper = knee-hip
    rest_lower = foot-knee
    ray = target-hip
    length = min(ray.length, rest_upper.length+rest_lower.length-.001)
    axis = ray.normalized()
    along = (length*length + rest_upper.length_squared-rest_lower.length_squared)/(2*length)
    offset = (rest_upper-axis*rest_upper.dot(axis)).normalized()
    new_upper = axis*along + offset*sqrt(max(0,rest_upper.length_squared-along*along))
    new_lower = axis*length-new_upper
    upper.rotation_quaternion = rest_upper.rotation_difference(new_upper)
    lower.rotation_quaternion = rest_lower.rotation_difference(upper.rotation_quaternion.inverted()@new_lower)
    # Cancel the shin's rotation while the foot is bearing weight.
    shoe.rotation_quaternion = (upper.rotation_quaternion @ lower.rotation_quaternion).inverted() @ Quaternion((1,0,0),sole_angle)


def key_leg(leg, frame):
    for bone in leg[-3:]:
        key(bone,"rotation_quaternion",frame)


def key(node, prop, frame):
    node.keyframe_insert(data_path=prop, frame=frame, group=node.name)


def record(name, frames, sample):
    for frame in range(1,frames+1):
        sample(frame, (frame-1)/(frames-1))
    # The exporter collects tracks with the same name into one glTF clip.
    for node in animated:
        action = node.animation_data.action
        slot = node.animation_data.action_slot
        action.name = f"{name}_{node.name}"
        track = node.animation_data.nla_tracks.new()
        track.name = name
        strip = track.strips.new(name,1,action)
        strip.action_slot = slot
        track.mute = True
        node.animation_data.action = None


def walk(frame, t):
    body.location = (sin(2*pi*t)*.018,0,-.022 + .014*(1-cos(8*pi*t))*.5)
    key(body,"location",frame)
    for leg in leg_nodes:
        signs,_,_,foot,_,_,_ = leg
        timing = {(-1,-1):0.0, (1,1):.25, (1,-1):.50, (-1,1):.75}
        phase = (t + timing[signs]) % 1.0
        stride = .26
        if phase < .74:
            reach = -stride*.5+stride*phase/.74
            lift = 0.0
            toe_pitch = 0.0
        else:
            step = (phase-.74)/.26
            reach = (cos(step*pi))*.5*stride
            lift = sin(step*pi)**1.55 * .104
            toe_pitch = sin(2*pi*step) * .15
        leg_pose(leg,foot+Vector((0,reach,lift))-body.location,toe_pitch)
        key_leg(leg,frame)
    for index,(yaw,pitch,slide) in enumerate(gun_nodes):
        yaw.rotation_euler.z = sin(2*pi*t)*(.036 if index != 2 else -.025)
        pitch.rotation_euler.x = cos(4*pi*t)*.028
        slide.location.y = 0
        key(yaw,"rotation_euler",frame)
        key(pitch,"rotation_euler",frame)
        key(slide,"location",frame)


def brace(frame, t):
    crouch = eased(t,.07,.40)*(1-eased(t,.70,.99))
    body.location = (0,.045*crouch,-.078*crouch)
    key(body,"location",frame)
    for leg in leg_nodes:
        _,_,_,foot,_,_,_ = leg
        leg_pose(leg,foot-body.location)
        key_leg(leg,frame)
    for index,(yaw,pitch,slide) in enumerate(gun_nodes):
        wind_up = eased(t,.04+index*.027,.32+index*.038)
        strike = eased(t,.35+index*.038,.48+index*.034)
        recovery = 1-eased(t,.67,.99)
        direction = [-1,1,.38][index]
        yaw.rotation_euler.z = (wind_up-strike*.36)*direction*.23*recovery
        pitch.rotation_euler.x = (wind_up*-.55+strike*1.16)*recovery*(1 if index < 2 else .68)
        kick_start = .50+index*.033
        slide.location.y = eased(t,kick_start,kick_start+.033)*(1-eased(t,kick_start+.035,kick_start+.16))*.085
        key(yaw,"rotation_euler",frame)
        key(pitch,"rotation_euler",frame)
        key(slide,"location",frame)


scene = bpy.context.scene
scene.render.fps = 30
animated = [body,leg_rig]+[node for gun in gun_nodes for node in gun]
record("HeavyWalk",49,walk)
record("CannonBrace",55,brace)
for node in animated:
    for track in node.animation_data.nla_tracks:
        track.mute = False
    node.animation_data.use_nla = False
# The rest pose is neutral if a caller instantiates the GLB before playing a clip.
body.location = (0,0,0)
for bone in leg_rig.pose.bones:
    bone.rotation_quaternion = (1,0,0,0)
for yaw,pitch,slide in gun_nodes:
    yaw.rotation_euler = pitch.rotation_euler = (0,0,0)
    slide.location = (0,0,0)

bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_image_format="JPEG",
                          export_jpeg_quality=90, export_animation_mode="NLA_TRACKS")

if len(ARGS) > 1:
    for node in animated:
        node.animation_data.use_nla = True
        for track in node.animation_data.nla_tracks:
            track.mute = track.name != "HeavyWalk"
    scene.frame_end = 49
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(Path(ARGS[1])/"ArmoredWalker.blend"))
