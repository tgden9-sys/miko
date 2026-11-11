import bpy,pathlib,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');reports=[]
for name in ['platform','endcap','pressure','canister']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/f'Source/Environment/Level2Platforms/{name}_original.glb'))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in meshes:
  bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 pts=[v.co for o in meshes for v in o.data.vertices];lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
 o=meshes[0];tree=BVHTree.FromPolygons([v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons])
 samples=[]
 for x in [-.5,-.25,0,.25,.5]:
  for y in [-.5,0,.5]:
   hit=tree.ray_cast(Vector((x,y,hi.z+1)),Vector((0,0,-1)))[0]
   if hit:samples.append(list(hit))
 reports.append({'asset':name,'min':list(lo),'max':list(hi),'top_samples':samples,'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)})
 sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_cavity=True;sc.render.resolution_x=1000;sc.render.resolution_y=900;sc.render.resolution_percentage=100
 centre=(lo+hi)*.5;span=max(hi-lo)
 bpy.ops.object.camera_add(location=centre+Vector((span*.65,-span*1.4,span*.65)));cam=bpy.context.object;cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.45;sc.camera=cam;sc.render.filepath=str(root/f'Builds/Validation/Level2Props/{name}.png');bpy.ops.render.render(write_still=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(root/f'Source/Environment/Level2Platforms/{name}_source.blend'))
 (root/'Builds/Validation/Level2Props/inspection.json').write_text(json.dumps(reports,indent=2))
