"""Centre the retained head over the new torso without rewriting head actions."""
import bpy,math
from pathlib import Path
from mathutils import Matrix,Vector
root=Path(__file__).resolve().parent;s=bpy.context.scene;s.frame_set(401)
hover=bpy.data.objects['CTRL | hover body'];head=bpy.data.objects['HEAD | helmet, visor and antenna']
alignment=bpy.data.objects.new('CTRL | head neutral alignment v28',None);s.collection.objects.link(alignment)
alignment.parent=hover;alignment.empty_display_type='ARROWS';alignment.empty_display_size=.08
pivot=Vector((0,-.105,.19))
alignment.matrix_basis=Matrix.Translation(Vector((.033,0,0)))@Matrix.Translation(pivot)@Matrix.Rotation(math.radians(-.5),4,'Y')@Matrix.Translation(-pivot)
head.parent=alignment;head.matrix_parent_inverse.identity()
alignment['purpose']='Neutral alignment only; retained head animation remains on its original control'
alignment['translation_x_m']=.033;alignment['roll_correction_degrees']=-.5
s.name='ROBOT aligned neckerchief torso and original articulated rig v28'
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(root/'robot_neckerchief_aligned_v28.blend'))
print('HEAD_NEUTRAL_ALIGNED',flush=True)
