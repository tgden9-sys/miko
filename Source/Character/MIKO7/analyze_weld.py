import bpy,numpy as np,os
BASE=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(BASE,'miko7_source.glb'))
obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
p=np.empty(len(obj.data.vertices)*3,dtype=np.float32);obj.data.vertices.foreach_get('co',p);p=p.reshape(-1,3)
uniq,inv=np.unique(np.round(p,6),axis=0,return_inverse=True)
edges=np.empty(len(obj.data.edges)*2,dtype=np.int32);obj.data.edges.foreach_get('vertices',edges);edges=inv[edges.reshape(-1,2)]
parent=np.arange(len(uniq))
def find(x):
    while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
    return x
for a,b in edges:
    ra,rb=find(a),find(b)
    if ra!=rb:parent[rb]=ra
roots=np.array([find(i) for i in range(len(uniq))])[inv]
u,c=np.unique(roots,return_counts=True)
print('WELDED',len(uniq),'COMPONENTS',len(u),flush=True)
for k in np.argsort(c)[-20:][::-1]:
    pp=p[roots==u[k]];print(int(c[k]),pp.min(axis=0).round(4),pp.max(axis=0).round(4),flush=True)
np.savez_compressed(os.path.join(BASE,'welded_components.npz'),roots=roots)
