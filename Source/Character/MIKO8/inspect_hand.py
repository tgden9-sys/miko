import bpy,os
from mathutils import Vector
B=os.path.dirname(os.path.abspath(__file__));Q=os.path.abspath(B+'/../../../Builds/Validation/MIKO8')
bpy.ops.wm.open_mainfile(filepath=B+'/MIKO8_inspection.blend');sc=bpy.context.scene;sc.render.resolution_x=800;sc.render.resolution_y=800;sc.cycles.samples=8;cam=sc.camera;cam.data.ortho_scale=.28
target=Vector((.245,-.015,-.06));cam.location=target+Vector((0,-3,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=Q+'/source_hand.png';bpy.ops.render.render(write_still=True)
