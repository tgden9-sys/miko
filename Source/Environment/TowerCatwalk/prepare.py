import bpy,pathlib,tempfile,json
from mathutils import Vector
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');tempfile.tempdir=str(root/'Builds/Validation/ThreeLevels');report=[]
for name in ['tower','catwalk']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/f'Source/Environment/TowerCatwalk/{name}_original.glb'))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in meshes:
  bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 pts=[v.co for o in meshes for v in o.data.vertices];lo=[min(p[i] for p in pts) for i in range(3)];hi=[max(p[i] for p in pts) for i in range(3)]
 before=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
 for o in meshes:
  bpy.context.view_layer.objects.active=o
  if before>64000:
   m=o.modifiers.new('Game detail','DECIMATE');m.ratio=64000/before;bpy.ops.object.modifier_apply(modifier=m.name)
  for mat in o.data.materials:
   if not mat or not mat.use_nodes:continue
   bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
   if bs:
    for key in ['Normal','Metallic','Roughness']:
     for link in list(bs.inputs[key].links):mat.node_tree.links.remove(link)
    bs.inputs['Roughness'].default_value=.95;bs.inputs['Metallic'].default_value=0.
 bpy.ops.wm.save_as_mainfile(filepath=str(root/f'Source/Environment/TowerCatwalk/{name}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(root/f'Game/models/environment/tower_catwalk/{name}.glb'),export_format='GLB')
 sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_cavity=True;sc.render.resolution_x=1000;sc.render.resolution_y=900;sc.render.resolution_percentage=100
 centre=Vector(tuple((a+b)*.5 for a,b in zip(lo,hi)));span=max(b-a for a,b in zip(lo,hi))
 bpy.ops.object.camera_add(location=centre+Vector((span*.6,-span*1.3,span*.5)));cam=bpy.context.object;cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.4;sc.camera=cam;sc.render.filepath=str(root/f'Builds/Validation/ThreeLevels/{name}.png');bpy.ops.render.render(write_still=True)
 report.append({'asset':name,'source_triangles':before,'lo_blender':lo,'hi_blender':hi})
 (root/'Builds/Validation/ThreeLevels/assets.json').write_text(json.dumps(report,indent=2))
