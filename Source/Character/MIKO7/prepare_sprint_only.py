import bpy,os,json,math
from mathutils import Quaternion,Vector
BASE=os.path.dirname(os.path.abspath(__file__));QA=os.path.abspath(os.path.join(BASE,'../../../Builds/Validation/MIKO7/v2'))
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'MIKO7_Rigged_v2.blend'))
scene=bpy.context.scene;rig=bpy.data.objects['MIKO7_RIG'];source=bpy.data.objects['SOURCE_Quaternius']
rig.animation_data.action=None;source.animation_data.action=None
for a in list(bpy.data.actions):
    if a.name!='MIKO7_Sprint_Loop':bpy.data.actions.remove(a)
a=bpy.data.actions['MIKO7_Sprint_Loop']
for layer in a.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for fc in bag.fcurves:
                first=min(fc.keyframe_points,key=lambda k:k.co.x);last=max(fc.keyframe_points,key=lambda k:k.co.x)
                last.co.y=first.co.y
                for k in fc.keyframe_points:k.interpolation='LINEAR'
                fc.update()
rig.animation_data.action=a
scene.frame_start=1;scene.frame_end=20;scene.frame_set(1);bpy.context.view_layer.update()
rig['About']='MIKO7 Sprint repair check. One corrected clip only. Other motions deliberately excluded.'
text=bpy.data.texts['MIKO Controls.py'];text.clear();text.write(open(os.path.join(BASE,'miko_controls.py'),encoding='utf-8').read())
notes=bpy.data.texts['READ ME • MIKO7'];notes.clear();notes.write('SPRINT CHECK — one corrected clip only\n\nPress Space to play / pause.\nFrames 1–20 contain one cycle. Frame 21 is the matching endpoint, excluded from playback to avoid a repeated frame.\nThe MIKO sidebar is loaded by Open MIKO7.cmd.\nThe original v1 is retained separately.\n')
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            sp=area.spaces.active;sp.region_3d.view_location=Vector((0,0,.51));sp.region_3d.view_distance=1.65;sp.region_3d.view_rotation=Quaternion((1,0,0),math.pi/2)
            sp.overlay.show_floor=False;sp.overlay.show_extras=False
            if hasattr(sp.overlay,'show_bones'):sp.overlay.show_bones=False
            sp.shading.type='MATERIAL'
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.cycles.samples=16
out=os.path.join(BASE,'MIKO7_Sprint_Check.blend');bpy.ops.wm.save_as_mainfile(filepath=out)
# Endpoint and frame-history check, including jumping backward into the first frames.
poses={};maxdiff=0.;maxscale=0.
for f in list(range(1,22))+[1,3,2,20,1,2,3]:
    scene.frame_set(f);bpy.context.view_layer.update()
    for p in rig.pose.bones:
        if not p.bone.use_deform:continue
        m=p.matrix.copy();key=(f,p.name)
        if key in poses:maxdiff=max(maxdiff,max(abs(m[r][c]-poses[key][r][c]) for r in range(4) for c in range(4)))
        poses[key]=m
        maxscale=max(maxscale,max(abs(v-1) for v in m.to_scale()))
looperror=max(max(abs(poses[(1,p.name)][r][c]-poses[(21,p.name)][r][c]) for r in range(4) for c in range(4)) for p in rig.pose.bones if p.bone.use_deform)
assert maxdiff<1e-5 and looperror<1e-5 and maxscale<1e-4
report={'clip_count':1,'playback_frames':[1,20],'endpoint':21,'frame_history_error':maxdiff,'loop_matrix_error':looperror,'maximum_scale_error':maxscale}
with open(os.path.join(QA,'sprint_final_validation.json'),'w') as f:json.dump(report,f,indent=2)
print('SPRINT_CHECK',report,flush=True)
scene.frame_set(1)
# Export this one clip only; preserve the ready-to-play blend above.
rig.animation_data.action=None
t=rig.animation_data.nla_tracks.new();t.name='MIKO7_Sprint_Loop';s=t.strips.new(a.name,1,a)
if hasattr(s,'action_slot'):s.action_slot=a.slots[0]
for o in scene.objects:o.select_set(o==rig or (o.type=='MESH' and o.parent==rig))
bpy.context.view_layer.objects.active=rig
props=bpy.ops.export_scene.gltf.get_rna_type().properties
options={'filepath':os.path.join(BASE,'MIKO7_Sprint_Check.glb'),'use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_skins':True,'export_def_bones':True,'export_force_sampling':True,'export_morph':False}
bpy.ops.export_scene.gltf(**{k:v for k,v in options.items() if k in props})
print('SPRINT_EXPORTED',flush=True)
