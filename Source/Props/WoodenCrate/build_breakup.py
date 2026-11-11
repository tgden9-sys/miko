"""Split the supplied textured game crate into capped 3D fragments, not proxy cubes."""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'Game/models/props'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(OUT/'wooden_crate.glb'))
source=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=source
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
coords=[v.co for v in source.data.vertices]
lo=Vector([min(v[i] for v in coords) for i in range(3)])
hi=Vector([max(v[i] for v in coords) for i in range(3)])
size=hi-lo
for v in source.data.vertices:
    v.co=Vector(((v.co.x-(lo.x+hi.x)/2)*.8/size.x,
                 (v.co.y-(lo.y+hi.y)/2)*.8/size.y,
                 (v.co.z-lo.z)*.8/size.z))
raw=bpy.data.materials.new('Fresh broken wood interior');raw.use_nodes=True
shader=next(n for n in raw.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
shader.inputs['Base Color'].default_value=(.32,.19,.085,1)
shader.inputs['Roughness'].default_value=.93
source.data.materials.append(raw)
original=bmesh.new();original.from_mesh(source.data)
parts=[]
axes=[[-.41,-.145,.12,.41],[-.41,.025,.41],[-.01,.37,.81]]
for ix in range(3):
 for iy in range(2):
  for iz in range(2):
   bm=original.copy()
   for axis,index in enumerate((ix,iy,iz)):
    for side in (0,1):
     point=Vector((0,0,0));point[axis]=axes[axis][index+side]
     normal=Vector((0,0,0));normal[axis]=1 if side else -1
     geometry=list(bm.verts)+list(bm.edges)+list(bm.faces)
     result=bmesh.ops.bisect_plane(bm,geom=geometry,dist=.00001,plane_co=point,plane_no=normal,clear_outer=True,clear_inner=False)
     cut_edges=[e for e in result['geom_cut'] if isinstance(e,bmesh.types.BMEdge) and e.is_boundary]
     if cut_edges:
      faces=bmesh.ops.holes_fill(bm,edges=cut_edges,sides=0).get('faces',[])
      for face in faces:face.material_index=1
   if not bm.faces:bm.free();continue
   bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
   mesh=bpy.data.meshes.new(f'Crate fragment {ix}{iy}{iz}');bm.to_mesh(mesh);bm.free()
   obj=bpy.data.objects.new(mesh.name,mesh);bpy.context.collection.objects.link(obj)
   for material in source.data.materials:mesh.materials.append(material)
   # Pivot at the individual fragment centre for convincing tumbling.
   center=sum((v.co for v in mesh.vertices),Vector())/len(mesh.vertices)
   for v in mesh.vertices:v.co-=center
   obj.location=center;parts.append(obj)
original.free();bpy.data.objects.remove(source,do_unlink=True)
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'wooden_crate_broken.glb'),export_format='GLB',use_selection=True)
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).parent/'WoodenCrateBreakup.blend'))
stats={'fragments':len(parts),'triangles':sum(len(p.vertices)-2 for o in parts for p in o.data.polygons),'size_m':.8,'source':'wooden_crate.glb','method':'clipped original UV-mapped mesh, capped wood interiors'}
(Path(__file__).parent/'breakup.json').write_text(json.dumps(stats,indent=2))
print('CRATE_BREAKUP_BUILT',stats)
