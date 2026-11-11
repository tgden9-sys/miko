import bpy,bmesh,pathlib,tempfile,json,statistics
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');tempfile.tempdir=str(root/'Builds/Validation/Overhang')
reports=[]
for kind,folder,out in [('overhang','Source/Environment/OverhangBuilding','Game/models/environment/overhang_building/overhang.glb'),('cargo','Source/Props/HeavyCargo','Game/models/props/heavy_cargo/heavy_cargo.glb')]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(root/folder/'original.glb'))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in meshes:
  bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 points=[v.co for o in meshes for v in o.data.vertices]
 lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
 if kind=='overhang':
  low=[p for p in points if p.z<lo.z+(hi.z-lo.z)*.4];support=min(p.x for p in low)
  o=meshes[0];tree=BVHTree.FromPolygons([v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons])
  roofs=[];ceilings=[]
  for x in [lo.x*.7,lo.x*.35,hi.x*.4,hi.x*.7]:
   for y in [-.22,0,.22]:
    hit=tree.ray_cast(Vector((x,y,hi.z+1)),Vector((0,0,-1)))[0]
    if hit:roofs.append(hit.z)
  for x in [lo.x*.7,lo.x*.5,lo.x*.3]:
   hit=tree.ray_cast(Vector((x,0,.02)),Vector((0,0,1)))[0]
   if hit:ceilings.append(hit.z)
  roof=statistics.median(roofs);ceiling=statistics.median(ceilings)
  print('MEASURED',roof,ceiling,'support',support)
  for o in meshes:
   bm=bmesh.new();bm.from_mesh(o.data)
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,roof),plane_no=(0,0,1),dist=.00001,clear_outer=True)
   edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-roof)<.0001 for v in e.verts)]
   bmesh.ops.holes_fill(bm,edges=edges,sides=0);bm.to_mesh(o.data);bm.free()
   for v in o.data.vertices:
    p=v.co;p.x=(p.x-support)*(5.6/(support-lo.x) if p.x<support else 3.2/(hi.x-support))
    p.y=(p.y-(lo.y+hi.y)*.5)*3./(hi.y-lo.y)
    p.z=(p.z-lo.z)*4.4/(ceiling-lo.z) if p.z<=ceiling else 4.4+(p.z-ceiling)*1.3/(roof-ceiling)
 else:
  for o in meshes:
   for v in o.data.vertices:
    p=v.co;p.x=(p.x-(lo.x+hi.x)*.5)*2.2/(hi.x-lo.x);p.y=(p.y-(lo.y+hi.y)*.5)*1.4/(hi.y-lo.y);p.z=(p.z-lo.z)*1.8/(hi.z-lo.z)
 before=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
 for o in meshes:
  bpy.context.view_layer.objects.active=o
  if before>64000:
   mod=o.modifiers.new('Game mesh','DECIMATE');mod.ratio=64000/before;bpy.ops.object.modifier_apply(modifier=mod.name)
  for mat in o.data.materials:
   if not mat or not mat.use_nodes:continue
   bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
   if bs:
    for name in ['Normal','Metallic','Roughness']:
     for link in list(bs.inputs[name].links):mat.node_tree.links.remove(link)
    bs.inputs['Metallic'].default_value=0.;bs.inputs['Roughness'].default_value=.9
 bpy.ops.wm.save_as_mainfile(filepath=str(root/folder/(kind+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(root/out),export_format='GLB',export_image_format='AUTO')
 reports.append({'asset':kind,'source_triangles':before,'game_triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons),'bytes':(root/out).stat().st_size})
(root/'Builds/Validation/Overhang/preparation.json').write_text(json.dumps(reports,indent=2))
