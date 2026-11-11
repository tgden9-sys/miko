import bpy,os,math,json
from mathutils import Vector,Matrix
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v1.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG'];cam=scene.camera
def aim(p):cam.rotation_euler=(Vector(p)-cam.location).to_track_quat('-Z','Y').to_euler()
scene.cycles.samples=12
checks=[('rest',None,1),('idle','Idle_Loop',20),('walk','Walk_Loop',11),('aim','Pistol_Idle_Loop',15)]
for name,clip,frame in checks:
    rig.animation_data.action=bpy.data.actions.get('MIKO7_'+clip) if clip else None
    if not clip:
        for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    scene.frame_set(frame);bpy.context.view_layer.update()
    scene.render.filepath=os.path.join(QA,'rig_'+name+'.png');bpy.ops.render.render(write_still=True)
    print('RENDERED',name,flush=True)
# hand closeup at rest, open / closed control verification
rig.animation_data.action=None
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
cam.data.ortho_scale=.24;target=Vector((.235,-.01,.331))
cam.location=target+Vector((.7,-1,.2));aim(target)
for value,name in [(0,'neutral'),(-.7,'open'),(.7,'grip')]:
    rig.pose.bones['CTRL-hand.L']['Grip']=value
    rig.update_tag();scene.frame_set(1);bpy.context.view_layer.update()
    scene.render.filepath=os.path.join(QA,'rig_hand_'+name+'.png');bpy.ops.render.render(write_still=True)
    print('HAND',name,flush=True)
