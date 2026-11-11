import bpy
import json
from array import array

SOURCE = r"C:\Users\tgden\Downloads\replicate-prediction-k1d4hp77rnrne0d1ecnbtg4vkc.glb"
OUT = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot\islands.json"

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=SOURCE)
obj = next(o for o in bpy.data.objects if o.type == 'MESH')
mesh = obj.data
n = len(mesh.vertices)
parent = array('i', range(n))
size = array('i', [1]) * n

def find(a):
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    return a

for edge in mesh.edges:
    a, b = edge.vertices
    ra, rb = find(a), find(b)
    if ra != rb:
        if size[ra] < size[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        size[ra] += size[rb]

components = {}
for vertex in mesh.vertices:
    root = find(vertex.index)
    if root not in components:
        components[root] = {'count': 0, 'sum': [0.0]*3, 'min': [float('inf')]*3, 'max': [-float('inf')]*3}
    item = components[root]
    item['count'] += 1
    for i in range(3):
        value = vertex.co[i]
        item['sum'][i] += value
        item['min'][i] = min(item['min'][i], value)
        item['max'][i] = max(item['max'][i], value)

records = []
for root, item in components.items():
    records.append({
        'root': root,
        'count': item['count'],
        'centroid': [v/item['count'] for v in item['sum']],
        'min': item['min'],
        'max': item['max'],
    })
records.sort(key=lambda item: item['count'], reverse=True)
with open(OUT, 'w', encoding='utf-8') as stream:
    json.dump({'vertices': n, 'edges': len(mesh.edges), 'component_count': len(records), 'components': records}, stream, indent=2)
print('ANALYZED', n, 'vertices,', len(mesh.edges), 'edges,', len(records), 'components')
