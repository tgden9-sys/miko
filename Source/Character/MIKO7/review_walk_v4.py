import bpy,os,math,json
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v4'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v4.blend'))
r=bpy.data.objects['MIKO7_RIG'];r.animation_data.action=bpy.data.actions['MIKO7_Walk'];sc=bpy.context.scene
sc.render.resolution_x=480;sc.render.resolution_y=480;sc.cycles.samples=6;cam=sc.camera;cam.data.ortho_scale=1.2
for view,pos in [('side',(3,0,.75)),('quarter',(1.8,-3.5,1.15))]:
 cam.location=pos;target=Vector((0,0,.48));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
 for i,f in enumerate([0,4,8,12,16,20,24,28,30]):
  sc.frame_set(f);bpy.context.view_layer.update();sc.render.filepath=os.path.join(QA,f'walk_{view}_{i:02d}.png');bpy.ops.render.render(write_still=True)
