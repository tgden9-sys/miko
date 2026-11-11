import bpy,os,numpy as np,json
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v1.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG'];cam=scene.camera
scene.cycles.samples=8;scene.render.resolution_x=750;scene.render.resolution_y=750
cam.data.ortho_scale=.24;target=Vector((.235,-.01,.331));cam.location=target+Vector((.7,-1,.2));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
obj=bpy.data.objects['MIKO7_Armour_and_Joints'];me=obj.data
p=np.empty(len(me.vertices)*3,dtype=np.float32);me.vertices.foreach_get('co',p);p=p.reshape(-1,3)
edges=np.empty(len(me.edges)*2,dtype=np.int32);me.edges.foreach_get('vertices',edges);edges=edges.reshape(-1,2);a,b=edges.T
d=np.linalg.norm(p[a]-p[b],axis=1);report={}
for value,name in [(-.7,'open'),(.7,'grip')]:
    rig.pose.bones['CTRL-hand.L']['Grip']=value;rig.update_tag();scene.frame_set(1);bpy.context.view_layer.update()
    scene.render.filepath=os.path.join(QA,'rig_hand_'+name+'.png');bpy.ops.render.render(write_still=True)
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());q=np.empty(len(me.vertices)*3,dtype=np.float32);ev.data.vertices.foreach_get('co',q);q=q.reshape(-1,3)
    ratio=np.linalg.norm(q[a]-q[b],axis=1)/np.maximum(d,.0001)
    report[name]={'grip':value,'maximum_edge_stretch':float(ratio.max()),'edges_above_6x':int((ratio>6).sum())}
    print('GRIP_CHECK',name,report[name],flush=True)
with open(os.path.join(QA,'hand_validation.json'),'w') as f:json.dump(report,f,indent=2)
