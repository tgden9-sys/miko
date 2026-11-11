import bpy
import json
from pathlib import Path

root = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'security_drone_source.glb'))
obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
mesh = obj.data
n = len(mesh.vertices)
parent = list(range(n))
size = [1] * n

def find(i):
    while parent[i] != i:
        parent[i] = parent[parent[i]]
        i = parent[i]
    return i

for edge in mesh.edges:
    a, b = edge.vertices
    ra, rb = find(a), find(b)
    if ra != rb:
        if size[ra] < size[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        size[ra] += size[rb]

stats = {}
for v in mesh.vertices:
    root_id = find(v.index)
    x, y, z = v.co
    if root_id not in stats:
        stats[root_id] = [0, [0.0, 0.0, 0.0], [x, y, z], [x, y, z]]
    s = stats[root_id]
    s[0] += 1
    for i, val in enumerate((x,y,z)):
        s[1][i] += val
        s[2][i] = min(s[2][i], val)
        s[3][i] = max(s[3][i], val)

components = []
for root_id, (count, total, low, high) in stats.items():
    components.append({'root': root_id, 'vertices': count, 'centre': [v/count for v in total], 'min': low, 'max': high})
components.sort(key=lambda c: c['vertices'], reverse=True)
(root / 'components.json').write_text(json.dumps(components, indent=2))
print('COMPONENTS', len(components), 'TOP', json.dumps(components[:30]))
