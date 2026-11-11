"""Rebuild MIKO7 from preserved GLB; fit, skin, and retarget a shared humanoid rig."""
import bpy, numpy as np, math, os, json
from mathutils import Vector, Matrix, Quaternion
BASE=os.path.dirname(os.path.abspath(__file__))
QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7'))
os.makedirs(QA,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=os.path.join(BASE,'miko7_source.glb'))
mesh=next(o for o in scene.objects if o.type=='MESH');mesh.name='MIKO7_Armour_and_Joints'
mesh.parent=None
mesh.matrix_world=Matrix.Identity(4)
raw=np.empty(len(mesh.data.vertices)*3,dtype=np.float32);mesh.data.vertices.foreach_get('co',raw);raw=raw.reshape(-1,3)
GROUND=float(-raw[:,2].min())
p=raw.copy();p[:,2]+=GROUND;mesh.data.vertices.foreach_set('co',p.ravel());mesh.data.update()
for o in list(scene.objects):
    if o.type=='EMPTY':bpy.data.objects.remove(o,do_unlink=True)
before=set(bpy.data.objects)
srcpath=os.path.join(BASE,'Quaternius','Animation Library[Standard]','Godot','AnimationLibrary_Godot_Standard.glb')
bpy.ops.import_scene.gltf(filepath=srcpath)
source=next(o for o in set(bpy.data.objects)-before if o.type=='ARMATURE')
source.name='SOURCE_Quaternius'
source_actions={a.name:a for a in bpy.data.actions}
src_col=bpy.data.collections.new('REFERENCE_Quaternius');scene.collection.children.link(src_col)
for o in set(bpy.data.objects)-before:
    for c in list(o.users_collection):c.objects.unlink(o)
    src_col.objects.link(o)
    o.hide_render=True;o.hide_set(True)
src_col.hide_render=True

arm=bpy.data.armatures.new('MIKO_Humanoid_Skeleton')
rig=bpy.data.objects.new('MIKO7_RIG',arm);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);mesh.select_set(False)
rig.show_in_front=True
def wp(v):return Vector((v[0],v[1],v[2]+GROUND))
spec={}
def bone(n,h,t,parent=None):spec[n]=(wp(h),wp(t),parent)
bone('root',(0,0,-GROUND),(0,0,-GROUND+.07))
bone('DEF-hips',(0,.025,-.105),(0,.025,-.045),'root')
bone('DEF-spine.001',(0,.025,-.045),(0,.025,.012),'DEF-hips')
bone('DEF-spine.002',(0,.025,.012),(0,.025,.075),'DEF-spine.001')
bone('DEF-spine.003',(0,.025,.075),(0,.025,.154),'DEF-spine.002')
bone('DEF-neck',(0,.025,.154),(0,.025,.192),'DEF-spine.003')
bone('DEF-head',(0,.025,.192),(0,.025,.41),'DEF-neck')
finger_paths={}
for s,sgn in [('L',1),('R',-1)]:
    def v(x,y,z):return (x*sgn,y,z)
    bone('DEF-shoulder.'+s,v(.062,.025,.145),v(.157,.025,.141),'DEF-spine.003')
    bone('DEF-upper_arm.'+s,v(.157,.025,.141),v(.19,.017,-.008),'DEF-shoulder.'+s)
    bone('DEF-forearm.'+s,v(.19,.017,-.008),v(.232,.008,-.126),'DEF-upper_arm.'+s)
    bone('DEF-hand.'+s,v(.232,.008,-.126),v(.25,-.007,-.178),'DEF-forearm.'+s)
    for digit,y,shrink in [('index',-.042,0),('middle',-.020,0),('ring',.002,.003),('pinky',.023,.009)]:
        path=[v(.252,y,-.178+shrink),v(.245,y,-.205+shrink),v(.219,y,-.221+shrink),v(.196,y,-.211+shrink)]
        finger_paths[(s,digit)]=path
        parent='DEF-hand.'+s
        for j in range(3):
            n=f'DEF-f_{digit}.{j+1:02d}.{s}';bone(n,path[j],path[j+1],parent);parent=n
    path=[v(.218,-.032,-.139),v(.201,-.044,-.154),v(.184,-.052,-.173),v(.174,-.055,-.187)]
    finger_paths[(s,'thumb')]=path;parent='DEF-hand.'+s
    for j in range(3):
        n=f'DEF-thumb.{j+1:02d}.{s}';bone(n,path[j],path[j+1],parent);parent=n
    bone('DEF-thigh.'+s,v(.077,.031,-.108),v(.105,.019,-.274),'DEF-hips')
    bone('DEF-shin.'+s,v(.105,.019,-.274),v(.13,.034,-.417),'DEF-thigh.'+s)
    bone('DEF-foot.'+s,v(.13,.034,-.417),v(.13,-.053,-.475),'DEF-shin.'+s)
    bone('DEF-toe.'+s,v(.13,-.053,-.475),v(.13,-.108,-.475),'DEF-foot.'+s)
bpy.ops.object.mode_set(mode='EDIT')
for n,(h,t,parent) in spec.items():
    b=arm.edit_bones.new(n);b.head=h;b.tail=t
    if parent:b.parent=arm.edit_bones[parent]
    if 'thumb.' in n or 'f_' in n:
        # Curl X is the depth axis, so the fingers follow their existing curved silhouette.
        b.align_roll(Vector((0,1,0)).cross((t-h).normalized()))
    elif n in source.data.bones:
        z=source.data.bones[n].matrix_local.to_3x3().col[2]
        if abs(z.normalized().dot((t-h).normalized()))<.95:b.align_roll(z)
    b.use_deform=n!='root'
for s in ['L','R']:
    for part in ['hand','foot']:
        ref=arm.edit_bones[f'DEF-{part}.{s}']
        c=arm.edit_bones.new(f'CTRL-{part}.{s}');c.head=ref.head;c.tail=ref.head+Vector((0,-.055,0));c.parent=arm.edit_bones['root'];c.use_deform=False
    for part,point in [('elbow',(.19,-.24,-.008)),('knee',(.105,-.22,-.274))]:
        c=arm.edit_bones.new(f'CTRL-{part}_pole.{s}');c.head=wp((point[0]*(1 if s=='L' else -1),point[1],point[2]));c.tail=c.head+Vector((0,0,.03));c.parent=arm.edit_bones['root'];c.use_deform=False
bpy.ops.object.mode_set(mode='OBJECT')
deform=arm.collections.new('Humanoid / FK')
fingers=arm.collections.new('Finger bones (advanced)')
controls=arm.collections.new('Easy hands and IK')
for b in arm.bones:
    (controls if b.name.startswith('CTRL') or b.name=='root' else fingers if 'f_' in b.name or 'thumb.' in b.name else deform).assign(b)
    b.color.palette='THEME04' if '.L' in b.name else 'THEME01' if '.R' in b.name else 'THEME03'
fingers.is_visible=False
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'

# Material-aware, predominantly rigid skinning, with narrow joint blends.
N=len(raw);names=list(spec);idx={n:i for i,n in enumerate(names)}
weights=np.zeros((N,len(names)),dtype=np.float32)
x=np.abs(raw[:,0]);y=raw[:,1];z=raw[:,2]
lv=np.empty(len(mesh.data.loops),dtype=np.int32);mesh.data.loops.foreach_get('vertex_index',lv)
luv=np.empty(len(mesh.data.loops)*2,dtype=np.float32);mesh.data.uv_layers.active.data.foreach_get('uv',luv);luv=luv.reshape(-1,2)
vuv=np.zeros((N,2),dtype=np.float32);vuv[lv]=luv
shader=next(n for n in mesh.data.materials[0].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
texture=shader.inputs['Base Color'].links[0].from_node.image
pixels=np.empty(texture.size[0]*texture.size[1]*4,dtype=np.float32);texture.pixels.foreach_get(pixels);pixels=pixels.reshape(texture.size[1],texture.size[0],4)
rgb=pixels[(vuv[:,1]*texture.size[1]).astype(int)%texture.size[1],(vuv[:,0]*texture.size[0]).astype(int)%texture.size[0],:3]
armour=(rgb.min(axis=1)>.43)|((rgb[:,1]>.42)&(rgb[:,1]>rgb[:,0]*1.3))
def put(mask,n,w=1):weights[mask,idx[n]]=w
body=np.ones(N,dtype=bool)
head=z>.19;put(head,'DEF-head');body[head]=False
neck=(z>.15)&(x<.080)&body;put(neck,'DEF-neck');body[neck]=False
armmask=(x>np.where(z>.02,.121,np.where(z>-.06,.141,np.where(z>-.13,.163,.150))))&(z>-.244)&(z<.19)&body
for s,sgn in [('L',1),('R',-1)]:
    m=armmask&(raw[:,0]*sgn>0);body[m]=False
    upper=np.clip((z+.008+.011)/.022,0,1)
    hand=np.clip((-.126-z+.008)/.016,0,1)
    weights[m,idx['DEF-upper_arm.'+s]]=upper[m]
    weights[m,idx['DEF-forearm.'+s]]=(1-upper[m])*(1-hand[m])
    weights[m,idx['DEF-hand.'+s]]=(1-upper[m])*hand[m]
    # The long back-of-hand guard is a rigid extension of the forearm shell.
    guard=m&(x>.256)&(z>-.181)&(z<-.07)
    weights[guard]=0;put(guard,'DEF-forearm.'+s)
    digitmask=m&(((z<-.180)&(x<.256))|((x<.216)&(z<-.139)))
    ids=np.flatnonzero(digitmask);q=raw[ids]
    segments=[];ds=[];ts=[]
    for digit in ['index','middle','ring','pinky','thumb']:
        path=finger_paths[(s,digit)]
        for j in range(3):
            a=np.array(path[j]);b=np.array(path[j+1]);v=b-a
            t=np.clip(((q-a)@v)/(v@v),0,1)
            d=np.sum((q-(a+t[:,None]*v))**2,axis=1)
            segments.append((digit,j));ds.append(d);ts.append(t)
    ds=np.array(ds).T;nearest=ds.argmin(axis=1)
    # Restrict deformation to finger surfaces; proximal palm stays rigid.
    for k,(digit,j) in enumerate(segments):
        which=nearest==k;vi=ids[which]
        weights[vi]=0
        n=f'DEF-thumb.{j+1:02d}.{s}' if digit=='thumb' else f'DEF-f_{digit}.{j+1:02d}.{s}'
        t=ts[k][which]
        w=np.ones(len(vi),dtype=np.float32)
        if j==0:
            blend=np.clip((.30-t)/.30,0,1)*.65
            weights[vi,idx['DEF-hand.'+s]]=blend;w-=blend
        else:
            blend=np.clip((.25-t)/.25,0,1)*.5
            prev=f'DEF-thumb.{j:02d}.{s}' if digit=='thumb' else f'DEF-f_{digit}.{j:02d}.{s}'
            weights[vi,idx[prev]]=blend;w-=blend
        if j<2:
            blend=np.clip((t-.75)/.25,0,1)*.5
            nxt=f'DEF-thumb.{j+2:02d}.{s}' if digit=='thumb' else f'DEF-f_{digit}.{j+2:02d}.{s}'
            weights[vi,idx[nxt]]=blend;w-=blend
        weights[vi,idx[n]]=w
        # A continuous transition under the knuckle plate avoids freezing shiny
        # pixels in the middle of a finger. Texture brightness is not anatomy.
        if digit!='thumb':
            alpha=np.clip((-z[vi]-.188)/.019,0,1)
        else:
            alpha=np.clip((.218-x[vi])/.021,0,1)
        weights[vi]*=alpha[:,None]
        weights[vi,idx['DEF-hand.'+s]]+=1-alpha
for s,sgn in [('L',1),('R',-1)]:
    leg=body&(z<-.105)&(raw[:,0]*sgn>0)
    body[leg]=False
    shin=np.clip((-.274-z+.012)/.024,0,1)
    foot=np.clip((-.417-z+.008)/.016,0,1)
    weights[leg,idx['DEF-thigh.'+s]]=1-shin[leg]
    weights[leg,idx['DEF-shin.'+s]]=shin[leg]*(1-foot[leg])
    weights[leg,idx['DEF-foot.'+s]]=shin[leg]*foot[leg]
    toe=leg&(y<-.061)&(z<-.453)
    weights[toe]=0;put(toe,'DEF-toe.'+s)
hips=body&(z<-.035);put(hips,'DEF-hips');body[hips]=False
low=body&(z<.015);put(low,'DEF-spine.001');body[low]=False
mid=body&(z<.063);put(mid,'DEF-spine.002');body[mid]=False
put(body,'DEF-spine.003')
# The long front breastplate and belly V move as one hard shell.
frontplate=(x<np.interp(z,[-.12,-.03,.04,.16],[.023,.060,.107,.099]))&(y<-.052)&(z>-.119)&(z<.17)&(~armmask)
weights[frontplate]=0;put(frontplate,'DEF-spine.003')
assert np.allclose(weights.sum(axis=1),1,atol=1e-5)
# Quantise only the few joint blends for efficient vertex-group writes.
weights=np.round(weights*32)/32
weights/=weights.sum(axis=1,keepdims=True)
for n,k in idx.items():
    if n=='root':continue
    vg=mesh.vertex_groups.new(name=n)
    for w in np.unique(weights[:,k]):
        if w>0:vg.add(np.flatnonzero(weights[:,k]==w).tolist(),float(w),'REPLACE')
mesh.parent=rig
mod=mesh.modifiers.new('MIKO mechanical skin','ARMATURE');mod.object=rig

# Split triangles at mechanical boundaries. Every resulting shell is rigid, so
# cross-joint triangles cannot stretch into spikes when elbows or knees bend.
old=mesh.data
loopverts=np.empty(len(old.loops),dtype=np.int32);old.loops.foreach_get('vertex_index',loopverts)
assert len(old.loops)==len(old.polygons)*3
labels=weights.argmax(axis=1)
# Fingers remain a continuous skinned surface; only the larger armour sections
# are separated. The generated knuckle plates stay on the palm bone.
for s in ['L','R']:
    for n,k in idx.items():
        if n.endswith('.'+s) and ('f_' in n or 'thumb.' in n):labels[labels==k]=idx['DEF-hand.'+s]
# UV seams made the imported mesh appear to contain thousands of islands.
# Analyse welded topology without changing UVs. Keep each bone's main connected
# surface; absorb stray slivers into the surrounding mechanical section.
up,first,weld=np.unique(np.round(raw,6),axis=0,return_index=True,return_inverse=True)
wl=labels[first];edges=np.empty(len(old.edges)*2,dtype=np.int32);old.edges.foreach_get('vertices',edges);edges=weld[edges.reshape(-1,2)]
parents=np.arange(len(up))
def find(k):
    while parents[k]!=k:parents[k]=parents[parents[k]];k=parents[k]
    return k
for a,b in edges[wl[edges[:,0]]==wl[edges[:,1]]]:
    ra,rb=find(a),find(b)
    if ra!=rb:parents[rb]=ra
rootids=np.array([find(i) for i in range(len(up))])
rcount=np.bincount(rootids,minlength=len(up))
clean=np.full(len(up),-1,dtype=np.int32)
for label in np.unique(wl):
    members=np.flatnonzero(wl==label);main=members[np.argmax(rcount[rootids[members]])]
    keep=(rootids==rootids[main]);clean[keep]=label
orphan_count=int((clean<0).sum())
for iteration in range(300):
    a,b=edges[:,0],edges[:,1];la,lb=clean[a],clean[b]
    ab=(la<0)&(lb>=0);ba=(lb<0)&(la>=0)
    if not ab.any() and not ba.any():break
    clean[a[ab]]=lb[ab];clean[b[ba]]=la[ba]
clean[clean<0]=wl[clean<0]
labels=clean[weld]
print('ABSORBED_SLIVERS',orphan_count,'welded vertices',flush=True)
tri=labels[loopverts].reshape(-1,3)
face_labels=np.where((tri[:,0]==tri[:,1])|(tri[:,0]==tri[:,2]),tri[:,0],np.where(tri[:,1]==tri[:,2],tri[:,1],tri[:,0]))
looplabels=np.repeat(face_labels,3)
keys=loopverts.astype(np.int64)*len(names)+looplabels
unique,inverse=np.unique(keys,return_inverse=True)
original=(unique//len(names)).astype(np.int32);newlabels=(unique%len(names)).astype(np.int32)
uv=np.empty(len(old.loops)*2,dtype=np.float32);old.uv_layers.active.data.foreach_get('uv',uv)
normals=np.empty(len(old.vertices)*3,dtype=np.float32);old.vertices.foreach_get('normal',normals);normals=normals.reshape(-1,3)
new=bpy.data.meshes.new('MIKO7_Rigid_Mechanical_Shells')
new.vertices.add(len(unique));new.vertices.foreach_set('co',p[original].ravel())
new.loops.add(len(inverse));new.loops.foreach_set('vertex_index',inverse)
new.polygons.add(len(face_labels));new.polygons.foreach_set('loop_start',np.arange(0,len(inverse),3,dtype=np.int32));new.polygons.foreach_set('loop_total',np.full(len(face_labels),3,dtype=np.int32));new.polygons.foreach_set('use_smooth',np.ones(len(face_labels),dtype=bool))
for mat in old.materials:new.materials.append(mat)
new.uv_layers.new(name='UVMap');new.uv_layers.active.data.foreach_set('uv',uv)
new.update()
new.normals_split_custom_set_from_vertices(normals[original].tolist())
mesh.data=new;mesh.vertex_groups.clear()
for n,k in idx.items():
    vi=np.flatnonzero(newlabels==k)
    if len(vi):mesh.vertex_groups.new(name=n).add(vi.tolist(),1.0,'REPLACE')
for s in ['L','R']:
    vi=np.flatnonzero(newlabels==idx['DEF-hand.'+s]);orig=original[vi]
    handvg=mesh.vertex_groups.get('DEF-hand.'+s)
    if handvg:handvg.remove(vi.tolist())
    for n,k in idx.items():
        if n=='DEF-hand.'+s or (n.endswith('.'+s) and ('f_' in n or 'thumb.' in n)):
            wg=weights[orig,k].copy()
            # Coarse boundary cleanup may have moved a few forearm vertices into
            # the palm. Those vertices stay rigidly attached to the palm.
            if n=='DEF-hand.'+s:
                digitcols=[idx[a] for a in idx if a=='DEF-hand.'+s or (a.endswith('.'+s) and ('f_' in a or 'thumb.' in a))]
                wg+=1-weights[orig][:,digitcols].sum(axis=1)
            vg=mesh.vertex_groups.get(n) or mesh.vertex_groups.new(name=n)
            for w in np.unique(wg):
                if w>0:vg.add(vi[wg==w].tolist(),float(w),'REPLACE')
np.savez_compressed(os.path.join(BASE,'rigid_partition.npz'),original=original,labels=newlabels)
print('RIGID_SHELLS',len(unique),'vertices; no stretched triangles',flush=True)

# Hidden joint cores cover the cut surfaces while armour rotates around them.
joint_mat=bpy.data.materials.new('Internal graphite joint cores');joint_mat.use_nodes=True
bsdf=next(n for n in joint_mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bsdf.inputs['Base Color'].default_value=(.025,.033,.038,1);bsdf.inputs['Metallic'].default_value=.65;bsdf.inputs['Roughness'].default_value=.4
for s in ['L','R']:
    for part,radius in [('upper_arm',.023),('forearm',.019),('hand',.015),('thigh',.025),('shin',.022),('foot',.018)]:
        bn=f'DEF-{part}.{s}';point=arm.bones[bn].head_local
        bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=radius,location=point)
        o=bpy.context.object;o.name=f'JointCore_{part}.{s}';o.data.materials.append(joint_mat)
        for poly in o.data.polygons:poly.use_smooth=True
        # Object and armature coordinates coincide; vertex-group binding preserves rest position.
        vg=o.vertex_groups.new(name=bn);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        o.parent=rig;md=o.modifiers.new('Rigid joint core','ARMATURE');md.object=rig

# Simple grip properties drive the fitted finger chains, relative to their pre-curled rest pose.
for s in ['L','R']:
    ctrl=rig.pose.bones['CTRL-hand.'+s]
    for prop in ['Grip','Thumb','Index','Middle','Ring','Pinky']:
        ctrl[prop]=0.0;ctrl.id_properties_ui(prop).update(min=-1.0,max=1.0,soft_min=-1.0,soft_max=1.0,description='0 = original relaxed grip; negative opens, positive closes')
    for digit in ['thumb','index','middle','ring','pinky']:
        for j in range(3):
            n=f'DEF-thumb.{j+1:02d}.{s}' if digit=='thumb' else f'DEF-f_{digit}.{j+1:02d}.{s}'
            pb=rig.pose.bones[n];pb.rotation_mode='XYZ'
            fc=pb.driver_add('rotation_euler',0);d=fc.driver;d.type='SCRIPTED'
            for varname,prop in [('g','Grip'),('c',digit.title())]:
                v=d.variables.new();v.name=varname;v.type='SINGLE_PROP';v.targets[0].id=rig;v.targets[0].data_path=f'pose.bones["CTRL-hand.{s}"]["{prop}"]'
            # Local X is +world Y; the opposite side curls in the opposite direction.
            d.expression=f'max(-1,min(1,g+c))*{(.36 if s=="L" else -.36)*(0.65 if digit=="thumb" else 1)}'
    for part,end,pole in [('hand','forearm','elbow'),('foot','shin','knee')]:
        ctrl=rig.pose.bones[f'CTRL-{part}.{s}'];ctrl['IK']=0.0;ctrl.id_properties_ui('IK').update(min=0.0,max=1.0,description='0: FK / library animation; 1: move this control to pose the limb')
        c=rig.pose.bones[f'DEF-{end}.{s}'].constraints.new('IK');c.name='Optional IK';c.target=rig;c.subtarget=f'CTRL-{part}.{s}';c.chain_count=2
        c.pole_target=rig;c.pole_subtarget=f'CTRL-{pole}_pole.{s}';c.pole_angle=-math.pi/2
        fc=c.driver_add('influence');d=fc.driver;v=d.variables.new();v.name='ik';v.type='SINGLE_PROP';v.targets[0].id=rig;v.targets[0].data_path=f'pose.bones["CTRL-{part}.{s}"]["IK"]';d.expression='ik'

# Visible, selectable controls; hidden shape objects never render.
shape_col=bpy.data.collections.new('CONTROL_SHAPES');scene.collection.children.link(shape_col);shape_col.hide_render=True
def shape(name,r):
    verts=[(math.cos(i*math.tau/32)*r,0,math.sin(i*math.tau/32)*r) for i in range(32)]
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[(i,(i+1)%32) for i in range(32)],[])
    o=bpy.data.objects.new(name,me);shape_col.objects.link(o);o.hide_render=True;o.hide_set(True);return o
ring=shape('Wrist and foot control',.040);rootshape=shape('Root control',.30);small=shape('Pole control',.018)
for pb in rig.pose.bones:
    if pb.name.startswith('CTRL') or pb.name=='root':
        pb.custom_shape=rootshape if pb.name=='root' else small if 'pole' in pb.name else ring
        pb.use_custom_shape_bone_size=False

# Retarget global motion onto fitted lengths; arms use an explicit T-pose reference.
rig.animation_data_create()
refs={}
for n in spec:
    if n not in source.data.bones:continue
    tr=arm.bones[n].matrix_local.to_quaternion();sr=source.data.bones[n].matrix_local.to_quaternion()
    ref=tr
    if any(k in n for k in ['upper_arm','forearm','hand.','shoulder.']):
        td=(arm.bones[n].tail_local-arm.bones[n].head_local).normalized()
        sd=(source.data.bones[n].tail_local-source.data.bones[n].head_local).normalized()
        ref=td.rotation_difference(sd)@tr
    refs[n]=sr.inverted()@ref
clipnames=['Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Sprint_Loop','Jump_Start','Jump_Loop','Jump_Land','Pistol_Idle_Loop','Pistol_Shoot','Interact']
animated=[n for n in spec if n in refs and 'f_' not in n and 'thumb.' not in n]
source.animation_data_create();source.hide_set(False)
clip_summary=[]
for clip in clipnames:
    sa=source_actions[clip];source.animation_data.action=sa
    if source.animation_data.action_slot is None:source.animation_data.action_slot=sa.slots[0]
    action=bpy.data.actions.new('MIKO7_'+clip);action.use_fake_user=True;rig.animation_data.action=action
    end=int(round(sa.frame_range[1]));start=int(round(sa.frame_range[0]))
    previous={}
    for f in range(start,end+1):
        scene.frame_set(f);bpy.context.view_layer.update()
        for n in animated:
            pb=rig.pose.bones[n];sb=source.pose.bones[n]
            rot=sb.matrix.to_quaternion()@refs[n]
            if n=='root':head=arm.bones[n].head_local+(sb.matrix.translation-source.data.bones[n].head_local)*.43
            elif n=='DEF-hips':
                delta=(sb.matrix.translation-source.data.bones[n].head_local)*.43
                head=arm.bones[n].head_local+delta
            else:
                pa=pb.parent
                head=pa.matrix@(pa.bone.matrix_local.inverted()@pb.bone.head_local)
            mat=rot.to_matrix().to_4x4();mat.translation=head;pb.matrix=mat
            q=pb.rotation_quaternion.copy()
            if n in previous:q.make_compatible(previous[n]);pb.rotation_quaternion=q
            previous[n]=q.copy()
            pb.keyframe_insert(data_path='rotation_quaternion',frame=f-start+1,group=n)
            if n in ['root','DEF-hips']:pb.keyframe_insert(data_path='location',frame=f-start+1,group=n)
    clip_summary.append({'action':action.name,'frames':end-start+1,'fps':30})
    print('RETARGETED',action.name,flush=True)
source.hide_set(True)
# Keep original reference actions with the reference rig, out of the export selection.
rig.animation_data.action=None
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
scene.frame_set(1)
rig['About']='MIKO7 fitted humanoid rig. Quaternius hierarchy; FK + optional IK; grip controls on CTRL-hand.L/R.'
rig['Animation_source']='Quaternius Universal Animation Library, Standard CC0 (OpenGameArt distribution).'
rig['Forward']='-Y; Z up. Source mesh preserved; grounded at Z=0.'
rig['Finger_note']='Generated fingers are already curved. Grip is relative to this sculpt; use modest values. Library finger channels are deliberately excluded.'
rig['Retarget_note']='Arms retarget through a T-pose reference. New libraries require a bone map and rest-pose conversion; naming alone does not retarget.'
rig['Mesh_note']='High detail sprite-rendering master, not a low-poly runtime mesh.'

# Orthographic review studio, shared by all motion checks.
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
world=bpy.data.worlds.new('MIKO Studio');world.use_nodes=True;scene.world=world
bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[0].default_value=(.065,.075,.09,1);bg.inputs[1].default_value=.5
for name,loc,power,size in [('Key',(-1.5,-2.5,2.8),100,2),('Fill',(2,-1,1.5),60,2),('Rim',(0,2,2.3),120,1.5)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.size=size;aim(o,(0,0,.55))
bpy.ops.object.camera_add(location=(1.8,-3.5,1.25));cam=bpy.context.object;cam.name='MIKO7_PreviewCamera';cam.data.type='ORTHO';cam.data.ortho_scale=1.22;aim(cam,(0,0,.51));scene.camera=cam
try:scene.render.engine='CYCLES'
except TypeError:pass
scene.cycles.samples=16
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.render.film_transparent=True
scene.frame_start=1;scene.frame_end=75
for o in bpy.context.selected_objects:o.select_set(False)
rig.select_set(True);bpy.context.view_layer.objects.active=rig
for a in bpy.context.screen.areas:
    if a.type=='VIEW_3D':
        a.spaces.active.region_3d.view_rotation=Quaternion((1,0,0),math.pi/2)
        a.spaces.active.region_3d.view_location=Vector((0,0,.51));a.spaces.active.region_3d.view_distance=1.8
        a.spaces.active.shading.type='MATERIAL'
# Pack images so the master is portable.
bpy.ops.file.pack_all()
out=os.path.join(BASE,'MIKO7_Rigged_v1.blend')
bpy.ops.wm.save_as_mainfile(filepath=out)
report={'vertices':N,'triangles':len(mesh.data.polygons),'deform_bones':sum(b.use_deform for b in arm.bones),'total_bones':len(arm.bones),'unweighted_vertices':int((weights.sum(axis=1)==0).sum()),'max_weight_error':float(abs(weights.sum(axis=1)-1).max()),'source_height':float(raw[:,2].max()-raw[:,2].min()),'clips':clip_summary}
with open(os.path.join(QA,'rig_validation.json'),'w') as f:json.dump(report,f,indent=2)
print('SAVED',out,report,flush=True)
