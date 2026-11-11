import bpy,os
from mathutils import Vector
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8')
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig']
for t in rig.animation_data.nla_tracks:t.mute=True
sc.render.resolution_x=640;sc.render.resolution_y=640;sc.cycles.samples=8;sc.camera.data.ortho_scale=2.5
for label,frames in [('Walk',[10]),('Sprint',[5,10]),('Idle',[0]),('Run',[0,7,14,21]),('JumpStart',[0,20,40]),('JumpAir',[0,30]),('JumpLand',[0,20]),('Turn180Left',[0,25,50])]:
 rig.animation_data.action=bpy.data.actions['MIKO8_'+label]
 if rig.animation_data.action.slots:rig.animation_data.action_slot=rig.animation_data.action.slots[0]
 for f in frames:
  sc.frame_set(f);bpy.context.view_layer.update()
  for view,pos in [('side',(5,0,1)),('quarter',(3,-5,1.4))]:
   sc.camera.location=pos;sc.camera.rotation_euler=(Vector((0,0,.95))-sc.camera.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=Q+'/native_'+label+'_'+view+'_'+str(f).zfill(2)+'.png';bpy.ops.render.render(write_still=True)
