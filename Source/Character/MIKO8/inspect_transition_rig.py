import bpy,json
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[3]
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).parent/'MIKO8_GameLOD.blend'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
print('RIG',rig.name,'matrix',list(rig.matrix_world),'bones',len(rig.data.bones))
print('MESHES',[(o.name,len(o.data.polygons)) for o in bpy.context.scene.objects if o.type=='MESH'])
print('ACTIONS',[(a.name,list(a.frame_range)) for a in bpy.data.actions if any(s in a.name for s in ['Idle','ClimbLedge','ClimbExit','Walk'])])
for n in ['root','DEF-hips','DEF-spine.001','DEF-spine.002','DEF-spine.003','DEF-head','DEF-upper_arm.L','DEF-forearm.L','DEF-hand.L','DEF-thigh.L','DEF-shin.L','DEF-foot.L','DEF-toe.L']:
 b=rig.data.bones[n];print('BONE',n,'parent',b.parent.name if b.parent else None,'head',list(b.head_local),'tail',list(b.tail_local))
rig.animation_data.action=None
for t in rig.animation_data.nla_tracks:t.mute=True
D=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
data=json.loads((root/'Game/models/miko8/VanillaLoop_Ladder_Trial.json').read_text())
world={}
for b in rig.data.bones:
 v=data['frames'][0][b.name];q=v['q'];m=Matrix.LocRotScale(Vector(v['p']),Quaternion((q[3],q[0],q[1],q[2])),Vector((1,1,1)))
 world[b.name]=world[b.parent.name]@m if b.parent else D.inverted().to_4x4()@m
 basis=b.matrix_local.inverted()@b.parent.matrix_local@m if b.parent else b.matrix_local.inverted()@world[b.name]
 rig.pose.bones[b.name].matrix_basis=basis
bpy.context.view_layer.update()
for name in ['DEF-hips','DEF-spine.003','DEF-hand.L','DEF-hand.R','DEF-foot.L','DEF-foot.R','DEF-toe.L','DEF-toe.R']:
 print('STOCK_POINT',name,list(D@rig.pose.bones[name].matrix.translation))
