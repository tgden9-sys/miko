"""Resumable Cycles exporter; run full/body/arms jobs in independent processes."""
import bpy,json,os,time,sys
from pathlib import Path
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT=Path(__file__).resolve().parent;OUT=ROOT.parents[1]/'Game'
group=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'full'
record=json.loads((ROOT/'neckerchief_render_jobs_v28.json').read_text())
base_group='arms' if group in ('armsA','armsB') else group
jobs=[j for j in record['jobs'] if j['group']==base_group]
if group in ('armsA','armsB'):
 jobs=[j for i,j in enumerate(jobs) if i%2==(0 if group=='armsA' else 1)]
s=bpy.context.scene;s.camera=bpy.data.objects['Sprite test camera'];s.camera.data.ortho_scale=1.38
s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=True
s.render.resolution_x=s.render.resolution_y=384;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA';s.render.film_transparent=True
s.render.use_persistent_data=True;s.render.threads_mode='FIXED'
s.render.threads=(os.cpu_count() or 8) if base_group=='full' else max(2,min(4,(os.cpu_count() or 8)//3))
meshes=[o for o in s.objects if o.type=='MESH' and not o.hide_render]
arms={side:{o for o in meshes if o.name.startswith(side+' ') and '| editable segment' in o.name} for side in ('L','R')}
body=set(meshes)-arms['L']-arms['R']
views={'full':set(meshes),'body':body,**arms}
for side in ('L','R'):
 for label,name in (('upper','UPPER ARM'),('forearm','FOREARM'),('hand','HAND')):
  views[label+'_'+side]={bpy.data.objects[f'{side} {name} | editable segment']}

if group=='body':
 manifest=json.loads(s['animation_manifest_v27']);data={'base':{},'aim':{},'plasma':{}}
 def point(side,joint):
  o=bpy.data.objects[f'CTRL | {side} {joint}']
  v=world_to_camera_view(s,s.camera,o.evaluated_get(bpy.context.evaluated_depsgraph_get()).matrix_world.translation)
  return [round((v.x-.5)*384*.364,3),round((.5-v.y)*384*.364,3)]
 def lm(side):return {j:point(side,j) for j in ('shoulder','elbow','wrist')}
 for clip in ('idle','move','jump','dash','idle_left','move_left','jump_left','dash_left','turn_to_left','turn_to_right'):
  data['base'][clip]=[]
  for f in manifest[clip]['frames']:
   s.frame_set(f);bpy.context.view_layer.update();data['base'][clip].append({side:lm(side) for side in ('L','R')})
 for side,clip,source in [('L','aim_L','aim_left_arm'),('R','aim_R','aim_right_arm'),('L','aim_L_left','aim_left_arm_left'),('R','aim_R_left','aim_right_arm_left')]:
  data['aim'][clip]=[]
  for f in manifest[source]['frames']:
   s.frame_set(f);bpy.context.view_layer.update();data['aim'][clip].append(lm(side))
 for clip in ('plasma','plasma_left'):
  data['plasma'][clip]=[]
  for f in manifest[clip]['frames']:
   s.frame_set(f);bpy.context.view_layer.update();data['plasma'][clip].append({side:lm(side) for side in ('L','R')})
 data['base']['blue_turn']=[]
 for f in manifest['aim_right_arm_left']['frames']:
  s.frame_set(f);bpy.context.view_layer.update();data['base']['blue_turn'].append({side:lm(side) for side in ('L','R')})
 (OUT/'layers/layer_points.json').write_text(json.dumps(data,indent=2),encoding='utf-8')

progress_path=ROOT/f'neckerchief_render_progress_{group}_v28.json'
done=set()
if progress_path.exists():
 old=json.loads(progress_path.read_text())
 if old.get('source_sha256')==record['source_sha256']:done=set(old.get('paths',[]))
elif group in ('armsA','armsB'):
 previous=ROOT/'neckerchief_render_progress_arms_v28.json'
 if previous.exists():
  old=json.loads(previous.read_text())
  if old.get('source_sha256')==record['source_sha256']:
   wanted={j['path'] for j in jobs};done=set(old.get('paths',[]))&wanted
started=time.time()
def progress(status):
 progress_path.write_text(json.dumps({'group':group,'source_sha256':record['source_sha256'],'done':len(done),'total':len(jobs),'status':status,'elapsed_seconds':round(time.time()-started,1),'paths':sorted(done)},indent=2),encoding='utf-8')
progress('rendering')
for j in jobs:
 if j['path'] in done:continue
 s.frame_set(j['frame'])
 visible=views[j['view']]
 for o in meshes:o.visible_camera=o in visible
 # Preserve the full transparent canvas but trace only the visible geometry's
 # projected bounds. Twelve pixels of padding retain the antialiasing/glow.
 s.render.use_border=True
 s.render.use_crop_to_border=False
 if s.render.use_border:
  graph=bpy.context.evaluated_depsgraph_get()
  points=[]
  for o in visible:
   evaluated=o.evaluated_get(graph)
   points.extend(world_to_camera_view(s,s.camera,evaluated.matrix_world@Vector(c)) for c in evaluated.bound_box)
  pad=12.0/384
  s.render.border_min_x=max(0,min(p.x for p in points)-pad)
  s.render.border_max_x=min(1,max(p.x for p in points)+pad)
  s.render.border_min_y=max(0,min(p.y for p in points)-pad)
  s.render.border_max_y=min(1,max(p.y for p in points)+pad)
 target=OUT/j['path'];target.parent.mkdir(parents=True,exist_ok=True)
 s.render.filepath=str(target)
 bpy.ops.render.render(write_still=True)
 done.add(j['path'])
 if len(done)%5==0:
  progress('rendering');print('EXPORT_PROGRESS',group,len(done),'/',len(jobs),'seconds',round(time.time()-started,1),flush=True)
progress('complete')
print('EXPORT_COMPLETE',group,len(done),'seconds',round(time.time()-started,1),flush=True)
