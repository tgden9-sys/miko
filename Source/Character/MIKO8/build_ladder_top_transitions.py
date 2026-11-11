"""Author/bake a contact-fitted ladder climb-out and return on MIKO's real rig.

Coordinates in the motion/contact curves are Godot metres relative to ladder top.
Bone animation is baked FK at 30fps after offline two-bone contact solving.
The accepted character mesh and existing animation assets are never re-exported.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion
R=Path(__file__).resolve().parents[3];B=Path(__file__).parent
O=R/'Builds/Validation/LadderTransitions';O.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(B/'MIKO8_GameLOD.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];sc.render.fps=30
for t in rig.animation_data.nla_tracks:t.mute=True
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
names=[b.name for b in rig.data.bones]
children={n:[b.name for b in rig.data.bones if b.name==n or any(p.name==n for p in b.parent_recursive)] for n in names}
D=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
stock=json.loads((R/'Game/models/miko8/VanillaLoop_Ladder_Trial.json').read_text())['frames'][0]
def from_json(frame):
 worlds={}
 for b in rig.data.bones:
  value=frame[b.name];q=value['q'];local=Matrix.LocRotScale(Vector(value['p']),Quaternion((q[3],q[0],q[1],q[2])),Vector((1,1,1)))
  worlds[b.name]=worlds[b.parent.name]@local if b.parent else D.inverted().to_4x4()@local
 return worlds
climb=from_json(stock)
a=bpy.data.actions['MIKO8_Idle'];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0];sc.frame_set(0);bpy.context.view_layer.update()
idle={p.name:p.matrix.copy() for p in rig.pose.bones};rig.animation_data.action=None
local_climb={b.name:(climb[b.parent.name].inverted()@climb[b.name] if b.parent else climb[b.name]) for b in rig.data.bones}
local_idle={b.name:(idle[b.parent.name].inverted()@idle[b.name] if b.parent else idle[b.name]) for b in rig.data.bones}
def smooth(a,b,t):
 t=max(0,min(1,(t-a)/(b-a)));return t*t*(3-2*t)
def curve(keys,t):
 if t<=keys[0][0]:return Vector(keys[0][1])
 for (a,p),(b,q) in zip(keys,keys[1:]):
  if t<=b:return Vector(p).lerp(Vector(q),smooth(a,b,t))
 return Vector(keys[-1][1])
def path(t):
 p=curve([(0,(0,-.95,0)),(.16,(0,-.84,-.015)),(.34,(0,-.65,-.10)),(.50,(0,-.28,-.30)),(.70,(0,.01,-.53)),(.84,(.22,.01,-.43)),(.96,(.64,.01,-.10)),(1,(.76,.01,0))],t)
 yaw=math.pi-(math.pi*.5)*smooth(.71,1,t)
 return p,yaw
def gvec(p):return Vector((p[0],-p[2],p[1]))
def local_target(p,root,yaw):return Matrix.Rotation(-yaw,3,'Z')@(gvec(p)-gvec(root))
end_root,end_yaw=path(1)
def world_end(bone):return D@(Matrix.Rotation(end_yaw,3,'Z')@idle[bone].translation)+end_root
end_feet={s:world_end('DEF-foot.'+s) for s in ['L','R']}
def rotate_chain(worlds,name,rotation):
 pivot=worlds[name].translation
 delta=Matrix.Translation(pivot)@rotation.to_matrix().to_4x4()@Matrix.Translation(-pivot)
 for n in children[name]:worlds[n]=delta@worlds[n]
def orient_chain(worlds,name,basis):
 old=worlds[name].copy();new=basis.to_4x4();new.translation=old.translation
 delta=new@old.inverted()
 for n in children[name]:worlds[n]=delta@worlds[n]
def solve(worlds,upper,lower,end,target,pole,orientation=None):
 p=worlds[upper].translation;mid=worlds[lower].translation;e=worlds[end].translation
 a=(mid-p).length;b=(e-mid).length;axis=(target-p).normalized()
 length=max(abs(a-b)+.002,min((target-p).length,a+b-.002))
 along=(a*a-b*b+length*length)/(2*length);height=math.sqrt(max(0,a*a-along*along))
 direction=(pole-axis*pole.dot(axis)).normalized();joint=p+axis*along+direction*height
 rotate_chain(worlds,upper,(mid-p).rotation_difference(joint-p))
 m=worlds[lower].translation;e=worlds[end].translation
 rotate_chain(worlds,lower,(e-m).rotation_difference(target-m))
 if orientation:orient_chain(worlds,end,orientation)
 return (worlds[end].translation-target).length
def authored(t):
 root,yaw=path(t);blend=smooth(.16,.76,t)
 worlds={}
 for b in rig.data.bones:
  local_blend=blend
  for side in ['L','R']:
   if b.name!='DEF-hand.'+side and b.name in children['DEF-hand.'+side]:
    local_blend=smooth(.69,.84,t) if side=='L' else smooth(.73,.86,t)
  local=local_climb[b.name].lerp(local_idle[b.name],local_blend)
  worlds[b.name]=worlds[b.parent.name]@local if b.parent else local
 # Low hips over the planted foot, then extend through the support leg.
 crouch=.13*smooth(.12,.36,t)*(1-smooth(.83,1.,t))
 shift=Vector((0,-.06*smooth(.18,.45,t)*(1-smooth(.67,.85,t)),-crouch))
 for n in children['DEF-hips']:worlds[n].translation+=shift
 rotate_chain(worlds,'DEF-spine.001',Quaternion(Vector((1,0,0)),math.radians(12)*smooth(.12,.40,t)*(1-smooth(.65,.88,t))))
 targets={};errors={};contact={}
 # Grips travel up the rails only while the opposite hand supports weight.
 for side,sign in [('L',-1),('R',1)]:
  release=(.69,.78) if side=='L' else (.73,.82)
  hand=curve([(0,(sign*.255,.65 if side=='L' else .40,-.33)),(.15,(sign*.255,.65 if side=='L' else .83,-.33)),(.34,(sign*.255,.95 if side=='L' else .83,-.36)),(.46,(sign*.255,.95,-.36)),(.58,(sign*.255,.95,-.55)),(.80,(sign*.255,.95,-.55))],t)
  influence=smooth(0,.10,t)*(1-smooth(*release,t))
  target=local_target(hand,root,yaw)
  target=worlds['DEF-hand.'+side].translation.lerp(target,influence)
  base=Matrix.Rotation(math.pi-yaw,3,'Z')@climb['DEF-hand.'+side].to_3x3()
  orientation=worlds['DEF-hand.'+side].to_3x3().lerp(base,influence)
  pole=Matrix.Rotation(-yaw,3,'Z')@Vector((sign*.4,-.2,-1))
  errors['hand_'+side]=solve(worlds,'DEF-upper_arm.'+side,'DEF-forearm.'+side,'DEF-hand.'+side,target,pole,orientation)
  contact['hand_'+side]=influence>.99
  targets['hand_'+side]=hand
 # Each foot stays at one rung/landing until its next explicit swing.
 feet={
 'L':curve([(0,(-.105,-.4662,-.21)),(.26,(-.105,-.4662,-.21)),(.38,(-.115,.20,-.43)),(.50,(-.115,.105,-.69)),(.84,(-.115,.105,-.69)),(.93,(end_feet['L'].x,.28,end_feet['L'].z)),(1,tuple(end_feet['L']))],t),
 'R':curve([(0,(.105,-.7052,-.21)),(.14,(.105,-.7052,-.21)),(.24,(.105,-.16,-.18)),(.34,(.105,-.2272,-.21)),(.50,(.105,-.2272,-.21)),(.60,(.115,.24,-.52)),(.70,(.115,.105,-.59)),(.73,(.115,.105,-.59)),(.80,(end_feet['R'].x,.25,end_feet['R'].z)),(.88,tuple(end_feet['R'])),(1,tuple(end_feet['R']))],t)}
 for side in ['L','R']:
  influence=smooth(0,.10,t)*(1-smooth(.96,1,t))
  target=worlds['DEF-foot.'+side].translation.lerp(local_target(feet[side],root,yaw),influence)
  turn=smooth(.84,1,t) if side=='L' else smooth(.73,.88,t)
  foot_yaw=math.pi-math.pi*.5*turn
  basis=Matrix.Rotation(foot_yaw-yaw,3,'Z')@rest['DEF-foot.'+side].to_3x3()
  basis=worlds['DEF-foot.'+side].to_3x3().lerp(basis,influence)
  pole=Vector((-.08 if side=='L' else .08,-1,.1))
  errors['foot_'+side]=solve(worlds,'DEF-thigh.'+side,'DEF-shin.'+side,'DEF-foot.'+side,target,pole,basis)
  targets['foot_'+side]=feet[side]
  contact['foot_'+side]=(.50<=t<=.84) if side=='L' else (.34<=t<=.50 or .88<=t<.96)
 return worlds,root,yaw,targets,errors,contact
def install(worlds):
 for b in rig.data.bones:
  parent=b.parent.name if b.parent else None
  rig.pose.bones[b.name].matrix_basis=(b.matrix_local.inverted()@rest[parent]@worlds[parent].inverted()@worlds[b.name] if parent else b.matrix_local.inverted()@worlds[b.name])
 bpy.context.view_layer.update()
result={'fps':30,'standard':{'height':3.2,'transition_below':.95,'exit_offset_x':.76,'exit_z':0,'landing_back_z':-.45,'main_deck_left_offset':.4},'clips':{}}
report={}
for label,duration in [('LadderTopOut',1.5),('LadderTopIn',1.6)]:
 action=bpy.data.actions.new('MIKO8_'+label);action.use_fake_user=True;rig.animation_data.action=action
 frames=[];motion=[];contacts=[];max_error=0
 count=round(duration*30)
 for frame in range(count+1):
  sc.frame_set(frame)
  u=frame/count
  # A separately baked return clip: reverse the contact sequence, with more
  # time reserved for the initial turn/reach and a quicker final lowering.
  phase=u if label=='LadderTopOut' else 1-curve([(0,(0,0,0)),(.4,(.33,0,0)),(1,(1,0,0))],u).x
  worlds,root,yaw,targets,errors,contact=authored(phase);install(worlds)
  max_error=max(max_error,max(errors.values()))
  values={}
  for b in rig.data.bones:
   pose=rig.pose.bones[b.name]
   local=worlds[b.parent.name].inverted()@worlds[b.name] if b.parent else worlds[b.name]
   q=(D@local.to_3x3()).to_quaternion() if not b.parent else local.to_quaternion()
   p=D@local.translation if not b.parent else local.translation
   values[b.name]={'p':list(p),'q':[q.x,q.y,q.z,q.w]}
   for prop in ['location','rotation_quaternion','scale']:
    if prop=='rotation_quaternion':pose.rotation_mode='QUATERNION'
    pose.keyframe_insert(data_path=prop,frame=frame,group=b.name)
  rig.location=gvec(root)+Vector((0,0,3.2));rig.rotation_mode='XYZ';rig.rotation_euler=(0,0,yaw)
  rig.keyframe_insert(data_path='location',frame=frame);rig.keyframe_insert(data_path='rotation_euler',frame=frame)
  frames.append(values);motion.append([*root,yaw]);contacts.append({'targets':{k:list(v) for k,v in targets.items()},'active':contact,'solver_error':errors})
 for layer in action.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for fc in bag.fcurves:
     for key in fc.keyframe_points:key.interpolation='LINEAR'
 result['clips'][label]={'duration':duration,'loop':False,'source':'Authored MIKO standard ladder top / offline contact-fitted FK bake','frames':frames,'motion':motion,'contacts':contacts}
 report[label]={'samples':count+1,'duration':duration,'maximum_IK_error_m':max_error}
 print('LADDER_TOP_BAKED',label,report[label],flush=True)
rig.animation_data.action=bpy.data.actions['MIKO8_LadderTopOut'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];sc.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(B/'MIKO8_LadderTop_Animated.blend'))
(R/'Game/models/miko8/MIKO8_LadderTop.json').write_text(json.dumps(result,separators=(',',':')))
(O/'authoring.json').write_text(json.dumps(report,indent=2))
print('STANDARD_LADDER_TOP_READY',report,flush=True)
