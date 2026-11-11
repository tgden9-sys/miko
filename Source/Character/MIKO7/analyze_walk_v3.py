import bpy,os,json,numpy as np
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v4'));os.makedirs(QA,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v3.blend'))
r=bpy.data.objects['MIKO7_RIG'];r.animation_data.action=bpy.data.actions['MIKO7_Walk'];sc=bpy.context.scene
out=[]
for f in range(41):
 sc.frame_set(f);bpy.context.view_layer.update()
 out.append({'frame':f,'hips':list(r.pose.bones['DEF-hips'].head),'head':list(r.pose.bones['DEF-head'].head),'root':list(r.pose.bones['root'].head),'feet':{s:list(r.pose.bones['DEF-foot.'+s].head) for s in ['L','R']},'knees':{s:list(r.pose.bones['DEF-shin.'+s].head) for s in ['L','R']}})
with open(os.path.join(QA,'walk_before.json'),'w') as f:json.dump(out,f,indent=2)
for name in ['hips','head','root']:
 p=np.array([x[name] for x in out]);print(name,'min',p.min(0),'max',p.max(0),'range',np.ptp(p,axis=0),flush=True)
for n in ['DEF-thigh.L','DEF-shin.L','DEF-foot.L','DEF-toe.L']:
 b=r.data.bones[n];print(n,'length',b.length,'rest_head',list(b.head_local),'rest_tail',list(b.tail_local),flush=True)
print('feet',[(x['frame'],[round(v,3) for v in x['feet']['L']]) for x in out[::5]],flush=True)
