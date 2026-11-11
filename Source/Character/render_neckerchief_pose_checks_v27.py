import bpy,json
from pathlib import Path
root=Path(__file__).resolve().parent;version='v28' if 'v28' in bpy.data.filepath else 'v27';out=root/('neckerchief_'+version);out.mkdir(exist_ok=True)
s=bpy.context.scene;manifest=json.loads(s['animation_manifest_v27'])
s.camera=bpy.data.objects['Sprite test camera'];s.camera.data.ortho_scale=1.38
s.render.resolution_x=s.render.resolution_y=512;s.render.resolution_percentage=100
s.render.film_transparent=True;s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA'
s.cycles.samples=16;s.cycles.use_denoising=True;s.render.use_persistent_data=True
for o in s.objects:
 if o.type=='MESH':o.visible_camera=True
for clip,index in [('idle',0),('idle_left',0),('aim_left_arm',11),('aim_right_arm',11),('aim_left_arm_left',11),('aim_right_arm_left',11),('plasma',15),('plasma_left',15),('ladder_idle',0),('ladder_climb',3),('ladder_climb',9),('jump',5)]:
 s.frame_set(manifest[clip]['frames'][index]);s.render.filepath=str(out/f'pose_{clip}_{index:02d}.png');bpy.ops.render.render(write_still=True)
 print('POSE_QA',clip,index,flush=True)
