import bpy,json,bmesh
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;R=P.parents[2]
bpy.ops.wm.open_mainfile(filepath=str(P/'source.blend'))
o=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=o;o.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
zs=sorted(v.co.z for v in o.data.vertices)
print('BASE_PROFILE',[(p,zs[int((len(zs)-1)*p)]) for p in [0,.001,.01,.03,.05,.1,.2,.5,.95,1]])
bm=bmesh.new();bm.from_mesh(o.data)
cut=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,.0927),plane_no=(0,0,1),clear_inner=True)
edges=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-.0927)<.0001 for v in e.verts)]
bmesh.ops.holes_fill(bm,edges=edges,sides=0);bm.to_mesh(o.data);bm.free()
for v in o.data.vertices:v.co.z-=.0927
mod=o.modifiers.new('Game detail','DECIMATE');mod.ratio=.2;bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(R/'Game/models/environment/ladder_building/ladder_building.glb'),use_selection=True,export_format='GLB')
from mathutils.bvhtree import BVHTree
tree=BVHTree.FromPolygons([v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons])
for y in [-.6,-.3,0,.3,.6]:
 print('FOOTPRINT',y,''.join('#' if tree.ray_cast(Vector((x,y,.5)),Vector((0,0,-1)))[0] else '.' for x in [-.85,-.6,-.3,0,.3,.6,.85]))
bpy.ops.wm.save_as_mainfile(filepath=str(P/'cleaned.blend'))
sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1100;sc.render.resolution_y=800;sc.render.resolution_percentage=100
sc.display.shading.color_type='MATERIAL';sc.display.shading.show_cavity=True
bpy.ops.object.camera_add(location=(3,4,2.5));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.8;sc.camera=cam
sc.render.filepath=str(P/'inspection.png');bpy.ops.render.render(write_still=True)
