"""Fit supplied tower bodies to a common kit; author clean shared caps/ladders.
Original GLBs are read-only inputs. Runtime coordinates are metres, ground y=0.
"""
import bpy,bmesh,math,pathlib,tempfile,json
import numpy as np
from mathutils import Vector

ROOT=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO')
SRC=ROOT/'Source/Environment/PlatformTowers'
OUT=ROOT/'Game/models/environment/platform_towers_v2'
CHECK=ROOT/'Builds/Validation/TowerArtRevision'
for d in [OUT,CHECK]:d.mkdir(parents=True,exist_ok=True)
tempfile.tempdir=str(CHECK)
SPECS={'small':(2.8,1.58,.43,.23),'medium':(3.55,1.70,.22,.155),'large':(4.3,1.78,.105,.085)}
report={}

def mat(name,colour):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*colour,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*colour,1)
 p.inputs['Metallic'].default_value=0;p.inputs['Roughness'].default_value=1
 return m

def finish(obj,paint,bevel=0):
 bpy.context.view_layer.objects.active=obj
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 if bevel:
  mod=obj.modifiers.new('Manufactured edge bevel','BEVEL');mod.width=bevel;mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
 obj.data.materials.clear();obj.data.materials.append(paint)
 return obj

def box(name,at,size,paint,bevel=.004):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
 return finish(o,paint,bevel)

def bolt(name,at,paint,r=.014,axis='Z'):
 rot=(math.pi/2,0,0) if axis=='Y' else (0,math.pi/2,0) if axis=='X' else (0,0,0)
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=r,depth=.008,location=at,rotation=rot)
 o=bpy.context.object;o.name=name;return finish(o,paint,.001)

def triangle(name,a,b,c,thickness,paint):
 # Triangular plate in the XZ plane, extruded in Blender Y.
 verts=[(x,y+dy,z) for dy in [-thickness/2,thickness/2] for x,y,z in [a,b,c]]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)])
 mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 return finish(o,paint,.003)

def beam(name,a,b,width,depth,paint):
 a,b=Vector(a),Vector(b);delta=b-a
 bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)*.5)
 o=bpy.context.object;o.name=name;o.scale=(width,depth,delta.length)
 o.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
 return finish(o,paint,.004)

def join_new(name,start,parent=None):
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o not in start]
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 if parent:o.parent=parent
 return o

for label,(height,cut,front_limit,ladder_half) in SPECS.items():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(SRC/(label+'_original.glb')))
 imported=[o for o in bpy.context.scene.objects if o.type=='MESH']
 source_count=sum(len(p.vertices)-2 for o in imported for p in o.data.polygons)
 removed=0
 for o in imported:
  bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  # Cut the scan cap off and clear the central ladder corridor through depth.
  # Reconstruction left painted/rung fragments on the inside rear surface;
  # measured clean rear bracing replaces that entire ambiguous centre region.
  bm=bmesh.new();bm.from_mesh(o.data)
  for x in [-ladder_half,ladder_half]:
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(x,0,0),plane_no=(1,0,0))
  discard=[f for f in bm.faces if -ladder_half+.000001<f.calc_center_median().x<ladder_half-.000001]
  removed+=len(discard);bmesh.ops.delete(bm,geom=discard,context='FACES')
  closure=mat('TowerSteelCut',(.27,.32,.31));o.data.materials.append(closure)
  for x in [-ladder_half,ladder_half]:
   edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.x-x)<.00001 for v in e.verts)]
   if edges:
    filled=bmesh.ops.holes_fill(bm,edges=edges,sides=0)
    for f in filled['faces']:f.material_index=len(o.data.materials)-1
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,cut),plane_no=(0,0,1),clear_outer=True)
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,.025),plane_no=(0,0,1),clear_inner=True)
  loose=[v for v in bm.verts if not v.link_faces]
  if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
  bm.to_mesh(o.data);bm.free();o.data.update()
  a=np.array([v.co[:] for v in o.data.vertices])
  band=a[(a[:,2]>.3)&(a[:,2]<cut*.78)]
  xmin,xmax=np.quantile(band[:,0],[.001,.999])
  ymin,ymax=np.quantile(band[:,1],[.001,.999])
  # Body footprint is shared, separate from the cap/ladder dimensional contract.
  sx=.94/(xmax-xmin);sy=.84/(ymax-ymin)
  cx=(xmin+xmax)/2;cy=(ymin+ymax)/2
  for v in o.data.vertices:
   v.co.x=(v.co.x-cx)*sx;v.co.y=(v.co.y-cy)*sy
   v.co.z=.03+(v.co.z-.025)/(cut-.025)*(height-.19)
  o.data.update()
  for paint in o.data.materials:
   if not paint or not paint.use_nodes:continue
   p=paint.node_tree.nodes.get('Principled BSDF')
   image=next((l.from_node.image for l in p.inputs['Base Color'].links if l.from_node.type=='TEX_IMAGE'),None)
   paint.name='TowerSource' if image else 'TowerSteel'
   for key in ['Normal','Metallic','Roughness']:
    for link in list(p.inputs[key].links):paint.node_tree.links.remove(link)
   for n in list(paint.node_tree.nodes):
    if n.type=='TEX_IMAGE' and n.image!=image:paint.node_tree.nodes.remove(n)
   p.inputs['Metallic'].default_value=0;p.inputs['Roughness'].default_value=1
  bpy.context.view_layer.objects.active=o
  dec=o.modifiers.new('Body silhouette budget','DECIMATE')
  dec.ratio=min(1,30000/max(1,sum(len(p.vertices)-2 for p in o.data.polygons)))
  bpy.ops.object.modifier_apply(modifier=dec.name);o.name='SuppliedFrame'
 steel=mat('TowerSteel',(.27,.32,.31));amber=mat('TowerAmber',(.56,.36,.13))
 deck=mat('TowerDeck',(.43,.47,.43));rung=mat('TowerRung',(.46,.50,.47))
 ink=mat('TowerInk',(.035,.048,.05));boltpaint=mat('TowerBolt',(.36,.39,.34))
 start=set(bpy.context.scene.objects)
 bays={'small':1,'medium':2,'large':3}[label]
 low=.14;high=height-.22;step=(high-low)/bays
 for i in range(bays):
  a=low+i*step;b=low+(i+1)*step
  beam('Rear diagonal',(-.34,.355,a),(.34,.355,b),.063,.055,steel)
  beam('Rear diagonal',(.34,.390,a),(-.34,.390,b),.063,.055,steel)
  for z in [a,b]:box('Rear horizontal tie',(0,.385,z),(.76,.06,.065),steel,.005)
  # The supplied side-post coupling plates remain; avoid a duplicate row.
 bracing=join_new('MatchedBracing',start)
 start=set(bpy.context.scene.objects)
 # Identical 2.0 x 1.6 m cap, top exactly at the selected deck height.
 box('Cap edge beam',(0,0,height-.09),(2,1.6,.18),steel,.018)
 box('Flush top plate',(0,0,height-.009),(1.95,1.55,.018),deck,.005)
 for y in [-.803,.803]:
  box('Painted edge stripe',(0,y,height-.075),(1.94,.004,.104),amber,.001)
 for x in [-1.003,1.003]:
  box('Painted end stripe',(x,0,height-.075),(.004,1.54,.104),amber,.001)
 for x in [-.87,.87]:
  for y in [-.808,.808]:
   box('Cap corner splice',(x,y,height-.085),(.17,.009,.151),steel,.007)
   for dz in [-.040,.040]:bolt('Splice bolt',(x,y-.006 if y<0 else y+.006,height-.085+dz),boltpaint,.012,'Y')
 # Sparse deliberate ink seams; no photographic grain or procedural speckles.
 for x in [-.32,.32]:box('Panel seam',(x,0,height+.0008),(.005,1.51,.0016),ink,0)
 box('Panel seam',(0,0,height+.0008),(1.91,.005,.0016),ink,0)
 for x in [-.84,.84]:
  for y in [-.64,.64]:
   bolt('Countersunk roof fixing',(x,y,height+.0015),boltpaint,.031)
   box('Fixing slot',(x,y,height+.006),(.028,.004,.001),ink,0)
 for x in [-.35,.35]:
  for y in [-.33,.33]:
   side=1 if x>0 else -1
   triangle('Cap gusset',(x,y,height-.18),(x,y,height-.44),(side*.82,y,height-.18),.045,steel)
   bolt('Gusset fixing',(x,y-.025,height-.27),boltpaint,.015,'Y')
 # A few clean paint chips, repeated identically across the set.
 for x,w in [(-.85,.045),(-.46,.025),(.18,.055),(.72,.035)]:
  for y in [-.806,.806]:box('Edge paint chip',(x,y,height-.11),(w,.001,.015),steel,0)
 cap=join_new('MatchedDeck',start)
 start=set(bpy.context.scene.objects)
 for x in [-.35,.35]:
  for y in [-.33,.33]:
   box('Ground footplate',(x,y,.015),(.27,.25,.03),steel,.008)
   for dx in [-.095,.095]:bolt('Ground anchor',(x+dx,y,.034),boltpaint,.016)
 feet=join_new('MatchedFeet',start)
 start=set(bpy.context.scene.objects)
 # Blender -Y is the front; all variants use the native 0.43 m rail spacing.
 for x in [-.215,.215]:
  box('Climb rail',(x,-.76,height*.5),(.052,.065,height),steel,.008)
  box('Rail highlight',(x,-.795,height*.5),(.016,.004,height-.06),rung,.002)
  for z in np.arange(.32,height-.20,1.05):
   box('Standoff',(x,-.56,float(z)),(.042,.35,.045),steel,.004)
   box('Standoff receiver',(x,-.395,float(z)),(.11,.03,.13),steel,.003)
 for i in range(1,int((height+.08)/.2648)+1):
  z=i*.2648-.08
  if z>height-.07:break
  box('Grip rung',(0,-.76,z),(.47,.082,.042),rung,.006)
  box('Grip inset',(0,-.764,z+.023),(.39,.055,.006),steel,.001)
  for x in [-.12,0,.12]:box('Grip notch',(x,-.806,z),(.005,.001,.019),ink,0)
 ladder=join_new('ClimbLadder',start)
 # Named mesh groups let middle towers hide their rear-facing ladders entirely.
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(label+'_matched.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(label+'.glb')),export_format='GLB',export_cameras=False,export_lights=False)
 report[label]={'height':height,'platform_width':2.,'platform_depth':1.6,'body_width':.94,'body_depth':.84,'ladder_rail_spacing':.43,'rung_pitch':.2648,
   'source_triangles':source_count,'removed_ladder_faces':removed,'runtime_triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),
   'runtime_bytes':(OUT/(label+'.glb')).stat().st_size}
 (CHECK/'matched_assets.json').write_text(json.dumps(report,indent=2))
 print('MATCHED_TOWER_BUILT',label,report[label],flush=True)
