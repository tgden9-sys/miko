import bpy,os
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v5'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v5.blend'))
r=bpy.data.objects['MIKO7_RIG'];sc=bpy.context.scene;cam=sc.camera
sc.render.resolution_x=480;sc.render.resolution_y=480;sc.cycles.samples=8;cam.data.ortho_scale=1.25
for clip,f in [('Idle',0),('Walk',6),('JumpStart',0),('JumpAir',30),('JumpLand',15),('Turn180Left',25),('Sprint',5)]:
 r.animation_data.action=bpy.data.actions['MIKO7_'+clip];sc.frame_set(f);bpy.context.view_layer.update()
 for view,pos in [('side',(3,0,.8)),('quarter',(1.8,-3.5,1.15))]:
  cam.location=pos;target=Vector((0,0,.48));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
  sc.render.filepath=os.path.join(QA,f'gaze_{clip}_{view}.png');bpy.ops.render.render(write_still=True)
