# Historical decimation trial; production builder is build_clean_crate.py.
import bpy,os,json
from mathutils import Vector
B=os.path.dirname(os.path.abspath(__file__))
G=os.path.abspath(B+'/../../../Game/models/props')
os.makedirs(G,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=B+'/source.glb')
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
centre=(lo+hi)/2;factor=.8/max(hi-lo)
report={'before':0,'after':0,'size':.8}
for o in objects:
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 # Bake object basis first, then normalize around its source world centre.
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 for v in o.data.vertices:v.co=(v.co+o.location-centre)*factor
 o.location=Vector((0,0,0))
 before=sum(len(p.vertices)-2 for p in o.data.polygons);report['before']+=before
 bpy.ops.object.mode_set(mode='EDIT')
 bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.mesh.remove_doubles(threshold=.0001)
 bpy.ops.mesh.delete_loose()
 bpy.ops.object.mode_set(mode='OBJECT')
 d=o.modifiers.new('Gameplay_5k','DECIMATE');d.ratio=min(1.0,5000/before);d.use_collapse_triangulate=True
 bpy.ops.object.modifier_apply(modifier=d.name)
 report['after']+=sum(len(p.vertices)-2 for p in o.data.polygons)
 o.name='MetalCrate'
assert report['after']<6000,report
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=B+'/decimation_trial.glb',use_selection=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MetalCrate_DecimationTrial.blend')
json.dump(report,open(B+'/decimation_trial.json','w'),indent=2)
print('CRATE_GAME_READY',report,flush=True)
