"""Preserve the Trellis original; prepare a lighter, ground-aligned game export."""
import bpy, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(Path(__file__).parent/'workshop_original.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
before=sum(len(o.data.polygons) for o in meshes)
for obj in meshes:
 bpy.context.view_layer.objects.active=obj
 mod=obj.modifiers.new('Game mesh detail','DECIMATE');mod.ratio=60000/before
 bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
points=[v.co for o in meshes for v in o.data.vertices]
lo=Vector([min(v[i] for v in points) for i in range(3)])
hi=Vector([max(v[i] for v in points) for i in range(3)])
size=hi-lo
# Fit the authored obstacle envelope. Blender axes are X width, Y depth, Z height.
target=Vector((6.4,3.,4.2))
for obj in meshes:
 for v in obj.data.vertices:
  v.co=Vector(((v.co.x-(lo.x+hi.x)/2)*target.x/size.x,
               (v.co.y-(lo.y+hi.y)/2)*target.y/size.y,
               (v.co.z-lo.z)*target.z/size.z))
 obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'Game/models/environment/workshop/workshop.glb'),export_format='GLB',use_selection=True)
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).parent/'Workshop.blend'))
stats={'source_triangles':before,'game_triangles':sum(len(o.data.polygons) for o in meshes),'dimensions_godot':[6.4,4.2,3.],'source':'workshop_original.glb'}
(Path(__file__).parent/'inspection.json').write_text(json.dumps(stats,indent=2))
# Neutral inspection: front and three-quarter, to identify the authored orientation.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.world.use_nodes=True;bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[1].default_value=.6
bpy.ops.object.light_add(type='AREA',location=(1,-5,8));bpy.context.object.data.energy=1400;bpy.context.object.data.size=6
scene.render.resolution_x=1100;scene.render.resolution_y=750;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
bpy.ops.object.camera_add(location=(8,-12,7));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=9.8;scene.camera=cam
for name,point in [('three_quarter',(8,-12,7)),('front',(0,-15,3.4))]:
 cam.location=point;cam.rotation_euler=(Vector((0,0,2))-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(ROOT/'Builds/Validation/Workshop'/f'{name}.png');bpy.ops.render.render(write_still=True)
print('WORKSHOP_PREPARED',stats)
