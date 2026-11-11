import bpy, math, json
from mathutils.bvhtree import BVHTree
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parent
out=root.parents[2]/'Game'/'models'/'environment'/'ortho_test'
out.mkdir(parents=True,exist_ok=True)
groups={'concrete':[],'bridge':[],'connector':[]}
for o in bpy.data.collections['A_ConcreteWalkway'].objects:
 if o.type in {'MESH','CURVE'}:groups['concrete'].append(o)
for o in bpy.data.collections['B_SteelBridge'].objects:
 if o.name.startswith(('Level bridge deck','Bridge non slip deck panels','Raised grip strip')):continue
 if o.type in {'MESH','CURVE'}:groups['bridge'].append(o)
for o in bpy.data.collections['Shared_AbutmentAndLight'].objects:
 if o.type not in {'MESH','CURVE'}:continue
 name=o.name
 if name.startswith('Opposite end'):continue
 if name.startswith('Continuous level rear rail'):
  groups['concrete' if o.location.x<0 else 'bridge'].append(o)
 elif name.startswith(('Rail post foot','Rail anchor bolt','Railing upright','Railing T collar')):
  post=round(o.location.x/2)*2
  if post in [-4,-2]:groups['concrete'].append(o)
  elif post in [2,4]:groups['bridge'].append(o)
  elif post==0:groups['connector'].append(o)
 else:groups['connector'].append(o)
# A common bare facade supports interchangeable service assemblies.
remove_services=('Utility pipe','Pipe collar','Flange bolt','Service junction box','Box inset','Box screw','Bent electrical conduit','Concrete structural rib','Recessed maintenance light housing','Protected light glass')
groups['concrete_clean']=[o for o in groups['concrete'] if not o.name.startswith(remove_services)]
# The runtime supplies shared weathering shaders. GLB keeps sensible base colours.
for m in bpy.data.materials:
 if not m.use_nodes:continue
 p=m.node_tree.nodes.get('Principled BSDF')
 ramps=[n for n in m.node_tree.nodes if n.type=='VALTORGB']
 if p and ramps:
  a=ramps[0].color_ramp.elements[0].color;b=ramps[0].color_ramp.elements[-1].color
  p.inputs['Base Color'].default_value=tuple((a[i]+b[i])/2 for i in range(4))
  for link in list(p.inputs['Base Color'].links):m.node_tree.links.remove(link)
stats={}
for name,objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 copies=[]
 for source in objects:
  obj=source.copy();obj.data=source.data.copy();bpy.context.scene.collection.objects.link(obj)
  obj.select_set(True);copies.append(obj)
 bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.object.convert(target='MESH')
 bpy.ops.object.join();obj=bpy.context.object;obj.name='Ortho_'+name
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 # Apply world transform so every reusable module has an explicit local origin.
 transform=obj.matrix_world.copy()
 for vertex in obj.data.vertices:
  vertex.co=transform@vertex.co
  if name.startswith('concrete'):vertex.co.x+=6
 obj.matrix_world.identity()
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 if name=='bridge':
  # Bake actual local occlusion into the shared mesh once, with no runtime AO pass.
  mesh=obj.data;mesh.update()
  bvh=BVHTree.FromPolygons([v.co for v in mesh.vertices],[p.vertices[:] for p in mesh.polygons],all_triangles=False)
  values=[]
  for vertex in mesh.vertices:
   normal=vertex.normal.normalized()
   helper=Vector((0,0,1)) if abs(normal.z)<.9 else Vector((0,1,0))
   tangent=normal.cross(helper).normalized();bitangent=normal.cross(tangent)
   hits=0.0
   for sample in range(12):
    radius=math.sqrt((sample+.5)/12);angle=sample*2.39996323
    direction=tangent*(radius*math.cos(angle))+bitangent*(radius*math.sin(angle))+normal*math.sqrt(1-radius*radius)
    hit=bvh.ray_cast(vertex.co+normal*.004,direction,.65)
    if hit[0] is not None:hits+=1.0-hit[3]/.65*.35
   ao=max(.22,1-hits/12*.85)
   values.append(ao)
  for attribute in list(mesh.color_attributes):mesh.color_attributes.remove(attribute)
  colour=mesh.color_attributes.new(name='BridgeSurfaceDetail',type='FLOAT_COLOR',domain='CORNER')
  for index,loop in enumerate(mesh.loops):
   n=mesh.corner_normals[index].vector
   bevel=1.0 if .55<max(abs(n.x),abs(n.y),abs(n.z))<.985 else 0.0
   colour.data[index].color=(values[loop.vertex_index],bevel,0,1)
  mesh.color_attributes.active_color=colour
  mesh.color_attributes.render_color_index=0
  print('BRIDGE_AO_BAKED',len(mesh.vertices),flush=True)
 # UVs are unnecessary: preview shader uses object-space triplanar wear.
 triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
 stats[name]={'triangles':triangles,'objects_combined':len(objects),'materials':len(obj.data.materials)}
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),use_selection=True,export_animations=False,export_vertex_color='ACTIVE',export_all_vertex_colors=False)
 bpy.data.objects.remove(obj,do_unlink=True)
json.dump(stats,open(root/'runtime_geometry.json','w'),indent=2)
print('PREVIEW_EXPORT_READY',stats,flush=True)
