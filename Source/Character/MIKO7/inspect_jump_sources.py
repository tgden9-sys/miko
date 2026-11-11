import bpy,os,json
BASE=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v1.blend'))
rig=bpy.data.objects['SOURCE_Quaternius'];rig.hide_set(False)
report={}
for clip in ['Idle_Loop','Walk_Loop','Sprint_Loop','Jump_Start','Jump_Loop','Jump_Land']:
    a=bpy.data.actions[clip];rig.animation_data.action=a
    if a.slots:rig.animation_data.action_slot=a.slots[0]
    data=[]
    for f in range(0,int(round(a.frame_range[1]))+1):
        bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
        feet=min(min(rig.pose.bones['DEF-toe.'+s].head.z,rig.pose.bones['DEF-toe.'+s].tail.z) for s in ['L','R'])
        data.append({'f':f,'root':rig.pose.bones['root'].head.z,'hips':rig.pose.bones['DEF-hips'].head.z,'toe_min':feet})
    report[clip]=data
with open(os.path.join(BASE,'jump_source_analysis.json'),'w') as f:json.dump(report,f,indent=2)
for clip,data in report.items():print(clip,[(x['f'],round(x['hips'],3),round(x['toe_min'],3)) for x in data[::5]],flush=True)
