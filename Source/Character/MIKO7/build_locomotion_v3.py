"""MIKO locomotion: deterministic baking, planted feet, extracted turn motion."""
import bpy,os,json,math,struct,numpy as np
from mathutils import Matrix,Vector,Quaternion
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v3'));os.makedirs(QA,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v1.blend'))
scene=bpy.context.scene;scene.render.fps=30
rig=bpy.data.objects['MIKO7_RIG'];source=bpy.data.objects['SOURCE_Quaternius']
rig.animation_data.action=None
for t in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(t)
for p in rig.pose.bones:
    p.matrix_basis=Matrix.Identity(4)
    for k in ['IK','Grip','Thumb','Index','Middle','Ring','Pinky']:
        if k in p:p[k]=0.
for a in list(bpy.data.actions):
    if a.name.startswith('MIKO7_'):bpy.data.actions.remove(a)
names=[b.name for b in rig.data.bones if b.name in source.data.bones and 'f_' not in b.name and 'thumb.' not in b.name]
rest={n:rig.data.bones[n].matrix_local.copy() for n in names}
refs={}
for n in names:
    tb=rig.data.bones[n];sb=source.data.bones[n];tr=tb.matrix_local.to_quaternion()
    if any(k in n for k in ['upper_arm','forearm','hand.','shoulder.']):tr=(tb.tail_local-tb.head_local).normalized().rotation_difference((sb.tail_local-sb.head_local).normalized())@tr
    refs[n]=sb.matrix_local.to_quaternion().inverted()@tr
# Foot shells are rigid: measure their actual sole geometry, rather than guessing a floor offset.
mesh=bpy.data.objects['MIKO7_Armour_and_Joints'];v=np.empty(len(mesh.data.vertices)*3,dtype=np.float32);mesh.data.vertices.foreach_get('co',v);v=v.reshape(-1,3)
footpoints={}
for s in ['L','R']:
    for part in ['foot','toe']:
        n=f'DEF-{part}.{s}';g=mesh.vertex_groups[n].index
        ids=[vv.index for vv in mesh.data.vertices if any(w.group==g and w.weight>.99 for w in vv.groups)]
        footpoints[n]=v[ids]
def sole_min(desired):
    value=1e9
    for n,p in footpoints.items():
        m=np.array(desired[n]@rest[n].inverted(),dtype=np.float64)
        value=min(value,float((p@m[:3,:3].T+m[:3,3])[:,2].min()))
    return value
def local_values(desired):
    result={}
    for n in names:
        tb=rig.data.bones[n]
        basis=rest[n].inverted()@rest[tb.parent.name]@desired[tb.parent.name].inverted()@desired[n] if tb.parent else rest[n].inverted()@desired[n]
        loc,q,scale=basis.decompose();assert max(abs(x-1) for x in scale)<1e-4
        if n not in ['root','DEF-hips']:assert loc.length<1e-4
        result[n]=(loc,q)
    return result
def write_action(label,samples,loop=False):
    if loop:samples[-1]={n:(p.copy(),q.copy()) for n,(p,q) in samples[0].items()}
    a=bpy.data.actions.new('MIKO7_'+label);a.use_fake_user=True;rig.animation_data.action=a;prev={}
    for i,values in enumerate(samples):
        for n,(loc,quat) in values.items():
            p=rig.pose.bones[n];q=quat.copy()
            if n in prev:q.make_compatible(prev[n])
            prev[n]=q.copy();p.location=loc;p.rotation_quaternion=q;p.scale=(1,1,1)
            for prop in ['location','rotation_quaternion','scale']:p.keyframe_insert(data_path=prop,frame=i,group=n)
    for layer in a.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                for fc in bag.fcurves:
                    for key in fc.keyframe_points:key.interpolation='LINEAR'
    rig.animation_data.action=None
    for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
    return a
metadata={'fps':30,'sprint_head_tilt_degrees':12,'clips':{}}
source.hide_set(False)
for t in list(source.animation_data.nla_tracks):source.animation_data.nla_tracks.remove(t)
for clip in ['Idle_Loop','Walk_Loop','Sprint_Loop','Jump_Start','Jump_Loop','Jump_Land']:
    source.animation_data.action=None
    for p in source.pose.bones:p.matrix_basis=Matrix.Identity(4)
    sa=bpy.data.actions[clip];source.animation_data.action=sa
    if sa.slots:source.animation_data.action_slot=sa.slots[0]
    start,end=[int(round(x)) for x in sa.frame_range];samples=[];foottrack=[]
    for f in range(start,end+1):
        scene.frame_set(f);bpy.context.view_layer.update();desired={}
        for n in names:
            tb=rig.data.bones[n];sb=source.pose.bones[n];rot=sb.matrix.to_quaternion()@refs[n]
            if n=='DEF-head' and clip=='Sprint_Loop':rot=rot@Quaternion((1,0,0),math.radians(-12))
            if n in ['root','DEF-hips']:head=tb.head_local+(sb.matrix.translation-source.data.bones[n].head_local)*.43
            else:head=desired[tb.parent.name]@(rest[tb.parent.name].inverted()@tb.head_local)
            m=rot.to_matrix().to_4x4();m.translation=head;desired[n]=m
        flight=0.
        if clip=='Sprint_Loop':
            toe=min(min(source.pose.bones[f'DEF-toe.{s}'].head.z,source.pose.bones[f'DEF-toe.{s}'].tail.z) for s in ['L','R'])
            flight=max(0.,toe-.025)*.43
        dz=flight-sole_min(desired)
        for m in desired.values():m.translation.z+=dz
        foottrack.append({s:list(desired[f'DEF-foot.{s}'].translation) for s in ['L','R']})
        samples.append(local_values(desired))
    label={'Idle_Loop':'Idle','Walk_Loop':'Walk','Sprint_Loop':'Sprint','Jump_Start':'JumpStart','Jump_Loop':'JumpAir','Jump_Land':'JumpLand'}[clip]
    loop=clip.endswith('_Loop');write_action(label,samples,loop)
    metadata['clips'][label]={'duration':(len(samples)-1)/30,'frames':len(samples),'loop':loop,'source':clip}
    if label in ['Walk','Sprint']:
        velocities=[]
        for i in range(len(foottrack)-1):
            for s in ['L','R']:
                dy=(foottrack[i+1][s][1]-foottrack[i][s][1])*30
                if dy>.08:velocities.append(dy)
        metadata['clips'][label]['suggested_speed']=float(np.median(velocities)) if velocities else (.6 if label=='Walk' else 1.4)
    print('BAKED',label,metadata['clips'][label],flush=True)
source.hide_set(True);source.animation_data.action=None
# User-provided normalized humanoid turns are node animations, not skinned rigs.
mapping={'DEF-hips':'hips','DEF-spine.001':'spine','DEF-spine.002':'chest','DEF-spine.003':'upperChest','DEF-neck':'neck','DEF-head':'head'}
for s,side in [('L','left'),('R','right')]:
    for bone,node in [('shoulder','Shoulder'),('upper_arm','UpperArm'),('forearm','LowerArm'),('hand','Hand'),('thigh','UpperLeg'),('shin','LowerLeg'),('foot','Foot'),('toe','Toes')]:mapping[f'DEF-{bone}.{s}']=side+node
child={'hips':'spine','spine':'chest','chest':'upperChest','upperChest':'neck','neck':'head'}
for side in ['left','right']:
    for a,b in [('Shoulder','UpperArm'),('UpperArm','LowerArm'),('LowerArm','Hand'),('Hand','MiddleProximal'),('UpperLeg','LowerLeg'),('LowerLeg','Foot'),('Foot','Toes')]:child[side+a]=side+b
C=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
turn_files=[]
for p,ds,fs in os.walk(os.path.join(BASE,'Turns')):
    for f in fs:
        if f.endswith('.glb'):turn_files.append(os.path.join(p,f))
for path in turn_files:
    raw=open(path,'rb').read();size=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+size]);nodes=doc['nodes'];parents={ch:i for i,n in enumerate(nodes) for ch in n.get('children',[])};global_rest={}
    def world(i):
        if i in global_rest:return global_rest[i]
        n=nodes[i]
        if 'matrix' in n:m=Matrix([n['matrix'][k:k+4] for k in range(0,16,4)]).transposed()
        else:
            q=n.get('rotation',[0,0,0,1]);m=Matrix.LocRotScale(Vector(n.get('translation',[0,0,0])),Quaternion((q[3],q[0],q[1],q[2])),Vector(n.get('scale',[1,1,1])))
        if i in parents:m=world(parents[i])@m
        global_rest[i]=m;return m
    sr={n['name']:C@world(i)@C.inverted() for i,n in enumerate(nodes) if 'name' in n}
    before=set(bpy.data.objects);actions=set(bpy.data.actions);bpy.ops.import_scene.gltf(filepath=path)
    objects=set(bpy.data.objects)-before;sa=next(iter(set(bpy.data.actions)-actions));obj={o.name.split('.')[0]:o for o in objects}
    tref={}
    for n,node in mapping.items():
        tr=rest[n].to_quaternion()
        if any(k in n for k in ['upper_arm','forearm','hand.','shoulder.']):
            td=(rig.data.bones[n].tail_local-rig.data.bones[n].head_local).normalized();sd=(sr[child[node]].translation-sr[node].translation).normalized();tr=td.rotation_difference(sd)@tr
        tref[n]=sr[node].to_quaternion().inverted()@tr
    label=('Turn180' if '180' in sa.name else 'Turn90')+('Left' if '_L' in sa.name else 'Right')
    start,end=[int(round(x)) for x in sa.frame_range];samples=[];yaws=[];motion=[];first_pos=None
    for f in range(start,end+1):
        scene.frame_set(f);bpy.context.view_layer.update();hip=obj['hips'].matrix_world.copy()
        yaw=(hip.to_quaternion()@sr['hips'].to_quaternion().inverted()).to_swing_twist('Z')[1]
        if yaws:
            while yaw-yaws[-1]>math.pi:yaw-=math.tau
            while yaw-yaws[-1]<-math.pi:yaw+=math.tau
        yaws.append(yaw);unturn=Quaternion((0,0,1),-yaw)
        pos=hip.translation.copy()
        if first_pos is None:first_pos=pos.copy()
        delta=(pos-first_pos)*.43;motion.append([delta.x,0.,-delta.y])
        desired={'root':rest['root'].copy()}
        for n in names:
            if n=='root':continue
            node=mapping[n];rot=unturn@obj[node].matrix_world.to_quaternion()@tref[n];tb=rig.data.bones[n]
            head=tb.head_local.copy() if n=='DEF-hips' else desired[tb.parent.name]@(rest[tb.parent.name].inverted()@tb.head_local)
            m=rot.to_matrix().to_4x4();m.translation=head;desired[n]=m
        dz=-sole_min(desired)
        for m in desired.values():m.translation.z+=dz
        samples.append(local_values(desired))
    yaws=np.array(yaws)-yaws[0]
    expected=math.radians(180 if '180' in label else 90)*(1 if 'Left' in label else -1)
    if abs(yaws[-1])<math.radians(40):
        t=np.linspace(0,1,len(yaws));yaws=expected*(t*t*(3-2*t))
    else:yaws*=expected/yaws[-1]
    write_action(label,samples)
    metadata['clips'][label]={'duration':(len(samples)-1)/30,'frames':len(samples),'loop':False,'source_file':os.path.relpath(path,BASE),'yaw':yaws.tolist(),'root_motion':motion,'turn_degrees':math.degrees(expected)}
    for o in objects:bpy.data.objects.remove(o,do_unlink=True)
    print('BAKED',label,'frames',len(samples),'yaw',math.degrees(yaws[-1]),flush=True)
# Remove reference actions from the deliverable dropdown and export only the new rig.
for a in list(bpy.data.actions):
    if not a.name.startswith('MIKO7_'):bpy.data.actions.remove(a)
rig['About']='MIKO7 locomotion v3: idle, walk, sprint, full jump, four supplied turn clips.'
rig['Sprint_head']='12 degrees backward head tilt, sprint only.'
scene.frame_set(0);rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
with open(os.path.join(BASE,'MIKO7_Locomotion_v3.json'),'w') as f:json.dump(metadata,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'MIKO7_Locomotion_v3.blend'))
# Validate every baked sample, not just selected poses.
validation={}
for a in [x for x in bpy.data.actions if x.name.startswith('MIKO7_')]:
    rig.animation_data.action=a;maxlen=0.;maxattach=0.;poses={};history=0.
    frames=list(range(int(a.frame_range[0]),int(a.frame_range[1])+1))
    for f in frames+[0,2,1,frames[-1],0]:
        scene.frame_set(f);bpy.context.view_layer.update()
        for n in names:
            p=rig.pose.bones[n];maxlen=max(maxlen,abs((p.tail-p.head).length-p.bone.length))
            if p.parent and n!='DEF-hips':maxattach=max(maxattach,(p.head-p.parent.matrix@(p.parent.bone.matrix_local.inverted()@p.bone.head_local)).length)
            key=(f,n);m=p.matrix.copy()
            if key in poses:history=max(history,max(abs(m[r][c]-poses[key][r][c]) for r in range(4) for c in range(4)))
            poses[key]=m
    validation[a.name]={'bone_length_error':maxlen,'attachment_error':maxattach,'history_error':history}
    assert maxlen<1e-4 and maxattach<1e-4 and history<1e-5
with open(os.path.join(QA,'bake_validation.json'),'w') as f:json.dump(validation,f,indent=2)
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(0)
for o in scene.objects:o.select_set(o==rig or (o.type=='MESH' and o.parent==rig))
bpy.context.view_layer.objects.active=rig
for a in [x for x in bpy.data.actions if x.name.startswith('MIKO7_')]:
    t=rig.animation_data.nla_tracks.new();t.name=a.name;s=t.strips.new(a.name,0,a)
    if hasattr(s,'action_slot'):s.action_slot=a.slots[0]
props=bpy.ops.export_scene.gltf.get_rna_type().properties
options={'filepath':os.path.join(BASE,'MIKO7_Locomotion_v3.glb'),'use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_skins':True,'export_def_bones':True,'export_force_sampling':True,'export_morph':False}
bpy.ops.export_scene.gltf(**{k:v for k,v in options.items() if k in props})
print('LOCOMOTION_V3_EXPORTED',flush=True)
