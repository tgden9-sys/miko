import bpy,os
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v6'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v6.blend'))
r=bpy.data.objects['MIKO7_RIG'];r.animation_data.action=bpy.data.actions['MIKO7_Sprint'];sc=bpy.context.scene;cam=sc.camera
sc.render.resolution_x=480;sc.render.resolution_y=480;sc.cycles.samples=6;cam.data.ortho_scale=1.25
for view,pos in [('side',(3,0,.8)),('quarter',(1.8,-3.5,1.15))]:
 cam.location=pos;target=Vector((0,0,.48));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
 for f in range(19):
  sc.frame_set(f);bpy.context.view_layer.update();sc.render.filepath=os.path.join(QA,f'sprint_{view}_{f:02d}.png');bpy.ops.render.render(write_still=True)
