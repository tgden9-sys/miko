import bpy,os,json,struct,math
from mathutils import Matrix
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8')
mapping={'Idle_Loop':'Idle','Walk_Loop':'Walk','Jog_Fwd_Loop':'Run','Jump_Start':'JumpStart','Jump_Loop':'JumpAir','Jump_Land':'JumpLand'}
bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene;sc.render.fps=30
path=os.path.abspath(B+'/../MIKO7/Quaternius/Animation Library[Standard]/Godot/AnimationLibrary_Godot_Standard.glb');bpy.ops.import_scene.gltf(filepath=path)
rig=next(o for o in sc.objects if o.type=='ARMATURE');rig.animation_data_clear();rig.animation_data_create();expected={};durations={}
for src,label in mapping.items():
 a=bpy.data.actions[src];rig.animation_data.action=a
 if a.slots:rig.animation_data.action_slot=a.slots[0]
 duration=float(a.frame_range[1])/30;durations[label]=duration;expected[label]={}
 for i in range(round(duration*60)+1):
  frame=min(i*.5,duration*30);sc.frame_set(int(frame),subframe=frame%1);bpy.context.view_layer.update();expected[label][frame]={p.name:p.matrix.copy() for p in rig.pose.bones}
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig']
for t in rig.animation_data.nla_tracks:t.mute=True
result={}
for label,frames in expected.items():
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a
 if a.slots:rig.animation_data.action_slot=a.slots[0]
 assert abs(float(a.frame_range[1])/30-durations[label])<1e-5
 error=0
 for frame,desired in frames.items():
  sc.frame_set(int(frame),subframe=frame%1);bpy.context.view_layer.update()
  for n,m in desired.items():error=max(error,max(abs(rig.pose.bones[n].matrix[r][c]-m[r][c]) for r in range(4) for c in range(4)))
 result[label]={'source_world_matrix_error_at_60hz':error,'duration_seconds':durations[label],'samples':len(frames)};assert error<.00002,(label,error)
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
json.dump(result,open(Q+'/standard_source_validation.json','w'),indent=2);print('STANDARD_NATIVE_IDENTITY_PASSED',result,flush=True)
