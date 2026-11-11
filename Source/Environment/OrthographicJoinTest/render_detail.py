import bpy
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parent
scene=bpy.context.scene
cam=scene.camera
cam.location=(0,-15,5.4)
cam.rotation_euler=(Vector((0,0,-.25))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=5.8
scene.cycles.samples=12
scene.render.resolution_x=1280
scene.render.resolution_y=960
scene.render.resolution_percentage=100
scene.render.filepath=str(root/'join_detail.png')
bpy.ops.render.render(write_still=True)
