import bpy
import json
from mathutils import Vector

SOURCE = r"C:\Users\tgden\Downloads\replicate-prediction-k1d4hp77rnrne0d1ecnbtg4vkc.glb"
OUT = r"C:\Users\tgden\Desktop\MIKO\Source\Enemies\SecurityRobot\inspection.json"

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=SOURCE)
bpy.context.view_layer.update()

objects = []
for obj in bpy.data.objects:
    corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box] if obj.type == 'MESH' else []
    objects.append({
        'name': obj.name,
        'type': obj.type,
        'parent': obj.parent.name if obj.parent else None,
        'location': list(obj.location),
        'rotation_euler': list(obj.rotation_euler),
        'scale': list(obj.scale),
        'vertices': len(obj.data.vertices) if obj.type == 'MESH' else 0,
        'bounds_min': [min(p[i] for p in corners) for i in range(3)] if corners else None,
        'bounds_max': [max(p[i] for p in corners) for i in range(3)] if corners else None,
        'materials': [slot.material.name if slot.material else None for slot in obj.material_slots],
    })

with open(OUT, 'w', encoding='utf-8') as stream:
    json.dump(objects, stream, indent=2)
print('INSPECTED', len(objects), 'objects')
