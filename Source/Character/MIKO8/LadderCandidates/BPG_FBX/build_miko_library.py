"""Retarget the supplied FBX motion. Preserve timing and authored root travel."""
import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
P=Path(__file__).resolve().parent;B=P.parents[1];R=B.parents[2]
bpy.ops.wm.open_mainfile(filepath=str(B/'MIKO8_GameLOD.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=True
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
bpy.ops.import_scene.fbx(filepath=str(P.parent/'VanillaLoop/SkeletonSettings.fbx'))
ref=next(o for o in bpy.context.selected_objects if o.type=='ARMATURE');sc.frame_set(1);bpy.context.view_layer.update()
reference={b.name:b.matrix.copy() for b in ref.pose.bones}
mapping={'DEF-hips':'pelvis','DEF-spine.001':'spine_01','DEF-spine.002':'spine_03','DEF-spine.003':'spine_05','DEF-neck':'neck_01','DEF-head':'head'}
for side,suffix in [('L','l'),('R','r')]:
 for a,b in [('shoulder','clavicle'),('upper_arm','upperarm'),('forearm','lowerarm'),('hand','hand'),('thigh','thigh'),('shin','calf'),('foot','foot'),('toe','ball')]:mapping['DEF-'+a+'.'+side]=b+'_'+suffix
 for a,b in [('f_index','index'),('f_middle','middle'),('f_ring','ring'),('f_pinky','pinky'),('thumb','thumb')]:
  for i in range(1,4):mapping[f'DEF-{a}.{i:02}.{side}']=f'{b}_{i:02}_{suffix}'
scale=rest['DEF-hips'].translation.z/(reference['pelvis'].translation.z*.01)
D=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
data={'source':'BP Games direct FBX ladder set','scale':scale,'clips':{}}
for source in sorted((P/'Source').glob('*.fbx')):
 bpy.ops.import_scene.fbx(filepath=str(source));src=next(o for o in bpy.context.selected_objects if o.type=='ARMATURE')
 src_action=src.animation_data.action;start,end=src_action.frame_range;fps=sc.render.fps/sc.render.fps_base;duration=(end-start)/fps
 label='Bpg'+source.stem.removeprefix('A_Neutral_Ladder_').replace('_','')
 out=bpy.data.actions.new('MIKO8_'+label);out.use_fake_user=True
 rig.animation_data.action=out
 frames=[];motion=[];effectors=[];count=round(duration*30)
 for i in range(count+1):
  at=start+(end-start)*i/count;sc.frame_set(int(at),subframe=at%1);bpy.context.view_layer.update()
  poses={b.name:b.matrix.copy() for b in src.pose.bones};root=poses['root'].translation*.01*scale
  desired={};values={}
  for bone in rig.data.bones:
   n=bone.name;parent=bone.parent.name if bone.parent else None;r=rest[n]
   rot=r.to_quaternion()
   if n in mapping:
    key=mapping[n];rot=poses[key].to_quaternion()@reference[key].to_quaternion().inverted()@r.to_quaternion()
   elif parent:rot=desired[parent].to_quaternion()@rest[parent].to_quaternion().inverted()@r.to_quaternion()
   pos=r.translation.copy() if not parent else desired[parent]@(rest[parent].inverted()@r.translation)
   if n=='DEF-hips':pos+=(poses['pelvis'].translation-poses['root'].translation-reference['pelvis'].translation)*(.01*scale)
   mat=rot.to_matrix().to_4x4();mat.translation=pos;desired[n]=mat
   local=desired[parent].inverted()@mat if parent else mat
   q=(D@local.to_3x3()).to_quaternion() if not parent else local.to_quaternion();p=D@local.translation if not parent else local.translation
   values[n]={'p':list(p),'q':[q.x,q.y,q.z,q.w]}
   rig.pose.bones[n].matrix_basis=(r.inverted()@rest[parent]@local if parent else r.inverted()@mat)
  for bone in rig.pose.bones:
   bone.rotation_mode='QUATERNION'
   for prop in ['location','rotation_quaternion']:bone.keyframe_insert(data_path=prop,frame=i,group=bone.name)
  rig.location=root;rig.keyframe_insert(data_path='location',frame=i)
  # Visual yaw PI maps local forward (+Z in Godot) to the ladder behind MIKO.
  motion.append(list(D@root));frames.append(values)
  effectors.append({n:list(D@(desired['DEF-'+n].translation+root)) for n in ['hand.L','hand.R','foot.L','foot.R']})
 for layer in out.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for fc in bag.fcurves:
     for key in fc.keyframe_points:key.interpolation='LINEAR'
 data['clips'][label]={'duration':duration,'loop':'Loop' in label,'frames':frames,'motion':motion,'effectors':effectors,'source':source.name}
 print('BPG_RETARGETED',label,round(duration,3),'root',motion[0],motion[-1],flush=True)
 rig.animation_data.action=None
 for obj in list(bpy.data.objects):
  if obj not in [rig] and obj.type=='ARMATURE':bpy.data.objects.remove(obj,do_unlink=True)
sc.render.fps=30
rig.animation_data.action=bpy.data.actions['MIKO8_BpgUpExitR'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];sc.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(B/'MIKO8_BPG_Ladder.blend'))
(R/'Game/models/miko8/MIKO8_BPG_Ladder.json').write_text(json.dumps(data,separators=(',',':')))
print('BPG_LIBRARY_READY',len(data['clips']),flush=True)
