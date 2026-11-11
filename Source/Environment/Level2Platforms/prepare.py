import bpy,pathlib,tempfile,json
from mathutils import Vector
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');tempfile.tempdir=str(root/'Builds/Validation/Level2Props');report=[]
for name in ['platform','endcap','pressure','canister']:
 bpy.ops.wm.open_mainfile(filepath=str(root/f'Source/Environment/Level2Platforms/{name}_source.blend'))
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];before=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
 for o in meshes:
  bpy.context.view_layer.objects.active=o
  if before>64000:
   mod=o.modifiers.new('Game mesh','DECIMATE');mod.ratio=64000/before;bpy.ops.object.modifier_apply(modifier=mod.name)
 if name=='pressure':
  base=meshes[0];base.name='SwitchBase'
  bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,.7));cutter=bpy.context.object;cutter.name='PlungerCutter';cutter.dimensions=(.90,.82,.75);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  button=base.copy();button.data=base.data.copy();bpy.context.collection.objects.link(button);button.name='SwitchPlunger'
  for obj,operation in [(button,'INTERSECT'),(base,'DIFFERENCE')]:
   bpy.context.view_layer.objects.active=obj
   mod=obj.modifiers.new('Separate actual centre button','BOOLEAN');mod.operation=operation;mod.object=cutter;mod.solver='EXACT';bpy.ops.object.modifier_apply(modifier=mod.name)
  bpy.data.objects.remove(cutter,do_unlink=True)
 for o in bpy.context.scene.objects:
  if o.type!='MESH':continue
  for mat in o.data.materials:
   if not mat or not mat.use_nodes:continue
   bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
   if bs:
    for key in ['Normal','Metallic','Roughness']:
     for link in list(bs.inputs[key].links):mat.node_tree.links.remove(link)
    bs.inputs['Roughness'].default_value=.95;bs.inputs['Metallic'].default_value=0.
 bpy.ops.wm.save_as_mainfile(filepath=str(root/f'Source/Environment/Level2Platforms/{name}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(root/f'Game/models/environment/level2_props/{name}.glb'),export_format='GLB')
 report.append({'asset':name,'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'bytes':(root/f'Game/models/environment/level2_props/{name}.glb').stat().st_size})
 (root/'Builds/Validation/Level2Props/preparation.json').write_text(json.dumps(report,indent=2))
