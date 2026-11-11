"""Build exact render jobs from resources and retain runtime animation timings."""
from pathlib import Path
import re,json,hashlib

ROOT=Path(__file__).resolve().parent
NEW=ROOT.parents[1]/'Game';OLD=NEW
if not OLD.exists():OLD=NEW
manifest=json.loads((ROOT/'animation_manifest_v27.json').read_text())
jobs=[]

def pose_for(path):
 p=Path(path);parts=p.parts;index=int(re.search(r'_(\d+)\.png$',p.name).group(1))
 if parts[0]=='sprites':clip=parts[-2]
 elif parts[1]=='body_blue_turn':clip='aim_right_arm_left'
 elif parts[1] in ('body_turn_to_left','body_turn_to_right'):clip=parts[1][5:]
 else:
  clip=parts[-2]
  clip={'aim_L':'aim_left_arm','aim_R':'aim_right_arm','aim_L_left':'aim_left_arm_left','aim_R_left':'aim_right_arm_left','blue_turn':'aim_right_arm_left'}.get(clip,clip)
 return clip,index

def view_for(path):
 parts=Path(path).parts
 if parts[0]=='sprites':return 'full'
 layer=parts[1]
 return 'body' if layer.startswith('body') else layer

def read_resource(path):
 text=path.read_text(encoding='utf-8')
 refs=dict((i,p) for p,i in re.findall(r'\[ext_resource type="Texture2D" path="res://([^"]+)" id="([^"]+)"\]',text))
 pattern=r'\{\s*"frames":\s*\[(.*?)\],\s*"loop":\s*(true|false),\s*"name":\s*&"([^"]+)",\s*"speed":\s*([\d.]+)\s*\}'
 animations=[]
 for content,loop,name,speed in re.findall(pattern,text,re.S):
  frames=[{'path':refs[i],'duration':float(d)} for d,i in re.findall(r'\{"duration":\s*([\d.]+),\s*"texture":\s*ExtResource\("([^"]+)"\)\}',content)]
  animations.append({'name':name,'loop':loop=='true','speed':float(speed),'frames':frames})
 assert animations,path
 return animations

def write_resource(path,animations):
 refs={};lines=[];anims=[]
 for anim in animations:
  frames=[]
  for f in anim['frames']:
   p=f['path']
   if p not in refs:
    refs[p]=str(len(refs)+1)
    lines.append(f'[ext_resource type="Texture2D" path="res://{p}" id="{refs[p]}"]')
   frames.append('{"duration": '+str(f['duration'])+', "texture": ExtResource("'+refs[p]+'")}')
  anims.append('{\n"frames": ['+', '.join(frames)+'],\n"loop": '+str(anim['loop']).lower()+',\n"name": &"'+anim['name']+'",\n"speed": '+str(anim['speed'])+'\n}')
 path.write_text(f'[gd_resource type="SpriteFrames" load_steps={len(refs)+1} format=3]\n\n'+'\n'.join(lines)+'\n\n[resource]\nanimations = [\n'+',\n'.join(anims)+'\n]\n',encoding='utf-8')
 return list(refs)

for resource in ('sprites/robot_frames.tres','layers/layer_frames.tres','layers/aim_parts.tres'):
 animations=read_resource(OLD/resource)
 if resource.startswith('sprites'):
  # These fixed angle caches were superseded by continuous shoulder aiming.
  animations=[a for a in animations if not re.search(r'_(?:up|down)\d+$',a['name'])]
 if resource=='layers/layer_frames.tres':
  for side in ('L','R'):
   if side+'_blue_turn' not in {a['name'] for a in animations}:
    animations.append({'name':side+'_blue_turn','loop':False,'speed':30.,'frames':[
     {'path':f'layers/{side}/blue_turn/blue_turn_{i:03d}.png','duration':1.} for i in range(12)]})
 for path in write_resource(NEW/resource,animations):
  clip,index=pose_for(path);view=view_for(path)
  assert clip in manifest,(path,clip)
  jobs.append({'path':path,'clip':clip,'index':index,'frame':manifest[clip]['frames'][index],'view':view,
               'group':'full' if view=='full' else ('body' if view=='body' else 'arms')})
jobs=list({j['path']:j for j in jobs}.values())
record={'source_sha256':hashlib.sha256((ROOT/'robot_neckerchief_aligned_v28.blend').read_bytes()).hexdigest(),'jobs':jobs}
(ROOT/'neckerchief_render_jobs_v28.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print('RENDER_JOBS',len(jobs),{g:sum(j['group']==g for j in jobs) for g in ('full','body','arms')})
