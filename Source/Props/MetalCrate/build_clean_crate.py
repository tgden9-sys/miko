"""Clean hard-surface game topology, with source appearance baked to a new UV atlas."""
import bpy,os,json,itertools
from mathutils import Vector,Matrix
B=os.path.dirname(os.path.abspath(__file__));G=os.path.abspath(B+'/../../../Game/models/props')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=B+'/source.glb')
sources=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[o.matrix_world@Vector(v) for o in sources for v in o.bound_box]
lo=Vector(tuple(min(v[i] for v in points) for i in range(3)));hi=Vector(tuple(max(v[i] for v in points) for i in range(3)))
centre=(lo+hi)/2;factor=.8/max(hi-lo)
for o in sources:
 matrix=o.matrix_world.copy()
 for v in o.data.vertices:v.co=(matrix@v.co-centre)*factor
 o.parent=None;o.matrix_world=Matrix.Identity(4);o.data.update()
mat=bpy.data.materials.new('Crate_Baked');mat.use_nodes=True
mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.82
mat.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value=.3
guard_mat=bpy.data.materials.new('Corner_Guards');guard_mat.use_nodes=True
guard_mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.70,.71,.65,1)
guard_mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8
guard_mat.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value=.3
parts=[]
def part(name,at,size,width,segments=2):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bevel=o.modifiers.new('Machined edges','BEVEL');bevel.width=width;bevel.segments=segments;bevel.harden_normals=True
 bpy.ops.object.modifier_apply(modifier=bevel.name)
 for p in o.data.polygons:p.use_smooth=True
 normal=o.modifiers.new('Face normals','WEIGHTED_NORMAL');normal.keep_sharp=True;normal.weight=50
 bpy.ops.object.modifier_apply(modifier=normal.name)
 o.data.materials.append(guard_mat if name=='Corner guard' else mat);parts.append(o)
for axis in range(3):
 others=[i for i in range(3) if i!=axis]
 for sign in [-1,1]:
  at=[0,0,0];at[axis]=sign*.36;size=[.63,.63,.63];size[axis]=.035
  part('Inset panel',at,size,.014,3)
  for cross in others:
   along=next(i for i in others if i!=cross)
   for side in [-1,1]:
    at=[0,0,0];at[axis]=sign*.365;at[cross]=side*.35
    size=[.08,.08,.08];size[axis]=.06;size[along]=.68
    part('Frame rail',at,size,.012,2)
for signs in itertools.product([-1,1],repeat=3):part('Corner guard',[s*.33 for s in signs],[.14]*3,.022,3)
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();target=bpy.context.object;target.name='MetalCrate'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.15192,island_margin=.018);bpy.ops.object.mode_set(mode='OBJECT')
image=bpy.data.images.new('Crate_Albedo',2048,2048,alpha=False)
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;mat.node_tree.nodes.active=tex
for other in target.data.materials:
 if other!=mat:
  node=other.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;other.node_tree.nodes.active=node
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
bake=scene.render.bake;bake.use_selected_to_active=True;bake.cage_extrusion=.06;bake.max_ray_distance=.16;bake.margin=12
bake.use_pass_direct=False;bake.use_pass_indirect=False;bake.use_pass_color=True
bpy.ops.object.select_all(action='DESELECT')
for o in sources:o.select_set(True)
target.select_set(True);bpy.context.view_layer.objects.active=target
bpy.ops.object.bake(type='DIFFUSE')
image.filepath_raw=B+'/crate_albedo.png';image.file_format='PNG';image.save();image.pack()
mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
slot_mat=bpy.data.materials.new('Guard_Slots');slot_mat.use_nodes=True
slot_mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.025,.032,.038,1)
slot_mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.95
slots=[]
for signs in itertools.product([-1,1],repeat=3):
 for axis in range(3):
  others=[i for i in range(3) if i!=axis];at=Vector([s*.33 for s in signs]);at[axis]=signs[axis]*.4006
  u=Vector((0,0,0));v=u.copy();u[others[0]]=.021;v[others[1]]=.008
  vertices=[at-u-v,at+u-v,at+u+v,at-u+v]
  face=[0,1,2,3] if u.cross(v)[axis]*signs[axis]>0 else [3,2,1,0]
  data=bpy.data.meshes.new('Slot');data.from_pydata(vertices,[],[face]);data.materials.append(slot_mat)
  obj=bpy.data.objects.new('Slot',data);bpy.context.collection.objects.link(obj);slots.append(obj)
bpy.ops.object.select_all(action='DESELECT');target.select_set(True)
for obj in slots:obj.select_set(True)
bpy.context.view_layer.objects.active=target;bpy.ops.object.join()
for o in sources:o.hide_render=True;o.hide_set(True)
bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
triangles=sum(len(p.vertices)-2 for p in target.data.polygons)
assert triangles<6000,triangles
bpy.ops.export_scene.gltf(filepath=G+'/metal_crate.glb',use_selection=True,export_animations=False)
bpy.ops.wm.save_as_mainfile(filepath=B+'/MetalCrate_Game.blend')
json.dump({'source_triangles':989231,'game_triangles':triangles,'size':.8,'method':'Clean bevelled panels/frame/corner guards; source diffuse colour baked to 2048 atlas.'},open(B+'/game_asset.json','w'),indent=2)
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.37,.45,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for at,power,size in [((1.5,-2,3),180,2),((-2,-1,1.3),90,2)]:
 bpy.ops.object.light_add(type='AREA',location=at);light=bpy.context.object;light.data.energy=power;light.data.size=size;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(1.5,-2,1.3));cam=bpy.context.object;cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=1.4;scene.camera=cam
scene.cycles.samples=20;scene.render.resolution_x=800;scene.render.resolution_y=800;scene.render.resolution_percentage=100;scene.render.filepath=B+'/retopo_preview.png';scene.view_settings.view_transform='Standard'
bpy.ops.render.render(write_still=True)
print('CLEAN_CRATE_READY',triangles,flush=True)
