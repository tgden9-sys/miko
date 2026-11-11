"""Non-destructive gameplay mesh reduction; canonical rig/actions stay unchanged."""
import bpy, os, json, math, sys
from mathutils import Matrix
fast = '--fast' in sys.argv
mesh_ratio = .03 if fast else .08
asset_name = 'MIKO8_FastLOD' if fast else 'MIKO8_GameLOD'
B=os.path.dirname(os.path.abspath(__file__))
G=os.path.abspath(B+'/../../../Game/models/miko8')
Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8/reactions')
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_Actions_Animated.blend')
rig=bpy.data.objects['MIKO8_Rig'];mesh=bpy.data.objects['MIKO8_Mesh']
rig.animation_data.action=None
for t in rig.animation_data.nla_tracks:t.mute=True
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
before={'vertices':len(mesh.data.vertices),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons)}
for o in bpy.context.scene.objects:o.select_set(False)
mesh.select_set(True);bpy.context.view_layer.objects.active=mesh
modifier=mesh.modifiers.new('Gameplay reduction','DECIMATE')
modifier.ratio=mesh_ratio;modifier.use_collapse_triangulate=True
# Reduce bind-pose topology before skin deformation, never bake the armature.
while list(mesh.modifiers).index(modifier)>0:bpy.ops.object.modifier_move_up(modifier=modifier.name)
bpy.ops.object.modifier_apply(modifier=modifier.name)
after={'vertices':len(mesh.data.vertices),'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons)}
assert after['triangles']<before['triangles']*.10
assert len(mesh.data.uv_layers)>0
assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers)
unweighted=sum(1 for v in mesh.data.vertices if not any(g.weight>0 for g in v.groups))
assert unweighted==0,unweighted
for v in mesh.data.vertices:
 assert all(math.isfinite(c) for c in v.co)
 assert all(math.isfinite(g.weight) and g.weight>=0 for g in v.groups)
for t in rig.animation_data.nla_tracks:t.mute=False
rig.animation_data.action=None
for o in bpy.context.scene.objects:o.select_set(o in [rig,mesh])
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=G+'/'+asset_name+'.glb',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_morph=False)
for t in rig.animation_data.nla_tracks:t.mute=True
rig.animation_data.action=bpy.data.actions['MIKO8_Idle']
rig.animation_data.action_slot=rig.animation_data.action.slots[0]
bpy.context.scene.frame_set(0)
if not fast: bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_GameLOD.blend')
report={'before':before,'after':after,'bone_count':len(rig.data.bones),'unweighted_vertices':unweighted,'policy':'Only bind-pose topology reduced; same UVs, weights, 53-bone rig and base animation actions; original master untouched.'}
json.dump(report,open(Q+('/fast_lod_build.json' if fast else '/game_lod_build.json'),'w'),indent=2)
print('GAME_LOD_READY',report,flush=True)
