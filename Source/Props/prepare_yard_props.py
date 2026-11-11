import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
report = {}
for label, folder, filename, height, angle, budget in [
    ('loader', 'Loader', 'loader_original.glb', 1.85, 90, 45000),
    ('wooden_crate', 'WoodenCrate', 'crate_original.glb', 0.95, 12, 18000),
]:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'Source/Props'/folder/filename))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    before = sum(len(o.data.polygons) for o in meshes)
    for obj in meshes:
        mod = obj.modifiers.new('Gameplay detail', 'DECIMATE')
        mod.ratio = min(1.0, budget / before)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.context.view_layer.update()
    points = [o.matrix_world @ Vector(p) for o in meshes for p in o.bound_box]
    low = Vector([min(p[i] for p in points) for i in range(3)])
    high = Vector([max(p[i] for p in points) for i in range(3)])
    factor = height / (high.z-low.z)
    offset = Vector(((low.x+high.x)/2, (low.y+high.y)/2, low.z))
    for obj in meshes:
        obj.location = (obj.location-offset)*factor
        obj.scale *= factor
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    target = ROOT/'Game/models/props'/f'{label}.glb'
    bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', use_selection=True)
    report[label] = {'source_faces': before, 'game_faces': sum(len(o.data.polygons) for o in meshes), 'height_m': height, 'scene_yaw_degrees': angle}
    # Neutral inspection image, independent of the game lighting.
    world = bpy.context.scene.world
    world.use_nodes = True
    world.node_tree.nodes.get('Background').inputs[0].default_value = (0.28,0.28,0.28,1)
    world.node_tree.nodes.get('Background').inputs[1].default_value = 0.8
    bpy.ops.object.light_add(type='AREA', location=(1,-3,5))
    bpy.context.object.data.energy = 450
    bpy.context.object.data.shape = 'DISK'
    bpy.context.object.data.size = 5
    bpy.ops.object.camera_add(location=(3,-6,3))
    cam = bpy.context.object
    cam.rotation_euler = (Vector((0,0,height*.5))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=4.8 if label=='loader' else 1.6
    scene=bpy.context.scene;scene.camera=cam
    scene.render.engine='CYCLES';scene.cycles.samples=16
    scene.render.resolution_x=960;scene.render.resolution_y=600;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.render.filepath=str(ROOT/'Builds/Validation/NewProps'/f'{label}_inspection.png')
    bpy.ops.render.render(write_still=True)
(ROOT/'Builds/Validation/NewProps/inspection.json').write_text(json.dumps(report,indent=2))
print(report)
