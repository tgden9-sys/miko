import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:\Users\tgden\Desktop\MIKO')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
info=[]
for name,file,x in [('A','cawami_Textured_5510399698.glb',-1.4),('B','cawawa_Textured_5510299699.glb',1.4)]:
 before=set(bpy.data.objects)
 bpy.ops.import_scene.gltf(filepath=str(Path(r'C:\Users\tgden\Downloads')/file))
 objs=[o for o in bpy.data.objects if o not in before]
 for o in objs:
  if not o.parent:o.location.x+=x
 for o in objs:
  if o.type=='MESH':
   bounds=[o.matrix_world@Vector(p) for p in o.bound_box]
   info.append({'name':name,'object':o.name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'min':[min(p[i] for p in bounds) for i in range(3)],'max':[max(p[i] for p in bounds) for i in range(3)]})
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12
scene.world.color=(.12,.12,.12)
for location,power,size in [((1,-4,6),1100,5),((-4,-1,3),600,4),((2,4,5),900,4)]:
 bpy.ops.object.light_add(type='AREA',location=location);bpy.context.object.data.energy=power;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=size
bpy.ops.object.camera_add(location=(4,-7,4.8));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,.7))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=6.6;scene.camera=camera
scene.render.resolution_x=1200;scene.render.resolution_y=760;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ROOT/'Builds/Validation/BridgePlatforms/source_assets.png')
(ROOT/'Source/Environment/BridgePlatforms/source_inspection.json').write_text(json.dumps(info,indent=2))
bpy.ops.render.render(write_still=True)
