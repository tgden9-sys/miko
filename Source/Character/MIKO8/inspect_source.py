import bpy,os,json,math
from mathutils import Vector
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8');os.makedirs(Q,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=B+'/MIKO8_source.glb')
sc=bpy.context.scene
for o in sc.objects:
 print('MODEL',o.name,o.type,list(o.dimensions),list(o.rotation_euler),list(o.location),len(o.data.vertices) if o.type=='MESH' else '')
pts=[o.matrix_world@Vector(c) for o in sc.objects if o.type=='MESH' for c in o.bound_box]
lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)));center=(lo+hi)/2
print('BOUNDS',list(lo),list(hi))
sc.render.engine='CYCLES';sc.cycles.samples=12;sc.render.resolution_x=700;sc.render.resolution_y=800;sc.render.resolution_percentage=100
sc.world=bpy.data.worlds.new('World');sc.world.use_nodes=True;sc.world.node_tree.nodes.get('Background').inputs[0].default_value=(.17,.17,.17,1)
for pos,power,size in [((3,-4,5),450,4),((-3,-1,3),300,3),((1,3,4),500,3)]:
 d=bpy.data.lights.new('Softbox','AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new('Softbox',d);sc.collection.objects.link(o);o.location=pos;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Review');cam=bpy.data.objects.new('Review',d);sc.collection.objects.link(cam);sc.camera=cam;d.type='ORTHO';d.ortho_scale=max(hi-lo)*1.18
for label,direction in [('front',(0,-4,0)),('side',(4,0,0)),('back',(0,4,0))]:
 cam.location=center+Vector(direction)*max(hi-lo);cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=Q+'/source_'+label+'.png';bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MIKO8_inspection.blend')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.abspath(B+'/../MIKO7/Quaternius/Animation Library[Standard]/Godot/AnimationLibrary_Godot_Standard.glb'))
for o in bpy.context.scene.objects:
 print('SOURCE',o.name,o.type,list(o.dimensions))
 if o.type=='ARMATURE':
  json.dump({'object':o.name,'matrix':[list(row) for row in o.matrix_world],'bones':[{ 'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(b.head_local),'tail':list(b.tail_local),'matrix':[list(row) for row in b.matrix_local]} for b in o.data.bones]},open(Q+'/source_skeleton.json','w'),indent=2)
print('ACTIONS',[(a.name,list(a.frame_range)) for a in bpy.data.actions])
