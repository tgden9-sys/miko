import bpy,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=Path(__file__).resolve().parents[3]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'Game/models/environment/workshop/workshop.glb'))
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
verts=[mesh.matrix_world@v.co for v in mesh.data.vertices]
tree=BVHTree.FromPolygons(verts,[list(p.vertices) for p in mesh.data.polygons])
samples=[]
for x in [-2.5,-2,-1.5,-1,-.5,0,.5,1,1.5,2,2.5]:
 hit,normal,face,distance=tree.ray_cast(Vector((x,0,6)),Vector((0,0,-1)),10)
 samples.append([x,round(hit.z,4) if hit else None])
print('ROOF_SAMPLES',json.dumps(samples))
(Path(__file__).parent/'roof_samples.json').write_text(json.dumps(samples,indent=2))
profiles={}
for name,points in {
 'left_right_at_lane':[(x,0) for x in [-3.19,-3.15,-3.10,-3.05,-3.,-2.95,-2.9,-2.8,-2.7,-2.6,2.6,2.7,2.8,2.9,2.95,3.,3.05,3.10,3.15,3.19]],
 'front_back_at_centre':[(0,z) for z in [-1.49,-1.45,-1.4,-1.35,-1.3,-1.25,-1.2,-1.1,1.1,1.2,1.25,1.3,1.35,1.4,1.45,1.49]],
 'corners':[(x,z) for x in [-3.1,-2.9,2.9,3.1] for z in [-1.4,1.4]],
}.items():
 values=[]
 for x,z in points:
  hit,normal,face,distance=tree.ray_cast(Vector((x,-z,6)),Vector((0,0,-1)),10)
  values.append([x,z,round(hit.z,4) if hit else None])
 profiles[name]=values
(Path(__file__).parent/'rim_profiles.json').write_text(json.dumps(profiles,indent=2))
print('RIM_PROFILES',json.dumps(profiles))
