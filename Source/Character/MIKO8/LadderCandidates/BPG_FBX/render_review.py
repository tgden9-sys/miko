import bpy,math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;B=P.parents[1];R=B.parents[2];O=R/'Builds/Validation/BPGLadder';O.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(B/'MIKO8_BPG_Ladder.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig']
sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=400;sc.render.resolution_y=500;sc.render.resolution_percentage=100
sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=True
sc.world.color=(.12,.14,.16);sc.render.image_settings.file_format='PNG'
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.2;sc.camera=cam
for label in ['BottomEnter','MoveUpL','MoveDownR','UpExitR','UpEnter']:
 a=bpy.data.actions['MIKO8_Bpg'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0]
 for i in range(5):
  sc.frame_set(round(a.frame_range[1]*i/4));bpy.context.view_layer.update()
  target=rig.matrix_world@Vector((0,0,1.));cam.location=target+Vector((3.7,-6,2.2));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
  sc.render.filepath=str(O/(label+'_'+str(i)+'.png'));bpy.ops.render.render(write_still=True)
print('BPG_REVIEW_RENDERED')
