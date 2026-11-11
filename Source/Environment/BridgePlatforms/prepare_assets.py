import bpy,json,tempfile
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(r'C:\Users\tgden\Desktop\MIKO')
OUT=ROOT/'Game/models/environment/bridge_platforms'
(ROOT/'Builds/Validation/BridgePlatforms/tmp').mkdir(exist_ok=True)
tempfile.tempdir=str(ROOT/'Builds/Validation/BridgePlatforms/tmp')
report=[]
for label,filename in [('deck','cawami_Textured_5510399698.glb'),('cantilever','cawawa_Textured_5510299699.glb')]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(Path(r'C:\Users\tgden\Downloads')/filename))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 # Imported source stays editable. Decimation is non-destructive in the .blend.
 original=sum(len(o.data.polygons) for o in objects)
 for o in objects:
  o.name='Bridge_'+label
  bpy.context.view_layer.objects.active=o;o.select_set(True)
  mod=o.modifiers.new('Game mesh 64000 triangles','DECIMATE');mod.ratio=min(1.,64000/len(o.data.polygons));mod.use_collapse_triangulate=True
  for mat in o.data.materials:
   if not mat or not mat.use_nodes:continue
   nodes=mat.node_tree.nodes;principled=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
   # Cel materials use only the colour atlas, not multi-megabyte normal/MR maps.
   base=principled.inputs['Base Color']
   used=base.links[0].from_node.image if base.is_linked and base.links[0].from_node.type=='TEX_IMAGE' else None
   for socket in ['Normal','Metallic','Roughness']:
    for link in list(principled.inputs[socket].links):mat.node_tree.links.remove(link)
   principled.inputs['Metallic'].default_value=0.;principled.inputs['Roughness'].default_value=.95
   for n in list(nodes):
    if n.type=='TEX_IMAGE' and n.image!=used:nodes.remove(n)
   if used:
    painted=ROOT/('Game/art/cel_scene/bridge_'+label+'_atlas_v2.png')
    if painted.exists():
     used=bpy.data.images.load(str(painted),check_existing=True);base.links[0].from_node.image=used
    used.scale(min(2048,used.size[0]),min(2048,used.size[1]));used.filepath_raw=str(OUT/(label+'_colour.png'));used.file_format='PNG';used.save();used.pack()
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/('Source/Environment/BridgePlatforms/'+label+'.blend')))
 deps=bpy.context.evaluated_depsgraph_get();decks=[];bounds=[];triangles=0
 for o in objects:
  ev=o.evaluated_get(deps);mesh=ev.to_mesh();mesh.calc_loop_triangles();triangles+=len(mesh.loop_triangles)
  verts=[o.matrix_world@v.co for v in mesh.vertices];tree=BVHTree.FromPolygons(verts,[list(p.vertices) for p in mesh.polygons])
  bounds.extend(verts)
  for x in [-.7,-.3,0.,.3,.7]:
   for y in [-.15,0.,.15]:
    hit=tree.ray_cast(Vector((x,y,4.)),Vector((0,0,-1)),5.)
    if hit[0]:decks.append(round(hit[0].z,5))
  ev.to_mesh_clear()
 bpy.ops.export_scene.gltf(filepath=str(OUT/(label+'.glb')),export_format='GLB',use_selection=False,export_apply=True,export_cameras=False,export_lights=False,export_image_format='AUTO')
 report.append({'asset':label,'original_file':filename,'source_bytes':(Path(r'C:\Users\tgden\Downloads')/filename).stat().st_size,'game_bytes':(OUT/(label+'.glb')).stat().st_size,'source_triangles':original,'game_triangles':triangles,'deck_samples':decks,'deck_height':sorted(decks)[len(decks)//2],'min':[min(p[i] for p in bounds) for i in range(3)],'max':[max(p[i] for p in bounds) for i in range(3)]})
(ROOT/'Source/Environment/BridgePlatforms/optimisation.json').write_text(json.dumps(report,indent=2))
print('BRIDGE_ASSETS_READY',json.dumps(report))
