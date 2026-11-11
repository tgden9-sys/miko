import bpy,os,json
p=os.path.dirname(__file__);bpy.ops.wm.read_factory_settings(use_empty=True)
for filename in ['SkeletonSettings.fbx','A_Ladder_Up_Loop.fbx']:
 bpy.ops.import_scene.fbx(filepath=p+'/'+filename)
 r=bpy.context.selected_objects[0]
 r=next(o for o in bpy.context.selected_objects if o.type=='ARMATURE');print(filename,r.name)
 for n in ['pelvis','head','upperarm_l','lowerarm_l','hand_l','thigh_l','calf_l','foot_l']:
  print(n,[round(v,2) for v in r.data.bones[n].head_local])
 if r.animation_data and r.animation_data.action:
  a=r.animation_data.action;print('action',a.name,list(a.frame_range))
  for f in [1,17.25,33.5]:
   bpy.context.scene.frame_set(int(f),subframe=f%1);print('pose',f,[(n,[round(v,3) for v in (r.matrix_world@r.pose.bones[n].matrix).translation]) for n in ['pelvis','foot_l','foot_r','hand_l','hand_r']])
