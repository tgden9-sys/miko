import bpy,os,json
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v2'))
poses={}
for ver in ['v1','v2']:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_'+ver+'.blend'))
    r=bpy.data.objects['MIKO7_RIG'];r.animation_data.action=bpy.data.actions['MIKO7_Sprint_Loop']
    for f in [1,2,3,4,5,10,15,20]:
        bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
        poses[(ver,f)]={p.name:p.matrix.copy() for p in r.pose.bones if p.bone.use_deform}
        if ver=='v1' and f in [1,2,3]:
            sc=bpy.context.scene;sc.render.resolution_x=480;sc.render.resolution_y=480;sc.cycles.samples=8;sc.camera.data.ortho_scale=1.3
            sc.render.filepath=os.path.join(QA,f'old_sprint_{f:02d}.png');bpy.ops.render.render(write_still=True)
report={}
for f in [1,2,3,4,5,10,15,20]:
    pairs=[(n,poses[('v1',f)][n],poses[('v2',f)][n]) for n in poses[('v1',f)]]
    report[f]={'max_position_difference':max((a.translation-b.translation).length for n,a,b in pairs),'rotation_differences':sorted([(n,a.to_quaternion().rotation_difference(b.to_quaternion()).angle*57.2957795) for n,a,b in pairs],key=lambda x:x[1],reverse=True)[:5]}
with open(os.path.join(QA,'pose_differences.json'),'w') as f:json.dump(report,f,indent=2)
print(json.dumps(report),flush=True)
