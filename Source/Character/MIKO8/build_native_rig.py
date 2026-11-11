import bpy,bmesh,os,json,math,numpy as np,time
from mathutils import Matrix,Vector
from mathutils.kdtree import KDTree
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8');os.makedirs(Q,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_inspection.blend')
sc=bpy.context.scene;sc.render.fps=30
mesh=next(o for o in sc.objects if o.type=='MESH');mesh.name='MIKO8_Mesh';mesh.parent=None;mesh.matrix_world=Matrix.Identity(4)
v=np.empty(len(mesh.data.vertices)*3,dtype=np.float32);mesh.data.vertices.foreach_get('co',v);v=v.reshape(-1,3);v[:,2]-=v[:,2].min();v*=1.8;mesh.data.vertices.foreach_set('co',v.ravel());mesh.data.update()
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(B+'/../MIKO7/Quaternius/Animation Library[Standard]/Godot/AnimationLibrary_Godot_Standard.glb'))
rig=next(o for o in set(bpy.data.objects)-before if o.type=='ARMATURE');rig.name='MIKO8_Rig'
for o in set(bpy.data.objects)-before:
 if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
rig.animation_data_clear();rest={b.name:b.matrix_local.copy() for b in rig.data.bones};tails={b.name:b.tail_local.copy() for b in rig.data.bones}
rig['source_timing_scale']=1.0
# glTF importer uses the scene's 30 fps: source key times already retain their seconds.
points={'root':(0,0,0),'DEF-hips':(0,.015,.505),'DEF-spine.001':(0,.014,.565),'DEF-spine.002':(0,.012,.638),'DEF-spine.003':(0,.01,.708),'DEF-neck':(0,.01,.776),'DEF-head':(0,.006,.812)}
child={'root':'DEF-hips','DEF-hips':'DEF-spine.001','DEF-spine.001':'DEF-spine.002','DEF-spine.002':'DEF-spine.003','DEF-spine.003':'DEF-neck','DEF-neck':'DEF-head'}
handrots={}
for s,sgn in [('L',1),('R',-1)]:
 for n,p in [('shoulder',(.040,.005,.744)),('upper_arm',(.127,.005,.735)),('forearm',(.175,.002,.603)),('hand',(.215,-.005,.485)),('thigh',(.065,.015,.505)),('shin',(.083,.012,.312)),('foot',(.09,.025,.099)),('toe',(.09,-.075,.025))]:points[f'DEF-{n}.{s}']=(p[0]*sgn,p[1],p[2])
 for a,b in [('shoulder','upper_arm'),('upper_arm','forearm'),('forearm','hand'),('thigh','shin'),('shin','foot'),('foot','toe')]:child[f'DEF-{a}.{s}']=f'DEF-{b}.{s}'
 # Fit the splayed palm to the mesh; source finger motion is retained on the final canonical rig.
 d=Vector((.24*sgn,0,-.97077));spread=Vector((-.97077*sgn,0,-.24));normal=(d*sgn).cross(spread)
 H=Matrix((d*sgn,spread,normal)).transposed();handrots[s]=H
 anchor=rest[f'DEF-hand.{s}'].translation
 for n,m in rest.items():
  if (('f_' in n or 'thumb.' in n) and n.endswith('.'+s)):
   points[n]=tuple(Vector(points[f'DEF-hand.{s}'])*1.8+H@(m.translation-anchor)*.80)
 # Individually place joints in the mesh's open, splayed fingers (the thumb is on the outer edge).
 paths={
 'index':[(.277,-.024,.438),(.296,-.024,.415),(.306,-.023,.400),(.313,-.022,.389)],
 'middle':[(.254,-.025,.427),(.267,-.025,.396),(.279,-.024,.375),(.281,-.023,.361)],
 'ring':[(.235,-.024,.423),(.242,-.024,.390),(.248,-.023,.368),(.249,-.022,.349)],
 'pinky':[(.215,-.023,.423),(.214,-.023,.394),(.213,-.022,.375),(.213,-.021,.360)],
 'thumb':[(.236,-.025,.485),(.263,-.025,.477),(.284,-.024,.470),(.294,-.023,.461)]}
 for digit,path in paths.items():
  for i in range(3):
   n=f'DEF-f_{digit}.{i+1:02d}.{s}' if digit!='thumb' else f'DEF-thumb.{i+1:02d}.{s}'
   points[n]=tuple(Vector((path[i][0]*sgn,path[i][1],path[i][2]))*1.8)
   if i<2:child[n]=f'DEF-f_{digit}.{i+2:02d}.{s}' if digit!='thumb' else f'DEF-thumb.{i+2:02d}.{s}'
   else:child[n]='TIP_'+n;points[child[n]]=tuple(Vector((path[3][0]*sgn,path[3][1],path[3][2]))*1.8)
for n in list(points):
 if not ('f_' in n or 'thumb.' in n or n.startswith('TIP_')):points[n]=tuple(Vector(points[n])*1.8)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:
 n=b.name;b.use_connect=False;b.head=points[n]
 if n in child:b.tail=points[child[n]]
 elif n=='DEF-head':b.tail=b.head+Vector((0,0,.22))
 elif n.startswith('DEF-toe'):b.tail=b.head+Vector((0,-.075,0))
 elif n.startswith('DEF-hand'):
  b.tail=points[f'DEF-f_middle.01.{n[-1]}']
 else:b.tail=b.head+handrots[n[-1]]@(tails[n]-rest[n].translation)*.80
 if (b.tail-b.head).length<.005:b.tail=b.head+Vector((0,0,.015))
 rot=rest[n].to_3x3();old=(tails[n]-rest[n].translation).normalized();new=(b.tail-b.head).normalized();r=old.rotation_difference(new).to_matrix()@rot
 if any(k in n for k in ['hand.','f_','thumb.']):
  H=handrots[n[-1]];r=(H@old).rotation_difference(new).to_matrix()@H@rot
 b.align_roll(r.col[2]);b.use_deform=n!='root'
bpy.ops.object.mode_set(mode='OBJECT');fitted={b.name:b.matrix_local.copy() for b in rig.data.bones}
names=[n for n in rest if n!='root'];groups={n:mesh.vertex_groups.new(name=n) for n in names};dist=np.empty((len(v),len(names)),dtype=np.float32)
for j,n in enumerate(names):
 b=rig.data.bones[n];a=np.array(b.head_local);d=np.array(b.tail_local)-a;t=np.clip(((v-a)@d)/(d@d),0,1);dist[:,j]=np.sum((v-a-t[:,None]*d)**2,axis=1)
 # Anatomical barriers prevent weights crossing adjacent limbs or the arm/torso gap.
 if n.endswith('.L'):dist[v[:,0]<0,j]+=10
 if n.endswith('.R'):dist[v[:,0]>0,j]+=10
 if any(k in n for k in ['thigh','shin','foot','toe']):dist[v[:,2]>1.8*.55,j]+=10
 if any(k in n for k in ['shoulder','upper_arm','forearm','hand','f_','thumb']):dist[v[:,2]<1.8*.34,j]+=10
 if n.startswith('DEF-spine') or n=='DEF-hips':dist[np.abs(v[:,0])>1.8*.135,j]+=.05
 if 'f_' in n or 'thumb' in n:dist[v[:,2]>1.8*.46,j]+=10
 if n!='DEF-head':dist[v[:,2]>1.8*.805,j]+=100
 if n=='DEF-head':dist[v[:,2]<1.8*.785,j]+=10
indices=np.argpartition(dist,4,axis=1)[:,:4];ds=np.take_along_axis(dist,indices,axis=1);weights=1/(ds+.00012)**3;weights/=weights.sum(axis=1,keepdims=True)
weights[weights<.008]=0;weights/=weights.sum(axis=1,keepdims=True);warped=np.zeros_like(v)
for j,n in enumerate(names):
 w=np.sum(np.where(indices==j,weights,0),axis=1);ids=np.flatnonzero(w>0)
 scale=Matrix.Identity(4)
 if any(k in n for k in ['upper_arm','forearm','thigh','shin','f_','thumb.']):scale[1][1]=(tails[n]-rest[n].translation).length/rig.data.bones[n].length
 m=np.array(rest[n]@scale@fitted[n].inverted());warped[ids]+=w[ids,None]*(v[ids]@m[:3,:3].T+m[:3,3])
 # Quantized skin weights keep group assignment fast on the dense source mesh.
 quant=np.round(w[ids]*255).astype(int)
 for value in np.unique(quant):
  if value:groups[n].add(ids[quant==value].tolist(),float(value)/255,'REPLACE')
print('EXPLICIT_SKIN',len(v),len(names),flush=True);unweighted=0
# Fit the rigid boot sole to the canonical ankle height in the bind mesh.
for side in [-1,1]:
 ids=np.flatnonzero((v[:,0]*side>0)&(v[:,2]<1.8*.11));floor=float(warped[ids,2].min());ankle=rest['DEF-foot.'+('L' if side>0 else 'R')].translation.z
 warped[ids,2]=ankle+(warped[ids,2]-ankle)*ankle/(ankle-floor)
mesh.data.vertices.foreach_set('co',warped.ravel());mesh.data.update()
bpy.context.view_layer.objects.active=rig;bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.matrix=rest[b.name];b.length=(tails[b.name]-rest[b.name].translation).length
bpy.ops.object.mode_set(mode='OBJECT');mesh.parent=rig;mesh.matrix_parent_inverse=Matrix.Identity(4);mod=mesh.modifiers.new('Quaternius skin','ARMATURE');mod.object=rig
rig.show_in_front=True
sc.frame_set(0);rig.animation_data_create();rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
for a in bpy.data.actions:a.use_fake_user=True
sc.camera.data.ortho_scale=2.3
target=Vector((0,0,.95))
for view,pos in [('front',(0,-5,.95)),('side',(5,0,.95)),('quarter',(3,-5,1.5))]:
 sc.camera.location=pos;sc.camera.rotation_euler=(target-sc.camera.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=Q+'/bound_'+view+'.png';bpy.ops.render.render(write_still=True)
json.dump({'vertices':len(v),'proxy_unweighted':unweighted,'bones':len(rest),'canonical_rest_max_error':max(max(abs(rest[b.name][i][j]-b.matrix_local[i][j]) for i in range(4) for j in range(4)) for b in rig.data.bones)},open(Q+'/binding.json','w'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_Native_Rig.blend')
print('NATIVE_BIND_COMPLETE',flush=True)
