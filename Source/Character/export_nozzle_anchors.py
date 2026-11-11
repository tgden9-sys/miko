"""Project the actual cut nozzle rim for every exported pose; no re-rendering."""
import bpy, json, math
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

root=Path(__file__).resolve().parent
scene=bpy.context.scene
scene.camera=bpy.data.objects['Sprite test camera']
scene.camera.data.ortho_scale=1.38
scene.render.resolution_x=scene.render.resolution_y=384
scene.render.resolution_percentage=100
body=bpy.data.objects['TORSO | sample 2 neckerchief and single rear chassis v27']
low=min(v.co.z for v in body.data.vertices)
rim=[v.co.copy() for v in body.data.vertices if v.co.z < low+0.002]
centre=Vector(((min(v.x for v in rim)+max(v.x for v in rim))/2,
               (min(v.y for v in rim)+max(v.y for v in rim))/2,low))
record=json.loads((root/'neckerchief_render_jobs_v28.json').read_text())
result={}
cache={}
def project(matrix,p):
    q=world_to_camera_view(scene,scene.camera,matrix@p)
    return Vector(((q.x-.5)*384,(.5-q.y)*384))
for job in record['jobs']:
    if job['view'] not in ('full','body'):continue
    frame=job['frame']
    if frame not in cache:
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        matrix=body.evaluated_get(bpy.context.evaluated_depsgraph_get()).matrix_world
        pts=[project(matrix,v) for v in rim]
        c=project(matrix,centre)
        axis=project(matrix,centre+Vector((0,0,-.05)))-c
        tangent=Vector((axis.y,-axis.x)).normalized()
        widths=[p.dot(tangent) for p in pts]
        cache[frame]={'centre':[round(x,4) for x in c],
                      'width':round(max(widths)-min(widths),4),
                      'angle':round(math.atan2(axis.y,axis.x)-math.pi/2,5)}
    result[job['path']]=cache[frame]
target=root.parents[1]/'Game/sprites/nozzle_anchors_v29.json'
target.write_text(json.dumps(result,separators=(',',':')))
print('NOZZLE_ANCHORS',len(result),'poses',len(cache),'rim_vertices',len(rim))
print('IDLE',result['sprites/idle/idle_000.png'])
