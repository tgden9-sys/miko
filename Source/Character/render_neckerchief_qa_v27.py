import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent;version='v28' if 'v28' in bpy.data.filepath else 'v27';out=ROOT/('neckerchief_'+version);out.mkdir(exist_ok=True)
s=bpy.context.scene;s.frame_set(1)
for name in ('CTRL | ROBOT ROOT','CTRL | hover body','HEAD | helmet, visor and antenna'):
 o=bpy.data.objects[name]
 if o.animation_data:o.animation_data_clear()
 o.rotation_euler=(0,0,0)
 if name=='CTRL | hover body':o.location=(0,0,0)
for o in s.objects:
 if o.type=='MESH':o.visible_camera=True
cam=bpy.data.objects['Sprite test camera'];s.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=1.12
s.render.resolution_x=s.render.resolution_y=640;s.render.resolution_percentage=100
s.render.film_transparent=True;s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA'
s.cycles.samples=24;s.cycles.use_denoising=True
gray=bpy.data.materials.new('QA neutral clay');gray.diffuse_color=(.43,.43,.43,1);gray.use_nodes=True
gray.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.43,.43,.43,1)
gray.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.7
views=[('front',(0,-3,.03)),('side',(3,-.10,.03)),('rear_three_quarter',(2,2,.03)),('back',(0,3,.03)),('front_three_quarter',(2,-3,.15))]
for look in ('material','clay'):
 s.view_layers[0].material_override=gray if look=='clay' else None
 s.view_settings.exposure=-2.0 if look=='clay' else 0.0
 for name,pos in views:
  cam.location=pos;cam.rotation_euler=(Vector((0,-.08,.03))-cam.location).to_track_quat('-Z','Y').to_euler()
  s.render.filepath=str(out/f'{look}_{name}.png');bpy.ops.render.render(write_still=True)
  print('QA',look,name,flush=True)
