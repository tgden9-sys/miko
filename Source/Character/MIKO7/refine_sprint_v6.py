"""Sprint-only refinement on the approved v5 walk/gaze/jump checkpoint."""
import bpy,os,math,json,numpy as np
from mathutils import Vector,Quaternion,Matrix
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v6'));os.makedirs(QA,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v5.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG'];old=bpy.data.actions['MIKO7_Sprint'];rig.animation_data.action=old
names=[b.name for b in rig.data.bones if b.name=='root' or (b.use_deform and 'f_' not in b.name and 'thumb.' not in b.name)]
rest={n:rig.data.bones[n].matrix_local.copy() for n in names};original=[]
for f in range(21):
    scene.frame_set(f);bpy.context.view_layer.update();original.append({n:rig.pose.bones[n].matrix.copy() for n in names})
means={}
for n in names:
    qs=[p[n].to_quaternion() for p in original[:-1]]
    for q in qs:q.make_compatible(qs[0])
    means[n]=Quaternion(np.mean([list(q) for q in qs],axis=0).tolist()).normalized()
mesh=bpy.data.objects['MIKO7_Armour_and_Joints'];v=np.empty(len(mesh.data.vertices)*3,dtype=np.float32);mesh.data.vertices.foreach_get('co',v);v=v.reshape(-1,3)
feet={}
for side in ['L','R']:
    groups={mesh.vertex_groups[f'DEF-{p}.{side}'].index for p in ['foot','toe']}
    ids=[p.index for p in mesh.data.vertices if any(w.group in groups and w.weight>.99 for w in p.groups)]
    feet[side]=v[ids]-np.array(rest['DEF-foot.'+side].translation)

FPS=30;FRAMES=18;DURATION=.6;SPEED=2.2;STANCE=.30;TRAVEL=SPEED*DURATION*STANCE;LIFT=.085
def smooth(t):return t*t*(3-2*t)
def body_height(phase):
    p=phase%.5
    if p<STANCE:
        u=p/STANCE
        return .337+.20*(STANCE*DURATION)*(u*u-u)
    u=(p-STANCE)/(.5-STANCE)
    return .337+.20*((.5-STANCE)*DURATION)*u*(1-u)
def foot_path(phase):
    if phase<STANCE:
        u=phase/STANCE;y=-TRAVEL*.5+TRAVEL*u;lift=0.;planted=True
        pitch=math.radians(-10)*(1-smooth(min(1.,u/.18))) if u<.18 else (math.radians(14)*smooth(max(0.,(u-.70)/.30)) if u>.70 else 0.)
    else:
        u=(phase-STANCE)/(1-STANCE);edge=.055;m=SPEED*DURATION*(1-STANCE);extra=m*edge*.5
        if u<edge:y=TRAVEL*.5+m*(u-u*u/(2*edge))
        elif u>1-edge:y=-TRAVEL*.5-extra+m*(u-(1-edge))**2/(2*edge)
        else:y=(TRAVEL*.5+extra)*(1-2*smooth((u-edge)/(1-2*edge)))
        if u<.13:lift=LIFT*smooth(u/.13)
        elif u<.50:lift=LIFT
        elif u<.90:lift=LIFT+(0.035-LIFT)*smooth((u-.50)/.40)
        else:lift=.035*(1-smooth((u-.90)/.10))
        pitch=math.radians(14-24*smooth(u));planted=False
    return y,lift,pitch,planted
def rot(n,phase):
    f=phase*20;i=int(math.floor(f));j=min(20,i+1)
    return original[i][n].to_quaternion().slerp(original[j][n].to_quaternion(),f-i)
def matrix(q,p):
    m=q.to_matrix().to_4x4();m.translation=p;return m
def aim(n,h,t):
    b=rig.data.bones[n]
    return (b.tail_local-b.head_local).normalized().rotation_difference((t-h).normalized())@b.matrix_local.to_quaternion()
samples=[];tracks=[];metric=[];reach=0.
for frame in range(FRAMES+1):
    phase=frame/FRAMES;desired={'root':rest['root'].copy()}
    h=Vector((.0035*math.sin(math.tau*phase),.025,body_height(phase)))
    desired['DEF-hips']=matrix(means['DEF-hips'].slerp(rot('DEF-hips',phase),.25),h)
    for n in names:
        if n in ['root','DEF-hips'] or any(x in n for x in ['thigh.','shin.','foot.','toe.']):continue
        b=rig.data.bones[n];head=desired[b.parent.name]@(rest[b.parent.name].inverted()@b.head_local);q=rot(n,phase)
        if n in ['DEF-spine.001','DEF-spine.002','DEF-spine.003']:q=means[n].slerp(q,.35)
        elif n in ['DEF-neck','DEF-head']:q=means[n].slerp(q,.45)
        desired[n]=matrix(q,head)
    feet_track={}
    for side,sgn in [('L',1),('R',-1)]:
        p=(phase+(0 if side=='L' else .5))%1.;y,lift,pitch,planted=foot_path(p)
        foot='DEF-foot.'+side;toe='DEF-toe.'+side;thigh='DEF-thigh.'+side;shin='DEF-shin.'+side
        fq=Quaternion((1,0,0),pitch)@rest[foot].to_quaternion();delta=fq@rest[foot].to_quaternion().inverted()
        points=feet[side]@np.array(delta.to_matrix()).T
        ankle=Vector((sgn*.116,.043+y,float(-points[:,2].min())+lift))
        hip=desired['DEF-hips']@(rest['DEF-hips'].inverted()@rig.data.bones[thigh].head_local)
        a=rig.data.bones[thigh].length;b=rig.data.bones[shin].length;d=(ankle-hip).length;reach=max(reach,d/(a+b))
        assert d<a+b-1e-5,('unreachable Sprint step',frame,side,d,a+b,ankle,h)
        axis=(ankle-hip).normalized();pole=Vector((sgn*.08,-1,0));pole=(pole-axis*pole.dot(axis)).normalized()
        along=(a*a-b*b+d*d)/(2*d);height=math.sqrt(max(0.,a*a-along*along));knee=hip+axis*along+pole*height
        desired[thigh]=matrix(aim(thigh,hip,knee),hip);desired[shin]=matrix(aim(shin,knee,ankle),knee)
        desired[foot]=matrix(fq,ankle);desired[toe]=matrix(delta@rest[toe].to_quaternion(),desired[foot]@(rest[foot].inverted()@rig.data.bones[toe].head_local))
        feet_track[side]={'phase':p,'planted':planted,'ankle':list(ankle),'sole_height':float((points+np.array(ankle))[:,2].min())}
    values={}
    for n in names:
        b=rig.data.bones[n]
        basis=rest[n].inverted()@rest[b.parent.name]@desired[b.parent.name].inverted()@desired[n] if b.parent else rest[n].inverted()@desired[n]
        loc,q,scale=basis.decompose();assert max(abs(x-1) for x in scale)<1e-4
        if n not in ['root','DEF-hips']:assert loc.length<1e-4
        values[n]=(loc,q)
    samples.append(values);tracks.append(feet_track);metric.append({'hips':list(h),'head':list(desired['DEF-head'].translation)})
samples[-1]={n:(p.copy(),q.copy()) for n,(p,q) in samples[0].items()}
rig.animation_data.action=None;bpy.data.actions.remove(old);action=bpy.data.actions.new('MIKO7_Sprint');action.use_fake_user=True;rig.animation_data.action=action;previous={}
for frame,values in enumerate(samples):
    for n,(p,q) in values.items():
        q=q.copy()
        if n in previous:q.make_compatible(previous[n])
        previous[n]=q.copy();pb=rig.pose.bones[n];pb.location=p;pb.rotation_quaternion=q;pb.scale=(1,1,1)
        for path in ['location','rotation_quaternion','scale']:pb.keyframe_insert(data_path=path,frame=frame,group=n)
for layer in action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for fc in bag.fcurves:
                for k in fc.keyframe_points:k.interpolation='LINEAR'
oldhips=np.array([x['DEF-hips'].translation for x in original]);oldhead=np.array([x['DEF-head'].translation for x in original])
hips=np.array([x['hips'] for x in metric]);head=np.array([x['head'] for x in metric]);contacts=[]
for i in range(FRAMES):
    for side in ['L','R']:
        a,b=tracks[i][side],tracks[i+1][side]
        if a['planted'] and b['planted'] and .18<a['phase']/STANCE<.70 and .18<b['phase']/STANCE<.70:contacts.append((b['ankle'][1]-a['ankle'][1])*FPS)
report={'before_hip_bounce_m':float(np.ptp(oldhips[:,2])),'after_hip_bounce_m':float(np.ptp(hips[:,2])),'before_head_bounce_m':float(np.ptp(oldhead[:,2])),'after_head_bounce_m':float(np.ptp(head[:,2])),'nominal_speed_m_s':SPEED,'contact_speed_error':float(max(abs(v-SPEED) for v in contacts)),'maximum_reach_fraction':reach,'duration':DURATION,'stance_fraction':STANCE}
assert report['after_head_bounce_m']<.025 and report['contact_speed_error']<1e-5
with open(os.path.join(QA,'sprint_refinement_metrics.json'),'w') as f:json.dump(report,f,indent=2)
with open(os.path.join(QA,'sprint_foot_tracks.json'),'w') as f:json.dump(tracks,f,indent=2)
meta=json.load(open(os.path.join(BASE,'MIKO7_Locomotion_v5.json')));meta['sprint_refinement']=report
meta['clips']['Sprint'].update({'duration':DURATION,'frames':FRAMES+1,'nominal_speed':SPEED,'suggested_speed':SPEED,'stance_fraction':STANCE,'source':'Refined Sprint: fixed contacts, controlled pelvis travel and matched 2.2 m/s stride'})
with open(os.path.join(BASE,'MIKO7_Locomotion_v6.json'),'w') as f:json.dump(meta,f,indent=2)
rig['Sprint_refinement']='v6: 2.2 m/s nominal; stable body; planted contact and low controlled flight. v5 walk and global gaze retained.'
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v6.blend'))
print('SPRINT_V6_METRICS',json.dumps(report),flush=True)
for o in scene.objects:o.select_set(o==rig or (o.type=='MESH' and o.parent==rig))
bpy.context.view_layer.objects.active=rig
for a in [a for a in bpy.data.actions if a.name.startswith('MIKO7_')]:
    t=rig.animation_data.nla_tracks.new();t.name=a.name;s=t.strips.new(a.name,0,a)
    if hasattr(s,'action_slot'):s.action_slot=a.slots[0]
props=bpy.ops.export_scene.gltf.get_rna_type().properties
opts={'filepath':os.path.join(BASE,'MIKO7_Locomotion_v6.glb'),'use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_skins':True,'export_def_bones':True,'export_force_sampling':True,'export_morph':False}
bpy.ops.export_scene.gltf(**{k:v for k,v in opts.items() if k in props})
print('SPRINT_V6_EXPORTED',flush=True)
