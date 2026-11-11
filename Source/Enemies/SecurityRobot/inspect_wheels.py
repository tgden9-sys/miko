import bpy
from collections import defaultdict

bpy.ops.wm.open_mainfile(filepath=r'C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot\security_robot_rig.blend')
obj = bpy.data.objects['Security_Robot_Mesh']
mesh = obj.data
names = ['Far_Wheel', 'Middle_Wheel', 'Near_Wheel']
for name in names:
    group = obj.vertex_groups[name]
    vertices = [v for v in mesh.vertices if any(g.group == group.index for g in v.groups)]
    bounds = [(min(v.co[i] for v in vertices), max(v.co[i] for v in vertices)) for i in range(3)]
    print(name, len(vertices), bounds, flush=True)
    counts = defaultdict(int)
    for v in vertices:
        r = ((v.co.y - .135)**2 + (v.co.z + .34)**2)**.5
        if r > .115:
            counts[round(v.co.x, 2)] += 1
    print('outer x:', sorted(counts.items(), key=lambda item: -item[1])[:20], flush=True)
print('Materials:', [(i,m.name) for i,m in enumerate(mesh.materials)], flush=True)
