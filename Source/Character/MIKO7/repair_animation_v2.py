"""Bake complete transforms from immutable hierarchy matrices; never feed target playback into baking."""
import bpy,os,json,math
from mathutils import Matrix,Vector
BASE=os.path.dirname(os.path.abspath(__file__))
QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v2'));os.makedirs(QA,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v1.blend'))
scene=bpy.context.scene;target=bpy.data.objects['MIKO7_RIG'];source=bpy.data.objects['SOURCE_Quaternius']
target.animation_data.action=None
for track in list(target.animation_data.nla_tracks):target.animation_data.nla_tracks.remove(track)
for pb in target.pose.bones:
    pb.matrix_basis=Matrix.Identity(4)
    if 'IK' in pb:pb['IK']=0.
    for prop in ['Grip','Thumb','Index','Middle','Ring','Pinky']:
        if prop in pb:pb[prop]=0.
source.hide_set(False)
names=[b.name for b in target.data.bones if b.name in source.data.bones and 'f_' not in b.name and 'thumb.' not in b.name]
rest={n:target.data.bones[n].matrix_local.copy() for n in names}
ref={}
for n in names:
    tb=target.data.bones[n];sb=source.data.bones[n]
    tr=tb.matrix_local.to_quaternion();sr=sb.matrix_local.to_quaternion();r=tr
    if any(k in n for k in ['upper_arm','forearm','hand.','shoulder.']):
        r=(tb.tail_local-tb.head_local).normalized().rotation_difference((sb.tail_local-sb.head_local).normalized())@tr
    ref[n]=sr.inverted()@r
clips=['Sprint_Loop']
for a in list(bpy.data.actions):
    if a.name.startswith('MIKO7_') and a.name!='MIKO7_Sprint_Loop':bpy.data.actions.remove(a)
report={}
for clip in clips:
    old=bpy.data.actions.get('MIKO7_'+clip)
    if old:bpy.data.actions.remove(old)
    sa=bpy.data.actions[clip];source.animation_data.action=sa
    if sa.slots:source.animation_data.action_slot=sa.slots[0]
    start,end=map(lambda v:int(round(v)),sa.frame_range)
    samples=[];previous={};maxloc=0.;maxscale=0.
    for f in range(start,end+1):
        scene.frame_set(f);bpy.context.view_layer.update()
        desired={};values={}
        for n in names:
            tb=target.data.bones[n];sb=source.pose.bones[n]
            rot=sb.matrix.to_quaternion()@ref[n]
            if n=='root' or n=='DEF-hips':
                head=tb.head_local+(sb.matrix.translation-source.data.bones[n].head_local)*.43
            else:
                pn=tb.parent.name
                head=desired[pn]@(rest[pn].inverted()@tb.head_local)
            world=rot.to_matrix().to_4x4();world.translation=head;desired[n]=world
            if tb.parent:
                pn=tb.parent.name
                basis=rest[n].inverted()@rest[pn]@desired[pn].inverted()@world
            else:basis=rest[n].inverted()@world
            loc,q,scale=basis.decompose()
            if n in previous:q.make_compatible(previous[n])
            previous[n]=q.copy()
            if n not in ['root','DEF-hips']:maxloc=max(maxloc,loc.length)
            maxscale=max(maxscale,max(abs(v-1) for v in scale))
            values[n]=(loc.copy(),q.copy(),Vector((1,1,1)))
        samples.append(values)
    assert maxloc<1e-4,(clip,maxloc)
    # No animation is attached while sampling. Write the finished action only now.
    a=bpy.data.actions.new('MIKO7_'+clip);a.use_fake_user=True;target.animation_data.action=a
    for i,values in enumerate(samples,1):
        for n,(loc,q,scale) in values.items():
            pb=target.pose.bones[n];pb.location=loc;pb.rotation_quaternion=q;pb.scale=scale
            for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(data_path=prop,frame=i,group=n)
    # Prevent automatic Bezier handles from overshooting fast motion between samples.
    for layer in a.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    for key in fc.keyframe_points:key.interpolation='LINEAR'
    target.animation_data.action=None
    for pb in target.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    report[clip]={'frames':len(samples),'max_unwanted_child_translation':maxloc,'max_scale_error':maxscale}
    print('REBAKED',clip,report[clip],flush=True)
source.hide_set(True);scene.frame_set(1)
target['Animation_fix']='v2: immutable parent matrices; full location/rotation/scale keys; no target-action evaluation during source sampling; linear per-frame keys.'
out=os.path.join(BASE,'MIKO7_Rigged_v2.blend');bpy.ops.wm.save_as_mainfile(filepath=out)
with open(os.path.join(QA,'rebake.json'),'w') as f:json.dump(report,f,indent=2)
# Check each stored frame in chronological AND arbitrary order against hierarchy invariants.
check={}
for clip in clips:
    a=bpy.data.actions['MIKO7_'+clip];target.animation_data.action=a
    orders=[list(range(1,int(a.frame_range[1])+1)),[1,3,2,int(a.frame_range[1]),1,2,3]]
    maxhead=0.;maxlen=0.;snapshots={};ordererror=0.
    for order in orders:
        for f in order:
            scene.frame_set(f);bpy.context.view_layer.update()
            for n in names:
                pb=target.pose.bones[n]
                if pb.parent and n!='DEF-hips':
                    expected=pb.parent.matrix@(pb.parent.bone.matrix_local.inverted()@pb.bone.head_local)
                    maxhead=max(maxhead,(pb.head-expected).length)
                maxlen=max(maxlen,abs((pb.tail-pb.head).length-pb.bone.length))
                key=(f,n);m=pb.matrix.copy()
                if key in snapshots:ordererror=max(ordererror,max(abs(m[r][c]-snapshots[key][r][c]) for r in range(4) for c in range(4)))
                snapshots[key]=m
    check[clip]={'parent_attachment_error':maxhead,'bone_length_error':maxlen,'frame_order_error':ordererror}
    assert maxhead<1e-4 and maxlen<1e-4 and ordererror<1e-5,(clip,check[clip])
    print('VERIFIED',clip,check[clip],flush=True)
with open(os.path.join(QA,'playback_validation.json'),'w') as f:json.dump(check,f,indent=2)
# Full-cycle contact sheet: especially the previously missed first frames.
target.animation_data.action=bpy.data.actions['MIKO7_Sprint_Loop']
scene.render.resolution_x=480;scene.render.resolution_y=480;scene.cycles.samples=8
scene.camera.data.ortho_scale=1.3
for f in range(1,22):
    scene.frame_set(f);bpy.context.view_layer.update()
    scene.render.filepath=os.path.join(QA,f'sprint_{f:02d}.png');bpy.ops.render.render(write_still=True)
target.animation_data.action=None
for pb in target.pose.bones:pb.matrix_basis=Matrix.Identity(4)
