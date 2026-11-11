import bpy,numpy as np,os,math,json,struct
from mathutils import Matrix,Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7'))
path=os.path.join(BASE,'MIKO7_Rigged_v1.blend');bpy.ops.wm.open_mainfile(filepath=path)
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG']
# Calibrate pole angles against the fitted rest joints with meshes disabled.
mods=[m for o in scene.objects if o.type=='MESH' for m in o.modifiers if m.type=='ARMATURE']
for m in mods:m.show_viewport=False
ik_results={}
for s in ['L','R']:
    for part,lower in [('hand','forearm'),('foot','shin')]:
        ctrl=rig.pose.bones[f'CTRL-{part}.{s}'];pb=rig.pose.bones[f'DEF-{lower}.{s}'];c=pb.constraints['Optional IK']
        target=pb.bone.head_local.copy();ctrl['IK']=1.;rig.update_tag();bpy.context.view_layer.update()
        scores=[]
        for angle in np.linspace(-math.pi,math.pi,73):
            c.pole_angle=float(angle);bpy.context.view_layer.update()
            scores.append(((pb.head-target).length,float(angle)))
        err,angle=min(scores);c.pole_angle=angle;bpy.context.view_layer.update()
        tiperr=(pb.tail-rig.pose.bones[f'CTRL-{part}.{s}'].head).length
        ik_results[f'{part}.{s}']={'pole_angle':angle,'rest_joint_error':err,'target_error':tiperr}
        ctrl['IK']=0.;rig.update_tag();bpy.context.view_layer.update()
for m in mods:m.show_viewport=True
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
scene.frame_set(1);bpy.context.view_layer.update()
# Real weight validation on every exported mesh, not the provisional arrays.
validation={'meshes':{},'ik':ik_results}
for o in scene.objects:
    if o.type!='MESH' or o.parent!=rig:continue
    sums=np.zeros(len(o.data.vertices));missing=0
    defids={g.index for g in o.vertex_groups if g.name in rig.data.bones and rig.data.bones[g.name].use_deform}
    for v in o.data.vertices:sums[v.index]=sum(g.weight for g in v.groups if g.group in defids)
    validation['meshes'][o.name]={'vertices':len(sums),'unweighted':int((sums<.001).sum()),'weight_error':float(abs(sums-1).max())}
    assert sums.min()>.999 and sums.max()<1.001,(o.name,sums.min(),sums.max())
validation['deform_bones']=sum(b.use_deform for b in rig.data.bones)
validation['animations']=[a.name for a in bpy.data.actions if a.name.startswith('MIKO7_')]
text=bpy.data.texts.get('MIKO Controls.py') or bpy.data.texts.new('MIKO Controls.py')
text.clear();text.write(open(os.path.join(BASE,'miko_controls.py'),encoding='utf-8').read())
rig['Skinning']='Rigid mechanical shells; continuous weighted fingers. Internal graphite joint cores.'
rig['Controls']='Open MIKO7.cmd loads the MIKO sidebar. Alternatively run the MIKO Controls.py text in this file.'
notes=bpy.data.texts.get('READ ME • MIKO7') or bpy.data.texts.new('READ ME • MIKO7')
notes.clear();notes.write('MIKO7 RIG\n\nOpen MIKO7.cmd for the easy MIKO sidebar (N key).\nGrip 0 is the original curved hand; negative opens and positive closes.\nTen Quaternius CC0 test clips are in the action library.\nRest pose resets sliders, FK, IK and the active animation.\nThe original mesh is preserved in miko7_source.glb.\nHigh-detail rendering master; use sprite renders or optimise separately for real-time.\nRetargeting new packs needs a bone map and rest-pose conversion.\nSee README.md beside this blend for limitations and rebuild instructions.\n')
# Store a clean rest pose; animation selection is done in the MIKO sidebar.
for o in bpy.context.selected_objects:o.select_set(False)
rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=path)
with open(os.path.join(QA,'final_validation.json'),'w') as f:json.dump(validation,f,indent=2)
print('FINAL_VALIDATION',json.dumps(validation),flush=True)
# Export only MIKO and its skin; reference mannequin and studio are excluded.
for o in scene.objects:o.select_set(False)
rig.select_set(True)
for o in scene.objects:
    if o.type=='MESH' and o.parent==rig:o.select_set(True)
tracks=[]
for a in bpy.data.actions:
    if not a.name.startswith('MIKO7_'):continue
    t=rig.animation_data.nla_tracks.new();t.name=a.name
    strip=t.strips.new(a.name,int(a.frame_range[0]),a)
    if hasattr(strip,'action_slot') and a.slots:strip.action_slot=a.slots[0]
    tracks.append(t)
props=bpy.ops.export_scene.gltf.get_rna_type().properties
options={'filepath':os.path.join(BASE,'MIKO7_Rigged_v1.glb'),'use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_skins':True,'export_def_bones':True,'export_force_sampling':True,'export_current_frame':False,'export_morph':False}
options={k:v for k,v in options.items() if k in props}
bpy.ops.export_scene.gltf(**options)
with open(options['filepath'],'rb') as f:
    header=f.read(12);size,kind=struct.unpack('<II',f.read(8));doc=json.loads(f.read(size))
print('GLB_ANIMATIONS',[a['name'] for a in doc.get('animations',[])],flush=True)
assert len(doc.get('animations',[]))==len(tracks)
assert len(doc.get('skins',[]))>0
with open(os.path.join(QA,'glb_validation.json'),'w') as f:json.dump({'animations':[a['name'] for a in doc['animations']],'skin_count':len(doc['skins']),'mesh_count':len(doc['meshes']),'embedded_images':len(doc.get('images',[])),'bytes':os.path.getsize(options['filepath'])},f,indent=2)
print('EXPORTED',options['filepath'],flush=True)
