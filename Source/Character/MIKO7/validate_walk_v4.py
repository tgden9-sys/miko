import bpy,os,json,math
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v4'))
poses={};maxdifference=0.
for version in ['v3','v4']:
 bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_'+version+'.blend'))
 r=bpy.data.objects['MIKO7_RIG']
 for a in [a for a in bpy.data.actions if a.name.startswith('MIKO7_') and a.name!='MIKO7_Walk']:
  r.animation_data.action=a
  for f in sorted(set([0,1,2,int(a.frame_range[1]/2),int(a.frame_range[1])])):
   bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
   for p in r.pose.bones:
    key=(a.name,f,p.name);m=p.matrix.copy()
    if version=='v3':poses[key]=m
    else:maxdifference=max(maxdifference,max(abs(m[i][j]-poses[key][i][j]) for i in range(4) for j in range(4)))
 assert len([a for a in bpy.data.actions if a.name.startswith('MIKO7_')])==10
assert maxdifference<1e-7
r.animation_data.action=bpy.data.actions['MIKO7_Walk'];maxlength=0.;maxattach=0.;history=0.;snapshots={}
for f in list(range(31))+[0,2,1,30,0]:
 bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
 for p in r.pose.bones:
  if not p.bone.use_deform:continue
  maxlength=max(maxlength,abs((p.tail-p.head).length-p.bone.length))
  if p.parent and p.name!='DEF-hips':maxattach=max(maxattach,(p.head-p.parent.matrix@(p.parent.bone.matrix_local.inverted()@p.bone.head_local)).length)
  key=(f,p.name);m=p.matrix.copy()
  if key in snapshots:history=max(history,max(abs(m[i][j]-snapshots[key][i][j]) for i in range(4) for j in range(4)))
  snapshots[key]=m
looperror=max(max(abs(snapshots[(0,p.name)][i][j]-snapshots[(30,p.name)][i][j]) for i in range(4) for j in range(4)) for p in r.pose.bones if p.bone.use_deform)
assert maxlength<1e-5 and maxattach<1e-5 and history<1e-6 and looperror<1e-6
out={'other_nine_animations_maximum_difference':maxdifference,'walk_bone_length_error':maxlength,'walk_attachment_error':maxattach,'walk_history_error':history,'walk_loop_error':looperror}
with open(os.path.join(QA,'walk_bake_validation.json'),'w') as f:json.dump(out,f,indent=2)
print('WALK_V4_CHECK',out,flush=True)
