"""Refine WALK only: steady pelvis, low swing clearance, matched-speed foot plants."""
import bpy,os,math,json,numpy as np
from mathutils import Vector,Quaternion,Matrix
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v4'));os.makedirs(QA,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v3.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG'];old=bpy.data.actions['MIKO7_Walk'];rig.animation_data.action=old
names=[b.name for b in rig.data.bones if b.name=='root' or (b.use_deform and 'f_' not in b.name and 'thumb.' not in b.name)]
rest={n:rig.data.bones[n].matrix_local.copy() for n in names};original=[]
for f in range(41):
    scene.frame_set(f);bpy.context.view_layer.update();original.append({n:rig.pose.bones[n].matrix.copy() for n in names})
means={}
for n in names:
    qs=[x[n].to_quaternion() for x in original[:-1]]
    for q in qs:q.make_compatible(qs[0])
    means[n]=Quaternion(np.array([list(q) for q in qs]).mean(0).tolist()).normalized()
mesh=bpy.data.objects['MIKO7_Armour_and_Joints'];coords=np.empty(len(mesh.data.vertices)*3,dtype=np.float32);mesh.data.vertices.foreach_get('co',coords);coords=coords.reshape(-1,3)
feet={}
for side in ['L','R']:
    ids={mesh.vertex_groups[f'DEF-{p}.{side}'].index for p in ['foot','toe']}
    vi=[v.index for v in mesh.data.vertices if any(w.group in ids and w.weight>.99 for w in v.groups)]
    feet[side]=coords[vi]-np.array(rig.data.bones[f'DEF-foot.{side}'].head_local)

DURATION=1.0;FPS=30;NOMINAL_SPEED=.45;STANCE=.58;TRAVEL=NOMINAL_SPEED*DURATION*STANCE;LIFT=.026
def smooth(t):return t*t*(3-2*t)
def trajectory(phase):
    if phase<STANCE:
        t=phase/STANCE;y=-TRAVEL*.5+TRAVEL*t;lift=0.
        pitch=math.radians(-4)*(1-smooth(min(1.,t/.12))) if t<.12 else (math.radians(6)*smooth(max(0.,(t-.82)/.18)) if t>.82 else 0.)
        planted=True
    else:
        t=(phase-STANCE)/(1-STANCE);p0=TRAVEL*.5;p1=-TRAVEL*.5;m=NOMINAL_SPEED*DURATION*(1-STANCE)
        y=(2*t**3-3*t*t+1)*p0+(t**3-2*t*t+t)*m+(-2*t**3+3*t*t)*p1+(t**3-t*t)*m
        lift=LIFT*math.sin(math.pi*t)**2;pitch=math.radians(6-10*smooth(t));planted=False
    return y,lift,pitch,planted
def source_rot(n,phase):
    f=phase*40;i=int(math.floor(f));j=min(i+1,40)
    return original[i][n].to_quaternion().slerp(original[j][n].to_quaternion(),f-i)
def matrix(q,p):
    m=q.to_matrix().to_4x4();m.translation=p;return m
def aim_bone(n,head,tail):
    b=rig.data.bones[n];d=(b.tail_local-b.head_local).normalized()
    return d.rotation_difference((tail-head).normalized())@b.matrix_local.to_quaternion()
samples=[];tracks=[];metrics=[];reach=0.
for frame in range(31):
    phase=frame/30.;desired={'root':rest['root'].copy()}
    h=Vector((.0025*math.cos(math.tau*phase),.025,.370+.001*math.cos(2*math.tau*phase)))
    desired['DEF-hips']=matrix(means['DEF-hips'].slerp(source_rot('DEF-hips',phase),.18),h)
    for n in names:
        if n in ['root','DEF-hips'] or any(p in n for p in ['thigh.','shin.','foot.','toe.']):continue
        b=rig.data.bones[n];parent=b.parent.name
        head=desired[parent]@(rest[parent].inverted()@b.head_local)
        q=source_rot(n,phase)
        if n in ['DEF-spine.001','DEF-spine.002','DEF-spine.003','DEF-neck','DEF-head']:q=means[n].slerp(q,.22)
        desired[n]=matrix(q,head)
    foot_track={}
    for side,sgn in [('L',1),('R',-1)]:
        p=(phase+(0 if side=='L' else .5))%1.
        y,lift,pitch,planted=trajectory(p)
        fq=Quaternion((1,0,0),pitch)@rest['DEF-foot.'+side].to_quaternion()
        delta=fq@rest['DEF-foot.'+side].to_quaternion().inverted()
        points=feet[side]@np.array(delta.to_matrix()).T
        ankle=Vector((sgn*.113,.034+y,float(-points[:,2].min())+lift))
        thigh='DEF-thigh.'+side;shin='DEF-shin.'+side
        hip=desired['DEF-hips']@(rest['DEF-hips'].inverted()@rig.data.bones[thigh].head_local)
        a=rig.data.bones[thigh].length;b=rig.data.bones[shin].length;d=(ankle-hip).length;reach=max(reach,d/(a+b))
        assert d<a+b-1e-5,('unreachable step',frame,side,d,a+b)
        axis=(ankle-hip).normalized();pole=Vector((sgn*.08,-1,0));pole=(pole-axis*pole.dot(axis)).normalized()
        along=(a*a-b*b+d*d)/(2*d);height=math.sqrt(max(0.,a*a-along*along));knee=hip+axis*along+pole*height
        desired[thigh]=matrix(aim_bone(thigh,hip,knee),hip);desired[shin]=matrix(aim_bone(shin,knee,ankle),knee)
        foot='DEF-foot.'+side;toe='DEF-toe.'+side
        desired[foot]=matrix(fq,ankle)
        desired[toe]=matrix(delta@rest[toe].to_quaternion(),desired[foot]@(rest[foot].inverted()@rig.data.bones[toe].head_local))
        foot_track[side]={'phase':p,'planted':planted,'ankle':list(ankle),'sole_height':float((points+np.array(ankle))[:,2].min())}
    values={}
    for n in names:
        b=rig.data.bones[n]
        basis=rest[n].inverted()@rest[b.parent.name]@desired[b.parent.name].inverted()@desired[n] if b.parent else rest[n].inverted()@desired[n]
        loc,q,scale=basis.decompose()
        assert max(abs(v-1) for v in scale)<1e-4
        if n not in ['root','DEF-hips']:assert loc.length<1e-4
        values[n]=(loc,q)
    samples.append(values);tracks.append(foot_track);metrics.append({'hips':list(h),'head':list(desired['DEF-head'].translation)})
samples[-1]={n:(p.copy(),q.copy()) for n,(p,q) in samples[0].items()}
rig.animation_data.action=None;bpy.data.actions.remove(old)
new=bpy.data.actions.new('MIKO7_Walk');new.use_fake_user=True;rig.animation_data.action=new;previous={}
for frame,values in enumerate(samples):
    for n,(loc,quat) in values.items():
        p=rig.pose.bones[n];q=quat.copy()
        if n in previous:q.make_compatible(previous[n])
        previous[n]=q.copy();p.location=loc;p.rotation_quaternion=q;p.scale=(1,1,1)
        for prop in ['location','rotation_quaternion','scale']:p.keyframe_insert(data_path=prop,frame=frame,group=n)
for layer in new.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for fc in bag.fcurves:
                for key in fc.keyframe_points:key.interpolation='LINEAR'
# Record measured body motion and contact velocity; preserve all other actions.
oldhip=np.array([x['DEF-hips'].translation for x in original]);oldhead=np.array([x['DEF-head'].translation for x in original])
newhip=np.array([x['hips'] for x in metrics]);newhead=np.array([x['head'] for x in metrics])
contacts=[]
for i in range(30):
    for side in ['L','R']:
        a,b=tracks[i][side],tracks[i+1][side]
        if a['planted'] and b['planted'] and .15<a['phase']/STANCE<.78 and .15<b['phase']/STANCE<.78:
            contacts.append((b['ankle'][1]-a['ankle'][1])*FPS)
report={'before_hip_bounce_m':float(np.ptp(oldhip[:,2])),'after_hip_bounce_m':float(np.ptp(newhip[:,2])),'before_head_bounce_m':float(np.ptp(oldhead[:,2])),'after_head_bounce_m':float(np.ptp(newhead[:,2])),'stance_backward_speed_m_s':float(np.mean(contacts)),'nominal_walk_speed_m_s':NOMINAL_SPEED,'contact_speed_error':float(max(abs(v-NOMINAL_SPEED) for v in contacts)),'maximum_reach_fraction':reach,'foot_clearance_m':LIFT,'duration':DURATION}
assert report['after_head_bounce_m']<.009 and report['contact_speed_error']<1e-5
with open(os.path.join(QA,'walk_refinement_metrics.json'),'w') as f:json.dump(report,f,indent=2)
with open(os.path.join(QA,'walk_foot_tracks.json'),'w') as f:json.dump(tracks,f,indent=2)
meta=json.load(open(os.path.join(BASE,'MIKO7_Locomotion_v3.json')))
meta['walk_refinement']=report;meta['clips']['Walk'].update({'duration':DURATION,'frames':31,'suggested_speed':NOMINAL_SPEED,'nominal_speed':NOMINAL_SPEED,'source':'Refined Walk: steady pelvis, two-bone leg solve, ground-contact trajectories'})
with open(os.path.join(BASE,'MIKO7_Locomotion_v4.json'),'w') as f:json.dump(meta,f,indent=2)
rig['Walk_refinement']='v4: steady torso; lower foot clearance; explicit stance contacts; 0.45 m/s nominal at 30fps.'
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v4.blend'))
print('WALK_REFINEMENT',json.dumps(report),flush=True)
for o in scene.objects:o.select_set(o==rig or (o.type=='MESH' and o.parent==rig))
bpy.context.view_layer.objects.active=rig
for a in [a for a in bpy.data.actions if a.name.startswith('MIKO7_')]:
    t=rig.animation_data.nla_tracks.new();t.name=a.name;s=t.strips.new(a.name,0,a)
    if hasattr(s,'action_slot'):s.action_slot=a.slots[0]
props=bpy.ops.export_scene.gltf.get_rna_type().properties
opts={'filepath':os.path.join(BASE,'MIKO7_Locomotion_v4.glb'),'use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_skins':True,'export_def_bones':True,'export_force_sampling':True,'export_morph':False}
bpy.ops.export_scene.gltf(**{k:v for k,v in opts.items() if k in props})
print('WALK_V4_EXPORTED',flush=True)
