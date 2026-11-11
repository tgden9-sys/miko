"""Reproducible v5 review: brisk matched-stride walk and global 30-degree gaze calibration."""
from pathlib import Path
BASE=Path(__file__).resolve().parent
code=(BASE/'refine_walk_v4.py').read_text(encoding='utf-8')
changes=[
    ("v4","v5"),
    ("DURATION=1.0;FPS=30;NOMINAL_SPEED=.45;STANCE=.58", "DURATION=.8;FPS=30;NOMINAL_SPEED=.72;STANCE=.56"),
    ("for frame in range(31):", "for frame in range(25):"),
    ("phase=frame/30.;", "phase=frame/24.;"),
    (".370+.001*math.cos", ".355+.001*math.cos"),
    ("for i in range(30):", "for i in range(24):"),
    ("'frames':31", "'frames':25"),
    ("'nominal_speed':NOMINAL_SPEED", "'nominal_speed':NOMINAL_SPEED,'stance_fraction':STANCE"),
    ("0.45 m/s nominal", "0.72 m/s nominal"),
]
for old,new in changes:
    assert old in code,old
    code=code.replace(old,new)
marker="with open(os.path.join(BASE,'MIKO7_Locomotion_v5.json'),'w') as f:json.dump(meta,f,indent=2)"
assert marker in code
gaze='''
# The model's head mounting angle needs the same correction in every motion.
# Sample first, then key the fixed local pitch; no feedback from modified curves.
gaze_offset=Quaternion((1,0,0),math.radians(-30))
gaze_report={}
for action in [a for a in bpy.data.actions if a.name.startswith('MIKO7_')]:
    rig.animation_data.action=action
    if action.slots:rig.animation_data.action_slot=action.slots[0]
    head_samples=[]
    for f in range(int(action.frame_range[0]),int(action.frame_range[1])+1):
        scene.frame_set(f);bpy.context.view_layer.update()
        head_samples.append((f,rig.pose.bones['DEF-head'].rotation_quaternion.copy()))
    previous=None
    for f,q in head_samples:
        corrected=q@gaze_offset
        if previous is not None:corrected.make_compatible(previous)
        previous=corrected.copy()
        rig.pose.bones['DEF-head'].rotation_quaternion=corrected
        rig.pose.bones['DEF-head'].keyframe_insert(data_path='rotation_quaternion',frame=f,group='DEF-head')
    gaze_report[action.name]={'local_pitch_lift_degrees':30,'frames':len(head_samples)}
meta['global_gaze_lift_degrees']=30
meta['review_note']='Global gaze calibration; brisker planted walk; smoother phase-independent jump preparation in Godot.'
with open(os.path.join(QA,'gaze_calibration.json'),'w') as f:json.dump(gaze_report,f,indent=2)
rig['Global_gaze_calibration']='30-degree backward local head pitch applied to all ten animations.'
# A mounting correction alone still lets the jump's torso pitch aim the eyes down.
# Stabilize the world-facing gaze around the corrected walking reference, while
# retaining a little head motion and the original yaw/roll.
head_rest=rig.data.bones['DEF-head'].matrix_local.to_quaternion()
forward=Vector((0,-1,0))
def elevation(q):
    d=(q@head_rest.inverted())@forward
    return math.atan2(d.z,math.hypot(d.x,d.y))
rig.animation_data.action=bpy.data.actions['MIKO7_Walk']
reference=[]
for f in range(25):
    scene.frame_set(f);bpy.context.view_layer.update()
    reference.append(elevation(rig.pose.bones['DEF-head'].matrix.to_quaternion()))
reference=float(np.mean(reference))
gaze_ranges={}
for action in [a for a in bpy.data.actions if a.name.startswith('MIKO7_')]:
    rig.animation_data.action=action
    samples=[];angles=[]
    for f in range(int(action.frame_range[0]),int(action.frame_range[1])+1):
        scene.frame_set(f);bpy.context.view_layer.update();head=rig.pose.bones['DEF-head']
        q=head.matrix.to_quaternion();current=elevation(q)
        wanted=reference+max(-math.radians(4),min(math.radians(4),(current-reference)*.18))
        d=(q@head_rest.inverted())@forward
        right=Vector((0,0,1)).cross(Vector((d.x,d.y,0))).normalized()
        corrected=Quaternion(right,-(wanted-current))@q
        desired=corrected.to_matrix().to_4x4();desired.translation=head.matrix.translation
        basis=head.bone.matrix_local.inverted()@head.parent.bone.matrix_local@head.parent.matrix.inverted()@desired
        samples.append((f,basis.to_quaternion()));angles.append(math.degrees(wanted))
    previous=None
    for f,q in samples:
        if previous is not None:q.make_compatible(previous)
        previous=q.copy();rig.pose.bones['DEF-head'].rotation_quaternion=q
        rig.pose.bones['DEF-head'].keyframe_insert(data_path='rotation_quaternion',frame=f,group='DEF-head')
    gaze_ranges[action.name]={'minimum_reference_elevation_degrees':min(angles),'maximum_reference_elevation_degrees':max(angles)}
meta['gaze_stabilization']={'reference_elevation_degrees':math.degrees(reference),'retained_pitch_motion_fraction':.18,'ranges':gaze_ranges}
with open(os.path.join(QA,'gaze_stabilization.json'),'w') as f:json.dump(meta['gaze_stabilization'],f,indent=2)
'''
code=code.replace(marker,gaze+'\n'+marker)
exec(compile(code,str(BASE/'generated_review_v5.py'),'exec'))
