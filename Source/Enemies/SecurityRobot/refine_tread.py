"""Add clean, bone-driven tyre treads over the source model's noisy tread."""
import bpy
import math

BASE = r'C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot'
bpy.ops.wm.open_mainfile(filepath=BASE + r'\security_robot_rig.blend')
rig = bpy.data.objects['Security_Robot_Rig']
for item in list(bpy.data.objects):
    if item.name.endswith(' clean tyre') or item.name.endswith(' chevrons'):
        bpy.data.objects.remove(item, do_unlink=True)

rubber = bpy.data.materials.new('Tyre - satin charcoal')
rubber.diffuse_color = (.027, .031, .038, 1)
rubber.use_nodes = True
bsdf = rubber.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (.027, .031, .038, 1)
bsdf.inputs['Roughness'].default_value = .82

lug = bpy.data.materials.new('Tyre tread - graphite')
lug.diffuse_color = (.017, .019, .022, 1)
lug.use_nodes = True
bsdf = lug.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (.017, .019, .022, 1)
bsdf.inputs['Roughness'].default_value = .91

def make_tyre(name, x0, x1):
    # Wheel axles run along X. Four profile bands soften both tyre shoulders.
    cy, cz = .135, -.335
    profile = [(x0, .145), (x0 + .010, .153), (x1 - .010, .153), (x1, .145)]
    sides = 72
    verts = []
    faces = []
    for x, radius in profile:
        for i in range(sides):
            angle = 2 * math.pi * i / sides
            verts.append((x, cy + radius * math.cos(angle), cz + radius * math.sin(angle)))
    for band in range(len(profile)-1):
        for i in range(sides):
            a = band*sides+i
            b = band*sides+(i+1)%sides
            faces.append((a, b, b+sides, a+sides))
    mesh = bpy.data.meshes.new(name + ' tread mesh')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name + ' clean tyre', mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(rubber)
    mesh.materials.append(lug)
    for poly in mesh.polygons:
        poly.use_smooth = True

    # Short staggered chevrons leave a dark centre groove. They are actual
    # raised geometry, so the roll remains legible in the small 2D silhouette.
    lug_verts = []
    lug_faces = []
    centre = (x0 + x1) / 2
    for i in range(30):
        angle = 2 * math.pi * i / 30
        for side in (-1, 1):
            xa = centre + side * .006
            xb = centre + side * ((x1-x0)/2-.011)
            theta_a = angle + side*.055
            theta_b = angle - side*.075
            width = .087
            start = len(lug_verts)
            for x, theta in ((xa,theta_a-width/2),(xb,theta_b-width/2),
                             (xb,theta_b+width/2),(xa,theta_a+width/2)):
                lug_verts.append((x, cy+.156*math.cos(theta), cz+.156*math.sin(theta)))
            lug_faces.append(tuple(range(start,start+4)))
        # Side shoulder blocks are visible to the game's exact profile camera.
        # Keep the centre of the sidewall and metal hub uncovered.
        for face_x in (x0-.008, x1+.008):
            start = len(lug_verts)
            for radius, theta in ((.119, angle-.016), (.145, angle-.030),
                                  (.145, angle+.030), (.119, angle+.016)):
                lug_verts.append((face_x, cy+radius*math.cos(theta), cz+radius*math.sin(theta)))
            lug_faces.append(tuple(range(start,start+4)))
    lug_mesh = bpy.data.meshes.new(name + ' chevrons mesh')
    lug_mesh.from_pydata(lug_verts, [], lug_faces)
    lug_mesh.update()
    lug_obj = bpy.data.objects.new(name + ' chevrons', lug_mesh)
    bpy.context.collection.objects.link(lug_obj)
    lug_mesh.materials.append(lug)
    for poly in lug_mesh.polygons:
        poly.use_smooth = True

    # Rigid binding matches the original wheel bone and exports to Godot.
    for item in (obj, lug_obj):
        item.parent = rig
        group = item.vertex_groups.new(name=name)
        group.add(list(range(len(item.data.vertices))), 1.0, 'REPLACE')
        modifier = item.modifiers.new('Follow wheel bone', 'ARMATURE')
        modifier.object = rig
    return (obj, lug_obj)

parts = []
parts += make_tyre('Far_Wheel', -.258, -.137)
parts += make_tyre('Middle_Wheel', -.041, .088)
parts += make_tyre('Near_Wheel', .188, .303)

bpy.ops.wm.save_as_mainfile(filepath=BASE + r'\security_robot_rig.blend')
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.data.objects['Security_Robot_Mesh'].select_set(True)
for item in parts:
    item.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=BASE + r'\security_robot_rig.glb',
    export_format='GLB', use_selection=True, export_animations=True,
    export_animation_mode='ACTIONS')
print('TREAD_REFINED', flush=True)
