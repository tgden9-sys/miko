import bpy,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[3];O=R/'Builds/Validation/LadderTransitions'
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).parent/'MIKO8_GameLOD.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig']
for track in rig.animation_data.nla_tracks:track.mute=True
sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=480;sc.render.resolution_y=560;sc.render.resolution_percentage=100
sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL'
sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=True
sc.world.color=(.16,.16,.16);sc.render.image_settings.file_format='PNG'
bpy.ops.object.camera_add(location=(3,-7,2.3));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.2;sc.camera=cam
for label in ['ClimbLedgeRM','ClimbExit']:
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0]
 for index in range(5):
  sc.frame_set(round(a.frame_range[1]*index/4));bpy.context.view_layer.update()
  hips=rig.pose.bones['DEF-hips'].matrix.translation
  target=Vector((hips.x,hips.y,hips.z+.05));cam.location=target+Vector((2.8,-7,1.0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
  sc.render.filepath=str(O/f'original_{label}_{index}.png');bpy.ops.render.render(write_still=True)
print('EXISTING_TOP_CLIPS_REVIEWED')
