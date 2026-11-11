import bpy,json
from mathutils import Vector
from pathlib import Path
P=Path(__file__).resolve().parent
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(P/'source.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
pts=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
print('BOUNDS',*[ [min(p[i] for p in pts),max(p[i] for p in pts)] for i in range(3)])
for o in meshes:print(o.name,len(o.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=str(P/'source.blend'))
