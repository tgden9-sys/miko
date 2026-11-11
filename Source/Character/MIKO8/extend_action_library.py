"""Append the user's climbing and spell clips without rebuilding the accepted bind mesh."""
import bpy,os,math,json,struct,numpy as np,glob
from mathutils import Matrix,Vector,Quaternion
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8/actions_v4');G=os.path.abspath(B+'/../../../Game/models/miko8');os.makedirs(Q,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];mesh=bpy.data.objects['MIKO8_Mesh'];sc.render.fps=30
rig.animation_data.action=None
for t in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(t)
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
rest={b.name:b.matrix_local.copy() for b in rig.data.bones};names=list(rest)
text=open(B+'/export_native_clips.py').read();exec(text[text.index("mapping={'DEF-hips'"):text.index("keep={'Idle_Loop'")])
labels={
'climb-down-loop':'ClimbDown','climb-enter':'ClimbEnter','climb-exit':'ClimbExit','climb-idle-loop':'ClimbIdle','climb-ledge':'ClimbLedge','climb-ledge-rm':'ClimbLedgeRM','climb-up-1m-rm':'Climb1mRM','climb-up-2m-rm':'Climb2mRM','climb-up-loop':'ClimbUp','get-off-wall-2m-rm':'ClimbOff2mRM',
'spell-double-enter':'SpellDoubleEnter','spell-double-exit':'SpellDoubleExit','spell-double-idle-loop':'SpellDoubleIdle','spell-double-shoot-loop':'SpellDoubleShoot','spell-simple-idle-loop':'SpellSingleIdle','spell-simple-enter':'SpellSingleEnter','spell-simple-exit':'SpellSingleExit','spell-simple-shoot':'SpellSingleShoot'}
meta=json.load(open(B+'/MIKO8_Native.json'));validation={};C=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
conversion=text[text.index(" raw=open(path,'rb').read()"):text.index('# Inspect native contact trajectories')]
old_label="label=('SprintEnter' if 'enter' in path else 'SprintExit' if 'exit' in path else 'Sprint' if 'sprint' in path else ('Turn180' if '180' in path else 'Turn90')+('Left' if '-l' in os.path.basename(path) else 'Right'))"
conversion=conversion.replace(old_label,"label=labels[key]")
conversion=conversion.replace("'loop':label=='Sprint'","'loop':'loop' in key")
for path in sorted(glob.glob(B+'/Templates/**/*.glb',recursive=True)):
 key=os.path.basename(path).removeprefix('quaternius-ual1-').removeprefix('quaternius-ual2-').removesuffix('.glb')
 if key not in labels:continue
 if bpy.data.actions.get('MIKO8_'+labels[key]):bpy.data.actions.remove(bpy.data.actions['MIKO8_'+labels[key]])
 exec('\n'.join(line[1:] if line.startswith(' ') else line for line in conversion.splitlines()))
# Include contact and emitter trajectories for inspection; no root transform is discarded.
for key,label in labels.items():
 data=meta['clips'][label];a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0];data['hands']=[];data['feet']=[]
 for f in range(round(data['duration']*30)+1):
  sc.frame_set(f);bpy.context.view_layer.update()
  for part,field in [('hand','hands'),('foot','feet')]:
   data[field].append({s:[rig.pose.bones[f'DEF-{part}.{s}'].matrix.translation.x,rig.pose.bones[f'DEF-{part}.{s}'].matrix.translation.z,-rig.pose.bones[f'DEF-{part}.{s}'].matrix.translation.y] for s in ['L','R']})
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
sc.frame_set(0)
for a in bpy.data.actions:
 if not a.name.startswith('MIKO8_'):continue
 a.use_fake_user=True;t=rig.animation_data.nla_tracks.new();t.name=a.name;s=t.strips.new(a.name,0,a);s.action_slot=a.slots[0]
for o in sc.objects:o.select_set(o in [rig,mesh])
bpy.context.view_layer.objects.active=rig
json.dump(meta,open(B+'/MIKO8_Actions.json','w'),indent=2);json.dump(meta,open(G+'/MIKO8_Native.json','w'),indent=2);json.dump(validation,open(Q+'/source_conversion.json','w'),indent=2)
bpy.ops.export_scene.gltf(filepath=G+'/MIKO8_Native.glb',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_morph=False)
for t in rig.animation_data.nla_tracks:t.mute=True
rig.animation_data.action=bpy.data.actions['MIKO8_Idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];sc.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_Actions_Animated.blend')
print('ACTIONS_EXPORTED',len(meta['clips']),flush=True)
