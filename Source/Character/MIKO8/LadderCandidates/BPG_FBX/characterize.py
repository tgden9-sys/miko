import bpy,json
from pathlib import Path
p=Path(__file__).resolve().parent
out={}
for f in sorted((p/'Source').glob('*.fbx')):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(f))
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');a=rig.animation_data.action;s,e=a.frame_range
 data={'matrix':list(map(list,rig.matrix_world)), 'rest':{n:list(rig.data.bones[n].matrix_local.translation) for n in ['root','pelvis','hand_l','hand_r','foot_l','foot_r']},'samples':[]}
 for t in [0,.25,.5,.75,1]:
  at=s+(e-s)*t;bpy.context.scene.frame_set(int(at),subframe=at%1)
  data['samples'].append({n:list(rig.matrix_world@rig.pose.bones[n].matrix.translation) for n in ['root','pelvis','hand_l','hand_r','foot_l','foot_r']})
 out[f.stem]=data
(p/'source_motion.json').write_text(json.dumps(out,indent=2))
print('SOURCE_CHARACTERIZED',len(out))
