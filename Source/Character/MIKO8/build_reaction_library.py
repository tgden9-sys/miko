import bpy,os,math,json,struct,numpy as np,glob
from mathutils import Matrix,Vector,Quaternion
B=os.path.dirname(os.path.abspath(__file__));G=os.path.abspath(B+'/../../../Game/models/miko8');Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8/reactions');os.makedirs(Q,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Actions_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];sc.render.fps=30
rig.animation_data.action=None
for t in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(t)
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
rest={b.name:b.matrix_local.copy() for b in rig.data.bones};names=list(rest)
text=open(B+'/export_native_clips.py').read();exec(text[text.index("mapping={'DEF-hips'"):text.index("keep={'Idle_Loop'")])
labels={'crawl-enter':'CrawlEnter','crawl-exit':'CrawlExit','crawl-fwd-loop':'CrawlForward','crawl-idle-loop':'CrawlIdle','death01':'Death1','death02':'Death2','hit-knockback':'HitKnockback','hit-knockback-rm':'HitKnockbackRM','hit-head':'HitHead','hit-shoulder-l':'HitShoulderLeft','hit-stomach':'HitStomach','ground-sit-enter':'GroundSitEnter','ground-sit-idle-loop':'GroundSitIdle','ground-sit-exit':'GroundSitExit'}
meta={'clips':{}};validation={};C=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)));D=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
conversion=text[text.index(" raw=open(path,'rb').read()"):text.index('# Inspect native contact trajectories')]
old="label=('SprintEnter' if 'enter' in path else 'SprintExit' if 'exit' in path else 'Sprint' if 'sprint' in path else ('Turn180' if '180' in path else 'Turn90')+('Left' if '-l' in os.path.basename(path) else 'Right'))"
conversion=conversion.replace(old,'label=labels[key]').replace("'loop':label=='Sprint'","'loop':'loop' in key")
for path in sorted(glob.glob(B+'/Templates/**/*.glb',recursive=True)):
 key=os.path.basename(path).removeprefix('quaternius-ual1-').removeprefix('quaternius-ual2-').removesuffix('.glb')
 if key not in labels:continue
 existing=bpy.data.actions.get('MIKO8_'+labels[key])
 if existing:bpy.data.actions.remove(existing)
 exec('\n'.join(line[1:] if line.startswith(' ') else line for line in conversion.splitlines()))
 label=labels[key];data=meta['clips'][label];a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0];data['frames']=[];hands=[]
 count=round(data['duration']*30)
 for f in range(count+1):
  sc.frame_set(f);bpy.context.view_layer.update();values={}
  for b in rig.data.bones:
   m=rig.pose.bones[b.name].matrix.copy();local=rig.pose.bones[b.parent.name].matrix.inverted()@m if b.parent else m
   q=((D@local.to_3x3()) if not b.parent else local.to_3x3()).to_quaternion();v=D@local.translation if not b.parent else local.translation
   values[b.name]={'p':list(v),'q':[q.x,q.y,q.z,q.w]}
  data['frames'].append(values)
  hands.append({side:list(rig.pose.bones['DEF-hand.'+side].matrix.translation) for side in ['L','R']})
 if label=='CrawlForward':
  speeds=[]
  for side in ['L','R']:
   floor=min(h[side][2] for h in hands)
   for first,second in zip(hands,hands[1:]):
    speed=(second[side][1]-first[side][1])*30
    if first[side][2]<floor+.05 and second[side][2]<floor+.05 and speed>.05:speeds.append(speed)
  data['speed']=float(np.median(speeds)) if speeds else .55
 print('EXTRA_READY',label,data['duration'],data.get('speed'),len(data['frames']),flush=True)
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
json.dump(meta,open(G+'/MIKO8_Reactions.json','w'));json.dump(validation,open(Q+'/source_conversion.json','w'),indent=2)
# Save animation-only source: the accepted dense character asset is not re-exported.
for a in bpy.data.actions:
 if a.name.startswith('MIKO8_'):a.use_fake_user=True
for o in list(bpy.data.objects):
 if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_Reactions_Rig.blend')
print('REACTIONS_CONVERTED',len(meta['clips']),flush=True)
