import bpy
import json
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'security_drone_source.glb'))

report = []
for obj in bpy.context.scene.objects:
    entry = {'name': obj.name, 'type': obj.type, 'parent': obj.parent.name if obj.parent else None}
    if obj.type == 'MESH':
        verts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
        entry['vertices'] = len(obj.data.vertices)
        entry['polygons'] = len(obj.data.polygons)
        entry['bounds_min'] = [min(v[i] for v in verts) for i in range(3)]
        entry['bounds_max'] = [max(v[i] for v in verts) for i in range(3)]
        entry['materials'] = [m.name if m else None for m in obj.data.materials]
    report.append(entry)
(root / 'inspection.json').write_text(json.dumps(report, indent=2))
print('INSPECTION', json.dumps(report)[:5000])
