"""Bake reusable existing poses and ladder motion into the replacement master."""
import bpy,math,json,copy
from pathlib import Path
from math import radians

ROOT=Path(__file__).resolve().parent
s=bpy.context.scene
names=['CTRL | ROBOT ROOT','CTRL | hover body','HEAD | helmet, visor and antenna']+[f'CTRL | {side} {j}' for side in ('L','R') for j in ('shoulder','elbow','wrist')]
objects={n:bpy.data.objects[n] for n in names}
keys={o.name:o.data.shape_keys for o in s.objects if o.type=='MESH' and not o.hide_render and o.data.shape_keys}
animated=list(objects.values())+list(keys.values())
actions={o:(o.animation_data.action,o.animation_data.action_slot) if o.animation_data else (None,None) for o in animated}

def restore():
 for o,(action,slot) in actions.items():
  if action:
   o.animation_data_create();o.animation_data.action=action
   if slot:o.animation_data.action_slot=slot

def snap(frame,yaw=None,left_plasma=False):
 restore();s.frame_set(frame)
 if yaw is not None:
  root=objects[names[0]];root.animation_data.action=None;root.rotation_euler.z=radians(yaw)
 if left_plasma:
  shoulder=objects['CTRL | R shoulder'];shoulder.animation_data.action=None
  t=min(1,(frame-221)/12)
  shoulder.rotation_euler=(radians(-79*t),0,radians(-70*t))
 bpy.context.view_layer.update()
 return {'objects':{n:{'location':list(o.location),'rotation_euler':list(o.rotation_euler),'scale':list(o.scale)} for n,o in objects.items()},
         'keys':{n:{k.name:k.value for k in key.key_blocks if k!=key.reference_key} for n,key in keys.items()}}

clips={}
base={'idle':list(range(1,49,2)),'move':list(range(50,74,2)),'jump':list(range(75,98,2)),
 'dash':list(range(98,114,2)),'move_start':list(range(165,175)),
 'move_stop':list(range(175,185)),'land':list(range(185,197))}
for name,frames in base.items():
 clips[name]=[snap(f) for f in frames]
 clips[name+'_left']=[snap(f,-90) for f in frames]
for name,start in (('turn_to_left',115),('turn_to_right',140)):
 clips[name]=[snap(f) for f in range(start,start+25)]
for name,start in (('aim_left_arm',197),('aim_right_arm',209),('aim_left_arm_left',237),('aim_right_arm_left',249)):
 clips[name]=[snap(f) for f in range(start,start+12)]
clips['plasma']=[snap(f,0) for f in range(221,237)]
clips['plasma_left']=[snap(f,-90,True) for f in range(221,237)]
rest=snap(1)

def ladder_pose(kind,i,count):
 p=copy.deepcopy(rest);ob=p['objects'];phase=i/count*math.tau
 ob['CTRL | ROBOT ROOT']['rotation_euler']=[0,0,radians(135)]
 ob['HEAD | helmet, visor and antenna']['rotation_euler']=[0,0,0]
 ob['CTRL | hover body']['location']=[0,0,0]
 ob['CTRL | hover body']['rotation_euler']=[0,0,0]
 for side in ('L','R'):
  ob[f'CTRL | {side} wrist']['location'][2]=-.18
  for j in ('shoulder','elbow','wrist'):ob[f'CTRL | {side} {j}']['scale']=[1,1,1]
  if f'{side} FOREARM | editable segment' in p['keys']:
   p['keys'][f'{side} FOREARM | editable segment']['Laser reach']=0
 if kind=='ladder_climb':
  ob['CTRL | hover body']['location'][2]=math.sin(phase*2)*.015
  ob['CTRL | hover body']['rotation_euler'][1]=math.sin(phase)*.03
 elif kind=='ladder_idle':ob['CTRL | hover body']['location'][2]=math.sin(phase)*.008
 t=1.0
 if kind.startswith('ladder_mount'):
  t=i/(count-1);t=t*t*(3-2*t)
  yaw=(0+135*t) if kind.endswith('right') else (-90-135*t)
  ob['CTRL | ROBOT ROOT']['rotation_euler'][2]=radians(yaw)
 for side,sign in (('R',1),('L',-1)):
  reach=math.sin(phase+(0 if side=='R' else math.pi)) if kind=='ladder_climb' else 0
  target_sh=(-105-reach*25,sign*(-30-reach*10),sign*10) if kind=='ladder_climb' else (-110,sign*-30,sign*10)
  target_el=(-35-reach*10,0,0)
  target_wr=(-20,sign*-10,0)
  # Start each mount at the actual neutral FK pose, then reach overhead.
  for joint,target in (('shoulder',target_sh),('elbow',target_el),('wrist',target_wr)):
   ob[f'CTRL | {side} {joint}']['rotation_euler']=[radians(a*t) for a in target]
 return p
for name,count in (('ladder_mount_right',10),('ladder_mount_left',10),('ladder_idle',8),('ladder_climb',12)):
 clips[name]=[ladder_pose(name,i,count) for i in range(count)]

restore()
manifest={};frame=401
for name,poses in clips.items():
 frames=[]
 s.timeline_markers.new('v27 | '+name,frame=frame)
 for pose in poses:
  for n,values in pose['objects'].items():
   o=objects[n]
   for prop,value in values.items():setattr(o,prop,value);o.keyframe_insert(data_path=prop,frame=frame)
  for n,values in pose['keys'].items():
   for key,value in values.items():
    k=keys[n].key_blocks[key];k.value=value;k.keyframe_insert(data_path='value',frame=frame)
  frames.append(frame);frame+=1
 manifest[name]={'frames':frames,'count':len(frames)}
 frame+=2
# Straight interpolation between baked samples avoids new overshoot at joints.
for o in animated:
 if o.animation_data and o.animation_data.action:
  action=o.animation_data.action;slot=o.animation_data.action_slot
  try:curves=action.layers[0].strips[0].channelbag(slot).fcurves
  except Exception:curves=[]
  for curve in curves:
   for k in curve.keyframe_points:
    if k.co.x>=401:k.interpolation='LINEAR'
s['animation_manifest_v27']=json.dumps(manifest)
s.frame_end=frame;s.frame_set(manifest['idle']['frames'][0])
(ROOT/'animation_manifest_v27.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'robot_neckerchief_v27.blend'))
print('BAKED_CLIPS',len(manifest),'FRAMES',sum(x['count'] for x in manifest.values()),flush=True)
