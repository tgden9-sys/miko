import bpy,os,json,math
from mathutils import Matrix,Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v3'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v3.blend'))
rig=bpy.data.objects['MIKO7_RIG'];scene=bpy.context.scene;meta=json.load(open(os.path.join(BASE,'MIKO7_Locomotion_v3.json')))
scene.cycles.samples=6;scene.render.resolution_x=400;scene.render.resolution_y=400;scene.camera.data.ortho_scale=1.45
for clip in meta['clips']:
    a=bpy.data.actions['MIKO7_'+clip];rig.animation_data.action=a;end=int(a.frame_range[1])
    for i in [0,1,2,3,4]:
        f=round(end*i/4);scene.frame_set(f);bpy.context.view_layer.update()
        # Apply the separately extracted turn yaw to show the actual game-facing motion.
        if clip.startswith('Turn'):rig.rotation_euler.z=meta['clips'][clip]['yaw'][f]
        else:rig.rotation_euler.z=0
        scene.render.filepath=os.path.join(QA,f'{clip}_{i}.png');bpy.ops.render.render(write_still=True)
    print('REVIEWED',clip,flush=True)
    rig.rotation_euler.z=0
