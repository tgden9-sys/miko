import bpy,os,json,math
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v2'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Sprint_Check.blend'))
rig=bpy.data.objects['MIKO7_RIG'];scene=bpy.context.scene
samples={}
names=[b.name for b in rig.data.bones if b.use_deform]
for f in range(1,22):
    scene.frame_set(f);bpy.context.view_layer.update()
    samples[f]={n:(rig.matrix_world@rig.pose.bones[n].matrix).copy() for n in names}
before=set(bpy.data.objects);before_actions=set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=os.path.join(BASE,'MIKO7_Sprint_Check.glb'))
newrig=next(o for o in set(bpy.data.objects)-before if o.type=='ARMATURE')
actions=set(bpy.data.actions)-before_actions
assert len(actions)==1
action=next(iter(actions));newrig.animation_data.action=action
if action.slots:newrig.animation_data.action_slot=action.slots[0]
poserror=0.;roterror=0.
start=int(round(action.frame_range[0]))
for i in range(21):
    scene.frame_set(start+i);bpy.context.view_layer.update()
    for n in names:
        a=samples[i+1][n];b=newrig.matrix_world@newrig.pose.bones[n].matrix
        poserror=max(poserror,(a.translation-b.translation).length)
        angle=a.to_quaternion().rotation_difference(b.to_quaternion()).angle
        roterror=max(roterror,min(angle,abs(2*math.pi-angle)))
report={'imported_animation_count':len(actions),'compared_frames':21,'maximum_world_position_error':poserror,'maximum_rotation_error_degrees':math.degrees(roterror)}
print('EXPORT_ROUNDTRIP',report,flush=True)
assert poserror<.001 and roterror<.005
with open(os.path.join(QA,'sprint_export_roundtrip.json'),'w') as f:json.dump(report,f,indent=2)
