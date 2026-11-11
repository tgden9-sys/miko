import bpy,os,json,math
from mathutils import Matrix,Vector
P=os.path.dirname(os.path.abspath(__file__));B=os.path.abspath(P+'/../..');G=os.path.abspath(B+'/../../../Game/models/miko8')
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;sc.render.fps=30
rig=bpy.data.objects['MIKO8_Rig'];rig.animation_data.action=None
for t in rig.animation_data.nla_tracks:t.mute=True
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
bpy.ops.import_scene.fbx(filepath=P+'/SkeletonSettings.fbx');ref=next(o for o in bpy.context.selected_objects if o.type=='ARMATURE');sc.frame_set(1);bpy.context.view_layer.update();refm={p.name:p.matrix.copy() for p in ref.pose.bones}
bpy.ops.import_scene.fbx(filepath=P+'/A_Ladder_Up_Loop.fbx');src=next(o for o in bpy.context.selected_objects if o.type=='ARMATURE');action=src.animation_data.action
start,end=action.frame_range;duration=(end-start)/(sc.render.fps/sc.render.fps_base)
mapping={'DEF-hips':'pelvis','DEF-spine.001':'spine_01','DEF-spine.002':'spine_03','DEF-spine.003':'spine_05','DEF-neck':'neck_01','DEF-head':'head'}
for s,t in [('L','l'),('R','r')]:
 for a,b in [('shoulder','clavicle'),('upper_arm','upperarm'),('forearm','lowerarm'),('hand','hand'),('thigh','thigh'),('shin','calf'),('foot','foot'),('toe','ball')]:mapping['DEF-'+a+'.'+s]=b+'_'+t
 for a,b in [('f_index','index'),('f_middle','middle'),('f_ring','ring'),('f_pinky','pinky'),('thumb','thumb')]:
  for i in range(1,4):mapping[f'DEF-{a}.{i:02}.{s}']=f'{b}_{i:02}_{t}'
scale=rest['DEF-hips'].translation.z/(refm['pelvis'].translation.z*.01)
C=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
count=40;frames=[];root=[];errors=[]
for i in range(count):
 f=start+(end-start)*i/(count-1);sc.frame_set(int(f),subframe=f%1);bpy.context.view_layer.update();poses={p.name:p.matrix.copy() for p in src.pose.bones};desired={};values={}
 for b in rig.data.bones:
  n=b.name; r=rest[n];pn=b.parent.name if b.parent else None
  rot=r.to_quaternion()
  if n in mapping:
   sn=mapping[n];rot=poses[sn].to_quaternion()@refm[sn].to_quaternion().inverted()@r.to_quaternion()
  elif pn:rot=desired[pn].to_quaternion()@rest[pn].to_quaternion().inverted()@r.to_quaternion()
  pos=r.translation.copy() if not pn else desired[pn]@(rest[pn].inverted()@r.translation)
  if n=='DEF-hips':
   delta=(poses['pelvis'].translation-refm['pelvis'].translation)*(.01*scale)

   pos+=delta
  mat=rot.to_matrix().to_4x4();mat.translation=pos;desired[n]=mat
  local=desired[pn].inverted()@mat if pn else mat
  localrest=rest[pn].inverted()@r if pn else r
  # glTF retains Blender bone-local axes. Only the top-level bone changes world basis.
  q=((C@local.to_3x3()) if not pn else local.to_3x3()).to_quaternion()
  v=C@local.translation if not pn else local.translation
  values[n]={'p':list(v),'q':[q.x,q.y,q.z,q.w]}
 frames.append(values)
 root.append([float(v) for v in (src.matrix_world@poses['pelvis']).translation])
data={'source':'VanillaLoop Free Sample Animation Set / A_Ladder_Up_Loop.fbx','duration':duration,'scale':scale,'rise':(root[-1][2]-root[0][2])*scale,'frames':frames,'root_source_m':root}
os.makedirs(G,exist_ok=True);json.dump(data,open(G+'/VanillaLoop_Ladder_Trial.json','w'))
print('TRIAL_EXPORTED',duration,scale,len(frames), 'mapping',len(mapping))




