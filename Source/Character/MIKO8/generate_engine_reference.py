import bpy,os,json
from mathutils import Matrix
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8')
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];meta=json.load(open(B+'/MIKO8_Native.json'));result={}
for t in rig.animation_data.nla_tracks:t.mute=True
for label,data in meta['clips'].items():
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a
 if a.slots:rig.animation_data.action_slot=a.slots[0]
 samples=[]
 for f in range(round(data['duration']*30)+1):
  sc.frame_set(f);bpy.context.view_layer.update();samples.append({p.name:[p.matrix.translation.x,p.matrix.translation.z,-p.matrix.translation.y] for p in rig.pose.bones})
 result[label]=samples
json.dump(result,open(Q+'/engine_reference.json','w'))
# Leave the editable master in a single, understandable action rather than stacked NLA tracks.
rig.animation_data.action=bpy.data.actions['MIKO8_Idle'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];sc.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_Native_Animated.blend')
print('ENGINE_REFERENCE_WRITTEN',flush=True)
