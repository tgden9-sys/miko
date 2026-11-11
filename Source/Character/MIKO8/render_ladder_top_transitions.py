import bpy,math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[3];B=Path(__file__).parent;O=R/'Builds/Validation/LadderTransitions'
bpy.ops.wm.open_mainfile(filepath=str(B/'MIKO8_LadderTop_Animated.blend'))
sc=bpy.context.scene;rig=bpy.data.objects['MIKO8_Rig']
def gv(p):return Vector((p[0],-p[2],p[1]))
def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);return m
concrete=mat('Landing grey',(.37,.39,.38));metal=mat('Handrail amber',(.58,.40,.15));dark=mat('Ladder backing',(.18,.22,.23))
def box(name,at,size,material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=gv(at));o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
def pipe(a,b,r=.03):
 a,b=gv(a),gv(b);bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=(b-a).length,location=(a+b)*.5)
 o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(metal)
box('Rear supported landing',(-.1,3.1,-.975),(1.,.2,1.05),concrete)
box('Main landing',(1.2,3.1,-.1),(1.6,.2,2.8),concrete)
box('Back wall',(0,1.55,-.72),(1.1,3.1,.16),dark)
for x in [-.255,.255]:
 pipe((x,0,-.33),(x,4.10,-.33))
 pipe((x,4.10,-.33),(x,4.10,-.70))
for index in range(1,14):
 y=index*.23898
 if y<3.15:pipe((-.255,y,-.33),(.255,y,-.33),.022)
sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=480;sc.render.resolution_y=560;sc.render.resolution_percentage=100
sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=True
sc.world.color=(.12,.14,.16);sc.render.image_settings.file_format='PNG'
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.6;sc.camera=cam
for label in ['LadderTopOut','LadderTopIn']:
 a=bpy.data.actions['MIKO8_'+label];rig.animation_data.action=a;rig.animation_data.action_slot=a.slots[0]
 for view,pos in [('back',(-1.1,4.65,9)),('side',(7,4.5,1.4))]:
  target=gv((.35,3.65,-.1));cam.location=gv(pos);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
  for index in range(8):
   sc.frame_set(round(a.frame_range[1]*index/7));bpy.context.view_layer.update()
   sc.render.filepath=str(O/f'{label}_{view}_{index}.png');bpy.ops.render.render(write_still=True)
rig.animation_data.action=bpy.data.actions['MIKO8_LadderTopOut'];rig.animation_data.action_slot=rig.animation_data.action.slots[0];sc.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(B/'MIKO8_LadderTop_Review.blend'))
print('LADDER_TOP_STAGED_REVIEW_DONE')
