import bpy,os,numpy as np,json
B=os.path.abspath('Source/Character/MIKO8');bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Native_Animated.blend');sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig'];mesh=bpy.data.objects['MIKO8_Mesh']
for t in rig.animation_data.nla_tracks:t.mute=True
ids={g.index:g.name for g in mesh.vertex_groups};foot=[]
for v in mesh.data.vertices:
 if sum(g.weight for g in v.groups if ids.get(g.group,'') in ['DEF-foot.L','DEF-foot.R','DEF-toe.L','DEF-toe.R'])>.55:foot.append(v.index)
foot=np.array(foot);results={}
for label in ['Idle','Walk','Run','Sprint']:
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0];duration=a.frame_range[1];values=[]
 for i in range(9):
  f=float(duration)*i/8;sc.frame_set(int(f),subframe=f%1);bpy.context.view_layer.update();ev=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());m=ev.to_mesh();coords=np.empty(len(m.vertices)*3,dtype=np.float32);m.vertices.foreach_get('co',coords);coords=coords.reshape(-1,3);values.append(round(float(coords[foot,2].min()),4));ev.to_mesh_clear()
 results[label]=values
print('SOLE_HEIGHTS_METRES',results,flush=True);json.dump(results,open('Builds/Validation/MIKO8/ladder_candidates/sole_heights.json','w'))
