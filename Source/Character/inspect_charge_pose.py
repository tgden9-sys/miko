import bpy
from pathlib import Path
root=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root/'robot_knockback_v32.blend'))
s=bpy.context.scene
s.frame_set(401)
for name in ('Sprite test camera','CTRL | ROBOT ROOT','CTRL | hover body','HEAD | helmet, visor and antenna',*[f'CTRL | {side} {joint}' for side in ('L','R') for joint in ('shoulder','elbow','wrist')]):
 o=bpy.data.objects[name]
 print(name, 'loc',tuple(round(v,3) for v in o.location),'rot',tuple(round(v,3) for v in o.rotation_euler),'world',tuple(round(v,3) for v in o.matrix_world.translation),flush=True)
print('THRUSTERS', [o.name for o in s.objects if 'thruster' in o.name.lower() or 'nozzle' in o.name.lower()],flush=True)
print('ENGINE', [o.name for o in s.objects if any(word in o.name.lower() for word in ('engine','exhaust','jet','plume'))],flush=True)
