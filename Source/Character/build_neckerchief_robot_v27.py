"""Extract the new textured torso; retain the master head, FK arms and actions."""
import bpy,bmesh,math,json
from mathutils import Vector
from pathlib import Path

ROOT=Path(__file__).resolve().parent
s=bpy.context.scene;s.frame_set(1)
hover=bpy.data.objects['CTRL | hover body']
old=bpy.data.objects['TORSO | clean nozzle, no fixed plume']
old.hide_render=True;old.hide_viewport=True
old.name='ARCHIVE | former torso before neckerchief v27'
for o in s.objects:
 if 'CAPE |' in o.name or 'THRUSTER |' in o.name:o.hide_render=True
before=set(bpy.data.objects)
source=ROOT/'source_assets_v28'/'sample2.glb'
if not source.exists():source=Path(r'C:\Users\tgden\Downloads\sample (2).glb')
bpy.ops.import_scene.gltf(filepath=str(source))
imported=[o for o in bpy.data.objects if o not in before]
body=next(o for o in imported if o.type=='MESH')
body.name='TORSO | sample 2 neckerchief and single rear chassis v27'
body.parent=None;body.matrix_world.identity()
bm=bmesh.new();bm.from_mesh(body.data)
# glTF splits vertices at UV seams; weld coincident geometry while retaining
# the per-face UV loops before identifying cut boundaries or shell islands.
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000002)
# Neck below the generated helmet, and nozzle above the generated solid flame.
for z,normal in ((-.050,(0,0,1)),(-.349,(0,0,-1))):
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
  plane_co=(0,0,z),plane_no=normal,dist=1e-6,clear_outer=True)
# Split at the arm roots. Retain the collar wings above the shoulders.
for x in (-.17,.17):
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
  plane_co=(x,0,0),plane_no=(1,0,0),dist=1e-6)
remove=[v for v in bm.verts if abs(v.co.x)>.17001 and v.co.z<-.065]
bmesh.ops.delete(bm,geom=remove,context='VERTS')
# Remove disconnected remnants from the cuts, retaining the largest torso island.
remaining=set(bm.verts);components=[]
while remaining:
 seed=remaining.pop();stack=[seed];group={seed}
 while stack:
  v=stack.pop()
  for e in v.link_edges:
   u=e.other_vert(v)
   if u in remaining:remaining.remove(u);group.add(u);stack.append(u)
 components.append(group)
print('SOURCE_TORSO_COMPONENTS',sorted([len(g) for g in components],reverse=True),flush=True)
# The generated torso uses separate front, rear, scarf and nozzle surface islands.
# Preserve these substantial pieces; retaining only one island loses the rear hull.
discard=[v for g in components if len(g)<8 for v in g]
if discard:bmesh.ops.delete(bm,geom=discard,context='VERTS')
boundary=[e for e in bm.edges if e.is_boundary]
if boundary:
 result=bmesh.ops.holes_fill(bm,edges=boundary,sides=0)
 for f in result.get('faces',[]):f.smooth=False
# Fit neck and shoulder height separately from the nozzle to preserve the old rig.
for v in bm.verts:
 z=v.co.z
 v.co.x*=1.08
 v.co.y-=.105
 v.co.z=(-.145+(z+.14)*(.145/.107)) if z>=-.14 else (-.145+(z+.14)*(.195/.209))
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(body.data);bm.free();body.data.update()
body.parent=hover;body.matrix_parent_inverse.identity()
for p in body.data.polygons:p.use_smooth=True
body['source']='sample (2).glb; original UV atlas retained'
body['rig_compatibility']='Existing head and all six arm controls retained without pivot changes'
for m in body.data.materials:
 m.name='TORSO | ivory armor and blue neckerchief source atlas v27'
 for n in m.node_tree.nodes:
  if n.type=='BSDF_PRINCIPLED':
   n.inputs['Roughness'].default_value=.61
   n.inputs['Metallic'].default_value=.10
 # Darken only the blue atlas regions, preserving the ivory plating and wear.
 tree=m.node_tree;tex=next(n for n in tree.nodes if n.type=='TEX_IMAGE')
 principled=next(n for n in tree.nodes if n.type=='BSDF_PRINCIPLED')
 sep=tree.nodes.new('ShaderNodeSeparateColor');tree.links.new(tex.outputs['Color'],sep.inputs['Color'])
 rg=tree.nodes.new('ShaderNodeMath');rg.operation='SUBTRACT';tree.links.new(sep.outputs['Blue'],rg.inputs[0]);tree.links.new(sep.outputs['Red'],rg.inputs[1])
 mask=tree.nodes.new('ShaderNodeMapRange');mask.clamp=True;mask.inputs['From Min'].default_value=.005;mask.inputs['From Max'].default_value=.060;tree.links.new(rg.outputs[0],mask.inputs['Value'])
 mix=tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[2].default_value=(.32,.48,.70,1)
 tree.links.new(mask.outputs[0],mix.inputs[0]);tree.links.new(tex.outputs['Color'],mix.inputs[1]);tree.links.new(mix.outputs[0],principled.inputs['Base Color'])

def material(name,color,metallic,roughness):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
 p.inputs['Metallic'].default_value=metallic;p.inputs['Roughness'].default_value=roughness
 return m
graphite=material('SOCKET | recessed graphite v27',(.018,.024,.032),.25,.55)
blue=material('SOCKET | muted blue machined lip v27',(.035,.065,.095),.28,.50)
inner=material('JOINT | spherical dark steel v27',(.025,.032,.040),.35,.50)

# A closed neck coupling replaces the cut helmet underside and prevents a gap
# when the retained head turns independently above the short neckerchief.
neckverts=[];neckfaces=[];n=64
profile=[(.004,.100),(-.006,.117),(-.029,.125),(-.045,.114)]
for z,r in profile:
 for i in range(n):
  a=2*math.pi*i/n;neckverts.append((r*math.cos(a),-.105+r*math.sin(a),z))
for j in range(len(profile)-1):
 for i in range(n):neckfaces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
neckfaces.extend([tuple(reversed(range(n))),tuple((len(profile)-1)*n+i for i in range(n))])
mesh=bpy.data.meshes.new('Neck coupling closed profile');mesh.from_pydata(neckverts,[],neckfaces);mesh.materials.append(graphite)
neck=bpy.data.objects.new('NECK | closed recessed coupling v27',mesh);s.collection.objects.link(neck);neck.parent=hover
for p in mesh.polygons:p.use_smooth=len(p.vertices)==4

def socket(side,sign):
 verts=[];faces=[];steps=64
 # Continuous hollow socket with a recessed cup and a restrained blue bevel.
 rings=[(.166,.043),(.181,.053),(.198,.055),(.211,.046),(.216,.034),(.190,.030)]
 center=Vector((0,-.10,-.145))
 for x,r in rings:
  for i in range(steps):
   a=2*math.pi*i/steps
   verts.append((sign*x,center.y+r*math.cos(a),center.z+r*math.sin(a)))
 for j in range(len(rings)-1):
  for i in range(steps):
   k=(i+1)%steps
   face=(j*steps+i,j*steps+k,(j+1)*steps+k,(j+1)*steps+i)
   faces.append(face if sign>0 else tuple(reversed(face)))
 mesh=bpy.data.meshes.new(f'{side} socket cup mesh');mesh.from_pydata(verts,[],faces);mesh.update()
 ob=bpy.data.objects.new(f'SOCKET | {side} recessed shoulder cup v27',mesh);s.collection.objects.link(ob)
 ob.parent=hover;mesh.materials.append(graphite);mesh.materials.append(blue)
 for p in mesh.polygons:p.use_smooth=True;p.material_index=1 if p.index//steps in (1,2) else 0
 # Add a real rotating ball to the existing upper-arm mesh, so every exporter
 # and all old FK actions carry it along with the same upper-arm object.
 upper=bpy.data.objects[f'{side} UPPER ARM | editable segment']
 upper.data.materials.append(inner);mi=len(upper.data.materials)-1
 b=bmesh.new();b.from_mesh(upper.data)
 inv=upper.matrix_world.inverted();pivot=bpy.data.objects[f'CTRL | {side} shoulder'].matrix_world.translation
 rings_v=[]
 for j in range(1,16):
  phi=math.pi*j/16;row=[]
  for i in range(32):
   a=2*math.pi*i/32
   world=pivot+Vector((math.cos(phi)*.032,math.sin(phi)*math.cos(a)*.033,math.sin(phi)*math.sin(a)*.033))
   row.append(b.verts.new(inv@world))
  rings_v.append(row)
 poles=[b.verts.new(inv@(pivot+Vector((x*.032,0,0)))) for x in (1,-1)]
 newfaces=[]
 for j in range(len(rings_v)-1):
  for i in range(32):newfaces.append(b.faces.new((rings_v[j][i],rings_v[j][(i+1)%32],rings_v[j+1][(i+1)%32],rings_v[j+1][i])))
 for i in range(32):
  newfaces.append(b.faces.new((poles[0],rings_v[0][(i+1)%32],rings_v[0][i])))
  newfaces.append(b.faces.new((poles[1],rings_v[-1][i],rings_v[-1][(i+1)%32])))
 for f in newfaces:f.material_index=mi;f.smooth=True
 bmesh.ops.recalc_face_normals(b,faces=list(b.faces));b.to_mesh(upper.data);b.free()

socket('L',-1);socket('R',1)
for o in imported:
 if o!=body:bpy.data.objects.remove(o,do_unlink=True)
s.name='ROBOT neckerchief torso and original articulated rig v27'
s.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'robot_neckerchief_v27.blend'))
print('BUILT_NECKERCHIEF',len(body.data.vertices),'vertices; existing actions retained',flush=True)
