import bpy, json, math, pathlib, shutil, tempfile
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = pathlib.Path(r'C:/Users/tgden/Desktop/MIKO')
SOURCE = ROOT / 'Source/Environment/PlatformTowers'
OUT = ROOT / 'Game/models/environment/platform_towers'
REPORT = ROOT / 'Builds/Validation/PlatformTowers'
for d in (SOURCE, OUT, REPORT): d.mkdir(parents=True, exist_ok=True)
tempfile.tempdir = str(REPORT)
FILES = {
    'small': pathlib.Path(r'C:/Users/tgden/Downloads/ChatGPT Image 4 Nov 2026, 23_20_56_Textured_55872101207.glb'),
    'medium': pathlib.Path(r'C:/Users/tgden/Downloads/ChatGPT Image 4 Nov 2026, 23_18_27_Textured_55870101204.glb'),
}
report = {}
for label, original in FILES.items():
    shutil.copy2(original, SOURCE / (label + '_original.glb'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / (label + '_original.glb')))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        obj.select_set(False)
        if label == 'small':
            # Reconstruction pitched the deck by ~2.7 degrees front-to-back.
            # Level only the upper cap; retain upright feet and source textures.
            for vertex in obj.data.vertices:
                blend = max(0.0, min(1.0, (vertex.co.z - 1.62) / .12))
                vertex.co.z -= .047 * vertex.co.y * blend
            obj.data.update()
    pts = [v.co.copy() for o in meshes for v in o.data.vertices]
    lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    before = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
    textures = []
    for obj in meshes:
        for mat in obj.data.materials:
            if not mat or not mat.use_nodes: continue
            bs = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if not bs: continue
            for key in ['Normal', 'Metallic', 'Roughness']:
                for link in list(bs.inputs[key].links): mat.node_tree.links.remove(link)
            bs.inputs['Metallic'].default_value = 0.0
            bs.inputs['Roughness'].default_value = 0.95
            image = next((l.from_node.image for l in bs.inputs['Base Color'].links if l.from_node.type == 'TEX_IMAGE'), None)
            if image:
                textures.append({'size': list(image.size), 'name': image.name})
                if max(image.size) > 2048:
                    ratio = 2048.0 / max(image.size)
                    image.scale(round(image.size[0] * ratio), round(image.size[1] * ratio))
            # Unused high-resolution normal/roughness images must not ship in GLB.
            for node in list(mat.node_tree.nodes):
                if node.type == 'TEX_IMAGE' and node.image != image: mat.node_tree.nodes.remove(node)
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        if before > 50000:
            dec = obj.modifiers.new('Preserve silhouette game reduction', 'DECIMATE')
            dec.ratio = 50000.0 / before
            bpy.ops.object.modifier_apply(modifier=dec.name)
        obj.select_set(False)
    after = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
    # Source-space surface measurements: Blender Z is runtime Y; -Y is runtime +Z.
    verts = [v.co.copy() for o in meshes for v in o.data.vertices]
    faces = []
    offset = 0
    for obj in meshes:
        faces.extend([tuple(offset + i for i in p.vertices) for p in obj.data.polygons])
        offset += len(obj.data.vertices)
    bvh = BVHTree.FromPolygons(verts, faces)
    roof = []
    for ix in range(9):
        for iy in range(9):
            x = lo.x + (hi.x - lo.x) * (.1 + .8 * ix / 8)
            y = lo.y + (hi.y - lo.y) * (.1 + .8 * iy / 8)
            hit, normal, face, dist = bvh.ray_cast(Vector((x, y, hi.z + .1)), Vector((0, 0, -1)), hi.z - lo.z + .2)
            if hit is not None: roof.append([x, -y, hit.z, normal.z])
    # Horizontal ladder/front profile, useful for matching the native hand and rung lane.
    profiles = []
    for frac in [.08, .2, .35, .5, .65, .8, .9]:
        z = lo.z + (hi.z - lo.z) * frac
        for x in [-.12, 0., .12]:
            hit, normal, face, dist = bvh.ray_cast(Vector((x, lo.y - .1, z)), Vector((0, 1, 0)), hi.y - lo.y + .2)
            if hit is not None: profiles.append([x, z, -hit.y])
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / (label + '.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT / (label + '.glb')), export_format='GLB', export_cameras=False, export_lights=False)
    # Source-colour inspection without extra specular noise or lighting baked twice.
    for obj in meshes:
        for mat in obj.data.materials:
            if not mat or not mat.use_nodes: continue
            nodes = mat.node_tree.nodes
            bs = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
            tex = next((l.from_node for l in bs.inputs['Base Color'].links if l.from_node.type == 'TEX_IMAGE'), None) if bs else None
            output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')
            emission = nodes.new('ShaderNodeEmission')
            if tex: mat.node_tree.links.new(tex.outputs['Color'], emission.inputs['Color'])
            mat.node_tree.links.new(emission.outputs[0], output.inputs['Surface'])
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.color_type = 'TEXTURE'
    scene.display.shading.light = 'FLAT'
    scene.display.shading.show_shadows = False
    scene.render.film_transparent = True
    scene.view_settings.view_transform = 'Standard'
    scene.render.resolution_x = 900
    scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    centre = (lo + hi) * .5
    span = max(hi - lo)
    for view, offset in [('front', Vector((0, -3, .12))), ('left', Vector((-3, 0, .12))), ('three_quarter', Vector((-1.5, -3, 1.0)))]:
        bpy.ops.object.camera_add(location=centre + offset * span)
        camera = bpy.context.object
        camera.rotation_euler = (centre - camera.location).to_track_quat('-Z', 'Y').to_euler()
        camera.data.type = 'ORTHO'
        camera.data.ortho_scale = span * 1.18
        scene.camera = camera
        scene.render.filepath = str(REPORT / (label + '_' + view + '.png'))
        bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(camera, do_unlink=True)
    report[label] = {'source_file': original.name, 'source_bytes': original.stat().st_size,
                     'source_triangles': before, 'runtime_triangles': after,
                     'runtime_bytes': (OUT / (label + '.glb')).stat().st_size,
                     'bounds_blender': [list(lo), list(hi)], 'textures': textures,
                     'roof_samples_runtime': roof, 'front_profile_runtime': profiles}
    (REPORT / 'asset_report.json').write_text(json.dumps(report, indent=2))
    print('TOWER_ASSET_PREPARED', label, before, after, flush=True)
