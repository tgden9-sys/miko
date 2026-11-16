"""Prepare the hover boss from its Trellis GLB.

Run with Blender: --background --python build_hover_boss.py -- source.glb [review directory]
"""
from math import cos, pi, radians, sin
from pathlib import Path
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / "MovementLab/models/props/lab_armored_hover_boss.glb"
SCALE = 1.88
GAP = .30
GUNS = {
    "Cannon_L": ((-.50,.24,.876),(-.795,-.358,.723),950),
    "Cannon_R": (( .49,.104,.865),( .643,-.614,.542),950),
    "Cannon_Front": ((.003,-.415,.625),(.015,-.702,.524),410),
}
SIDE_CUT = .51
HOVER_DECK = .376
FRONT_CUT = -.445
FRONT_HALF_WIDTH = .105
FRONT_BOTTOM = .440
FRONT_TOP = .653


def grade_paint(material):
    material.name = "Hover boss slate and burnished copper"
    nodes = material.node_tree.nodes
    shader = next(node for node in nodes if node.type == "BSDF_PRINCIPLED")
    base = shader.inputs["Base Color"].links[0].from_node
    base.image.scale(1536,1536)
    rgba = np.empty(1536*1536*4,dtype=np.float32)
    base.image.pixels.foreach_get(rgba)
    pixels = rgba.reshape(-1,4)
    rgb = pixels[:,:3].copy()
    gray = rgb @ np.array((.31,.54,.15),dtype=np.float32)
    chroma = rgb.max(1)-rgb.min(1)
    muted = gray[:,None]+(rgb-gray[:,None])*(.87-.42*chroma[:,None])
    warm = np.clip((rgb[:,0]-rgb[:,2]-.09)*2.75,0,1)
    warm *= np.clip((rgb[:,1]-rgb[:,2]-.035)*5.75,0,1)
    copper = (gray*.87+.009)[:,None]*np.array((1.23,.94,.72),dtype=np.float32)
    signal = np.clip((rgb[:,0]-rgb[:,1]-.15)*4,0,1)*(1-np.clip((rgb[:,1]-rgb[:,2]-.07)*8,0,1))
    muted += (rgb-muted)*signal[:,None]*.45
    pixels[:,:3] = np.clip(muted*(1-warm[:,None])+copper*warm[:,None],0,1)
    texture = bpy.data.images.new("ArmoredHoverBoss_SlateCopper",1536,1536,alpha=False)
    texture.pixels.foreach_set(rgba)
    texture.update()
    texture.pack()
    base.image = texture
    for node in list(nodes):
        if node != base and node != shader and node.type != "OUTPUT_MATERIAL":
            nodes.remove(node)
    shader.inputs["Metallic"].default_value = .13
    shader.inputs["Roughness"].default_value = .73


def empty(name, parent=None, local=(0,0,0)):
    node = bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(node)
    node.parent = parent
    node.location = local
    node.empty_display_size = .1
    return node


def material(name,color):
    paint = bpy.data.materials.new(name)
    paint.use_nodes = True
    shader = paint.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color,1)
    shader.inputs["Roughness"].default_value = .66
    return paint


def classify(point):
    x,y,z = point
    if abs(x) > SIDE_CUT and z > HOVER_DECK:
        return "Cannon_R" if x > 0 else "Cannon_L"
    if abs(x) < FRONT_HALF_WIDTH and y < FRONT_CUT and FRONT_BOTTOM < z < FRONT_TOP:
        return "Cannon_Front"
    return "Chassis"


def split_surfaces(source):
    mesh = bmesh.new()
    mesh.from_mesh(source)
    bmesh.ops.remove_doubles(mesh,verts=mesh.verts[:],dist=.00003)
    planes = [
        ((SIDE_CUT,0,0),(1,0,0)), ((-SIDE_CUT,0,0),(1,0,0)), ((0,0,HOVER_DECK),(0,0,1)),
        ((FRONT_HALF_WIDTH,0,0),(1,0,0)), ((-FRONT_HALF_WIDTH,0,0),(1,0,0)),
        ((0,FRONT_CUT,0),(0,1,0)), ((0,0,FRONT_BOTTOM),(0,0,1)), ((0,0,FRONT_TOP),(0,0,1)),
    ]
    for point,normal in planes:
        bmesh.ops.bisect_plane(mesh,geom=mesh.verts[:]+mesh.edges[:]+mesh.faces[:],
                               dist=.000007,plane_co=point,plane_no=normal)
    mesh.verts.index_update()
    labels = {face: classify(face.calc_center_median()) for face in mesh.faces}
    pending = set(labels)
    # Keep reconstruction flecks with their nearest shared piece.
    for first in mesh.faces:
        if first not in pending:
            continue
        pending.remove(first)
        label = labels[first]
        component, neighbors, queue = [first], {}, [first]
        while queue:
            face = queue.pop()
            for edge in face.edges:
                for neighbor in edge.link_faces:
                    other = labels[neighbor]
                    if other != label:
                        neighbors[other] = neighbors.get(other,0)+edge.calc_length()
                    elif neighbor in pending:
                        pending.remove(neighbor)
                        component.append(neighbor)
                        queue.append(neighbor)
        if neighbors and len(component) < 250 and sum(face.calc_area() for face in component) < .012:
            best = max(neighbors,key=neighbors.get)
            for face in component:
                labels[face] = best
    groups = {}
    for face,label in labels.items():
        groups.setdefault(label,[]).append(face)
    return mesh,groups


def make_part(name,faces,uv_layer,pivot,parent,budget,paint,interior):
    points, polygons, uvs, indices = [], [], [], {}
    for face in faces:
        polygon = []
        for loop in face.loops:
            vertex = loop.vert
            if vertex.index not in indices:
                indices[vertex.index] = len(points)
                points.append((vertex.co-pivot)*SCALE)
            polygon.append(indices[vertex.index])
            uvs.append(loop[uv_layer].uv.copy())
        polygons.append(polygon)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points,[],polygons)
    mesh.materials.append(paint)
    mesh.materials.append(interior)
    uv = mesh.uv_layers.new(name="AlbedoUV")
    for index,coordinate in enumerate(uvs):
        uv.data[index].uv = coordinate
    mesh.validate(clean_customdata=False)
    part = bmesh.new()
    part.from_mesh(mesh)
    for face in bmesh.ops.holes_fill(part,edges=[edge for edge in part.edges if edge.is_boundary],sides=0)["faces"]:
        if face.calc_area() < .55:
            face.material_index = 1
        else:
            bmesh.ops.delete(part,geom=[face],context="FACES_ONLY")
    bmesh.ops.recalc_face_normals(part,faces=part.faces[:])
    bmesh.ops.triangulate(part,faces=part.faces[:])
    part.to_mesh(mesh)
    part.free()
    for face in mesh.polygons:
        face.use_smooth = face.material_index == 0
    obj = bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new("Game triangle budget","DECIMATE")
    modifier.ratio = min(1.0,budget/len(mesh.polygons))
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.validate(clean_customdata=False)
    obj.data.calc_loop_triangles()
    print(name,len(obj.data.loop_triangles),flush=True)


def make_bearing(name,parent,direction,radius,length,paint):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=radius*SCALE,depth=length*SCALE)
    joint = bpy.context.object
    joint.name = name
    joint.parent = parent
    joint.location = (0,0,0)
    joint.rotation_euler = Vector(direction).to_track_quat("Z","Y").to_euler()
    joint.data.materials.append(paint)
    for face in joint.data.polygons:
        face.use_smooth = len(face.vertices) == 4


def smooth(t,start,end):
    v = min(max((t-start)/(end-start),0),1)
    return v*v*(3-2*v)


def record(name,frames,hull,gun_nodes):
    for frame in range(1,frames+1):
        t = (frame-1)/(frames-1)
        phase = 2*pi*t
        lift = .032*sin(phase)+.009*sin(phase*2)
        bank = .022*sin(phase)
        tilt = .012*cos(phase)
        if name == "Glide":
            bank = .058*sin(phase)
            tilt = -.04+.012*cos(phase)
        if name == "CannonVolley":
            brace = smooth(t,.08,.34)*(1-smooth(t,.72,1))
            lift = -.052*brace
            bank = .019*sin(phase)*brace
            tilt = -.032*brace
        hull.location.z = GAP+lift
        hull.rotation_euler = (tilt,bank,0)
        hull.keyframe_insert(data_path="location",frame=frame)
        hull.keyframe_insert(data_path="rotation_euler",frame=frame)
        for index,(yaw,pitch,recoil) in enumerate(gun_nodes):
            turn = 0
            elevation = 0
            kick = 0
            if name == "CannonVolley":
                settle = smooth(t,.09+index*.018,.33+index*.018)*(1-smooth(t,.71,1))
                shot = .43+index*.085
                kick = smooth(t,shot,shot+.026)*(1-smooth(t,shot+.026,shot+.145))
                turn = [-.095,.095,.105][index]*settle
                elevation = -.19*settle-.043*kick
            yaw.rotation_euler.z = turn
            pitch.rotation_euler.x = elevation
            recoil.location.y = .112*kick
            yaw.keyframe_insert(data_path="rotation_euler",frame=frame)
            pitch.keyframe_insert(data_path="rotation_euler",frame=frame)
            recoil.keyframe_insert(data_path="location",frame=frame)
    for node in [hull]+[node for gun in gun_nodes for node in gun]:
        animation = node.animation_data
        if animation.action is None:
            continue
        action,slot = animation.action,animation.action_slot
        action.name = name+"_"+node.name
        track = animation.nla_tracks.new()
        track.name = name
        strip = track.strips.new(name,1,action)
        strip.action_slot = slot
        track.mute = True
        animation.action = None


def main():
    args = sys.argv[sys.argv.index("--")+1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args[0])
    source = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    bpy.context.view_layer.objects.active = source
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    source.data.transform(Matrix.Rotation(radians(34),4,"Z"))
    paint = source.data.materials[0]
    grade_paint(paint)
    interior = material("Dark steel sockets",(.038,.046,.051))
    mesh,groups = split_surfaces(source.data)
    uv = mesh.loops.layers.uv.active
    root = empty("ArmoredHoverBoss")
    hull = empty("HoverChassis",root,(0,0,GAP))
    make_part("ChassisSkin",groups["Chassis"],uv,Vector(),hull,2900,paint,interior)
    gun_nodes = []
    for name,(at,muzzle,budget) in GUNS.items():
        pivot = Vector(at)
        yaw = empty(name+"_Yaw",hull,pivot*SCALE)
        pitch = empty(name+"_Pitch",yaw)
        recoil = empty(name+"_Recoil",pitch)
        make_part(name+"Skin",groups[name],uv,pivot,recoil,budget,paint,interior)
        is_front = name.endswith("Front")
        make_bearing(name+"_Bearing",yaw,(0,1,0) if is_front else (1,0,0),
                     .064 if is_front else .109,.125 if is_front else .19,interior)
        empty(name+"_Muzzle",recoil,(Vector(muzzle)-pivot)*SCALE)
        gun_nodes.append((yaw,pitch,recoil))
    mesh.free()
    bpy.data.objects.remove(source,do_unlink=True)
    scene = bpy.context.scene
    scene.render.fps = 30
    clips = (("HoverIdle",67),("Glide",67),("CannonVolley",62))
    for name,frames in clips:
        record(name,frames,hull,gun_nodes)
    animated = [hull]+[node for gun in gun_nodes for node in gun]
    for node in animated:
        for track in node.animation_data.nla_tracks:
            track.mute = False
        node.animation_data.use_nla = False
    hull.location.z = GAP
    hull.rotation_euler = (0,0,0)
    for yaw,pitch,recoil in gun_nodes:
        yaw.rotation_euler = pitch.rotation_euler = (0,0,0)
        recoil.location.y = 0
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_image_format="JPEG",
                              export_jpeg_quality=91,export_animation_mode="NLA_TRACKS")
    if len(args) > 1:
        for node in animated:
            node.animation_data.use_nla = True
            for track in node.animation_data.nla_tracks:
                track.mute = track.name != "HoverIdle"
        scene.frame_end = clips[0][1]
        scene.frame_set(1)
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(args[1])/"ArmoredHoverBoss.blend"))


if __name__ == "__main__":
    main()
