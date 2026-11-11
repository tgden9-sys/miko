import bpy,os,math
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v5.blend'));r=bpy.data.objects['MIKO7_RIG'];rest=r.data.bones['DEF-head'].matrix_local.to_quaternion()
for clip in ['Idle','Walk','JumpStart','JumpAir','JumpLand','Sprint']:
 a=bpy.data.actions['MIKO7_'+clip];r.animation_data.action=a;out=[]
 for f in [0,int(a.frame_range[1]/2),int(a.frame_range[1])]:
  bpy.context.scene.frame_set(f);bpy.context.view_layer.update();v=(r.pose.bones['DEF-head'].matrix.to_quaternion()@rest.inverted())@Vector((0,-1,0));out.append(round(math.degrees(math.atan2(v.z,math.hypot(v.x,v.y))),1))
 print('GAZE',clip,out,flush=True)
