import bpy,os,json
from mathutils import Matrix
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v2'))
report={}
for version in ['v1','v2']:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_'+version+'.blend'))
    rig=bpy.data.objects['MIKO7_RIG'];rig.animation_data.action=bpy.data.actions['MIKO7_Sprint_Loop']
    results=[];poses={}
    for f in range(1,22):
        bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
        poses[f]={p.name:p.matrix.copy() for p in rig.pose.bones if p.bone.use_deform}
        maxerror=0.;maxscale=0.
        for p in rig.pose.bones:
            if not p.bone.use_deform:continue
            if p.parent and p.name!='DEF-hips':
                expect=p.parent.matrix@(p.parent.bone.matrix_local.inverted()@p.bone.head_local)
                maxerror=max(maxerror,(p.head-expect).length)
            maxscale=max(maxscale,max(abs(s-1) for s in p.matrix.to_scale()))
        results.append({'frame':f,'attachment_error':maxerror,'scale_error':maxscale})
    report[version]=results
    if version=='v2':
        report['loop_position_error']=max((poses[1][n].translation-poses[21][n].translation).length for n in poses[1])
        report['loop_rotation_error_degrees']=max(poses[1][n].to_quaternion().rotation_difference(poses[21][n].to_quaternion()).angle*57.2957795 for n in poses[1])
        report['frame_jumps']=[max((poses[f+1][n].translation-poses[f][n].translation).length for n in poses[f]) for f in range(1,21)]
with open(os.path.join(QA,'sprint_comparison.json'),'w') as f:json.dump(report,f,indent=2)
print(json.dumps(report),flush=True)
