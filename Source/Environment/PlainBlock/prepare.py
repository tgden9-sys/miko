import bpy, pathlib, tempfile, json
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO')
tempfile.tempdir=str(root/'Builds/Validation/PlainBlock')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'Source/Environment/PlainBlock/original.glb'))
stats=[]
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 before=sum(len(p.vertices)-2 for p in obj.data.polygons)
 if before>64000:
  bpy.context.view_layer.objects.active=obj
  mod=obj.modifiers.new('Game reduction','DECIMATE');mod.ratio=64000/before
  bpy.ops.object.modifier_apply(modifier=mod.name)
 stats.append({'source_triangles':before,'game_triangles':sum(len(p.vertices)-2 for p in obj.data.polygons)})
 for mat in obj.data.materials:
  if not mat or not mat.use_nodes:continue
  bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
  if bs:
   for name in ['Normal','Metallic','Roughness']:
    for link in list(bs.inputs[name].links):mat.node_tree.links.remove(link)
   bs.inputs['Metallic'].default_value=0.;bs.inputs['Roughness'].default_value=.9
bpy.ops.wm.save_as_mainfile(filepath=str(root/'Source/Environment/PlainBlock/PlainBlock.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'Game/models/environment/plain_block/plain_block.glb'),export_format='GLB',export_image_format='AUTO')
(root/'Source/Environment/PlainBlock/optimisation.json').write_text(json.dumps(stats,indent=2))

