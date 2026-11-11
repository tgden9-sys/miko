import bpy,os,json,math
from mathutils import Vector
BASE=os.path.dirname(os.path.abspath(__file__))+'/Props/MetalCrate'
os.makedirs(BASE,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=BASE+'/source.glb')
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
report={'bounds':[list(lo),list(hi)],'objects':[{'name':o.name,'vertices':len(o.data.vertices),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'materials':[m.name for m in o.data.materials]} for o in meshes]}
print('CRATE_SOURCE',json.dumps(report),flush=True)
centre=(lo+hi)/2;scale=2.0/max(hi-lo)
for o in meshes:o.location=(o.location-centre)*scale;o.scale*=scale
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=20
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(0.32,0.37,0.45,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for at,power,size in [((3,-4,5),500,4),((-3,-1,2),220,3)]:
 bpy.ops.object.light_add(type='AREA',location=at);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(3,-4,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.5;scene.camera=cam
scene.render.resolution_x=900;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=BASE+'/source_preview.png'
scene.view_settings.view_transform='Standard'
bpy.ops.render.render(write_still=True)
json.dump(report,open(BASE+'/inspection.json','w'),indent=2)
