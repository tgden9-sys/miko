import bpy,os,math,json,struct,numpy as np,glob
from mathutils import Matrix,Vector,Quaternion
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8');G=os.path.abspath(B+'/../../../Game/models/miko8');os.makedirs(G,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Rig.blend');sc=bpy.context.scene;sc.render.fps=30;rig=bpy.data.objects['MIKO8_Rig'];mesh=bpy.data.objects['MIKO8_Mesh'];rig.animation_data_create()
rest={b.name:b.matrix_local.copy() for b in rig.data.bones};names=list(rest)
# Recover seconds for the first binding checkpoint; later rebuilds already import at native timing.
time_scale=float(rig.get('source_timing_scale',1.25))
if abs(time_scale-1)>1e-6:
 for a in bpy.data.actions:
  for layer in a.layers:
   for strip in layer.strips:
    for bag in strip.channelbags:
     for fc in bag.fcurves:
      for k in fc.keyframe_points:k.co.x/=time_scale;k.handle_left.x/=time_scale;k.handle_right.x/=time_scale
rig['source_timing_scale']=1.0
mapping={'DEF-hips':'hips','DEF-spine.001':'spine','DEF-spine.002':'chest','DEF-spine.003':'upperChest','DEF-neck':'neck','DEF-head':'head'}
for s,side in [('L','left'),('R','right')]:
 for bone,node in [('shoulder','Shoulder'),('upper_arm','UpperArm'),('forearm','LowerArm'),('hand','Hand'),('thigh','UpperLeg'),('shin','LowerLeg'),('foot','Foot'),('toe','Toes')]:mapping[f'DEF-{bone}.{s}']=side+node
 for digit in ['index','middle','ring','pinky','thumb']:
  for i,suffix in enumerate(['Proximal','Intermediate','Distal'] if digit!='thumb' else ['Metacarpal','Proximal','Distal']):
   n=f'DEF-f_{digit}.{i+1:02d}.{s}' if digit!='thumb' else f'DEF-thumb.{i+1:02d}.{s}'
   mapping[n]=side+('Little' if digit=='pinky' else digit.title())+suffix
keep={'Idle_Loop':'Idle','Walk_Loop':'Walk','Jog_Fwd_Loop':'Run','Jump_Start':'JumpStart','Jump_Loop':'JumpAir','Jump_Land':'JumpLand'}
meta={'fps':30,'animation_policy':'Native source poses and seconds retained. Template conversion only changes skeleton coordinate basis. No gait edits, IK, gaze offsets, or time warping.','clips':{}}
for a in list(bpy.data.actions):
 if a.name in keep:
  label=keep[a.name];a.name='MIKO8_'+label;meta['clips'][label]={'duration':float(a.frame_range[1])/30,'loop':label in ['Idle','Walk','Run','JumpAir'],'source':'Quaternius Standard/'+next(k for k,v in keep.items() if v==label)}
 else:bpy.data.actions.remove(a)
C=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
validation={}
for path in glob.glob(B+'/Templates/**/*.glb',recursive=True):
 raw=open(path,'rb').read();doc=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]]);nodes=doc['nodes'];parents={c:i for i,n in enumerate(nodes) for c in n.get('children',[])};cache={}
 def world(i):
  if i not in cache:
   n=nodes[i];q=n.get('rotation',[0,0,0,1]);m=Matrix.LocRotScale(Vector(n.get('translation',[0,0,0])),Quaternion((q[3],q[0],q[1],q[2])),Vector(n.get('scale',[1,1,1])));cache[i]=(world(parents[i]) if i in parents else Matrix.Identity(4))@m
  return cache[i]
 sr={n['name']:C@world(i)@C.inverted() for i,n in enumerate(nodes)}
 before=set(bpy.data.objects);oldactions=set(bpy.data.actions);bpy.ops.import_scene.gltf(filepath=path);objects=set(bpy.data.objects)-before;newactions=set(bpy.data.actions)-oldactions;sa=next(iter(newactions));obj={o.name.split('.')[0]:o for o in objects}
 label=('SprintEnter' if 'enter' in path else 'SprintExit' if 'exit' in path else 'Sprint' if 'sprint' in path else ('Turn180' if '180' in path else 'Turn90')+('Left' if '-l' in os.path.basename(path) else 'Right'))
 correction={n:sr[mapping[n]].inverted()@rest[n] for n in mapping};duration=max(doc['accessors'][s['input']]['max'][0] for s in doc['animations'][0]['samplers']);count=round(duration*30)
 action=bpy.data.actions.new('MIKO8_'+label);action.use_fake_user=True;rig.animation_data.action=action;prev={};expected={};hipmotion=[];yaws=[]
 for f in range(count+1):
  sc.frame_set(f);bpy.context.view_layer.update();desired={'root':rest['root'].copy()}
  for n,node in mapping.items():desired[n]=obj[node].matrix_world@correction[n]
  hip=desired['DEF-hips'];yaw=(hip.to_quaternion()@rest['DEF-hips'].to_quaternion().inverted()).to_swing_twist('Z')[1]
  if yaws:
   while yaw-yaws[-1]>math.pi:yaw-=math.tau
   while yaw-yaws[-1]<-math.pi:yaw+=math.tau
  yaws.append(yaw);hipmotion.append([hip.translation.x,hip.translation.z,-hip.translation.y])
  expected[f]={n:m.copy() for n,m in desired.items()}
  for n in names:
   b=rig.data.bones[n];basis=rest[n].inverted()@rest[b.parent.name]@desired[b.parent.name].inverted()@desired[n] if b.parent else rest[n].inverted()@desired[n]
   p=rig.pose.bones[n];p.location,q,p.scale=basis.decompose();q.make_compatible(prev[n]) if n in prev else None;prev[n]=q.copy();p.rotation_mode='QUATERNION';p.rotation_quaternion=q
   for prop in ['location','rotation_quaternion','scale']:p.keyframe_insert(data_path=prop,frame=f,group=n)
 for layer in action.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for fc in bag.fcurves:
     for k in fc.keyframe_points:k.interpolation='LINEAR'
 error=0
 for f in list(range(count+1))+[count,0,2,1,0]:
  sc.frame_set(f);bpy.context.view_layer.update()
  for n in names:error=max(error,max(abs(rig.pose.bones[n].matrix[i][j]-expected[f][n][i][j]) for i in range(4) for j in range(4)))
 assert error<.00002,(label,error);validation[label]={'template_world_matrix_error':error,'samples':count+1}
 meta['clips'][label]={'duration':duration,'loop':label=='Sprint','source':os.path.relpath(path,B),'hip_motion':hipmotion,'yaw':yaws}
 for o in objects:bpy.data.objects.remove(o,do_unlink=True)
 for a in newactions:bpy.data.actions.remove(a)
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
 print('NATIVE_CLIP',label,duration,error,flush=True)
# Inspect native contact trajectories and derive controller speeds from unchanged foot travel.
for label,data in meta['clips'].items():
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a
 if a.slots:rig.animation_data.action_slot=a.slots[0]
 count=round(data['duration']*30);track=[]
 for f in range(count+1):
  sc.frame_set(f);bpy.context.view_layer.update();track.append({s:list(rig.pose.bones['DEF-foot.'+s].matrix.translation) for s in ['L','R']})
 data['feet']=track
 if label in ['Walk','Run','Sprint']:
  speeds=[]
  for s in ['L','R']:
   floor=min(p[s][2] for p in track)
   for p,q in zip(track,track[1:]):
    speed=(q[s][1]-p[s][1])*30
    if p[s][2]<floor+.08 and speed>.1:speeds.append(speed)
  data['speed']=float(np.median(speeds));print('SPEED',label,data['speed'],flush=True)
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
sc.frame_set(0)
for a in bpy.data.actions:
 a.use_fake_user=True;t=rig.animation_data.nla_tracks.new();t.name=a.name;strip=t.strips.new(a.name,0,a)
 if a.slots:strip.action_slot=a.slots[0]
for o in sc.objects:o.select_set(o in [rig,mesh])
bpy.context.view_layer.objects.active=rig
json.dump(meta,open(B+'/MIKO8_Native.json','w'),indent=2);json.dump(meta,open(G+'/MIKO8_Native.json','w'),indent=2);json.dump(validation,open(Q+'/native_conversion_validation.json','w'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_Native_Animated.blend')
bpy.ops.export_scene.gltf(filepath=G+'/MIKO8_Native.glb',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_morph=False)
print('NATIVE_EXPORT_COMPLETE',flush=True)
