import bpy,math,tempfile,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:\Users\tgden\Desktop\MIKO');OUT=ROOT/'Game/models/environment/industrial_ladder';OUT.mkdir(exist_ok=True)
tempfile.tempdir=str(ROOT/'Builds/Validation/BridgePlatforms/tmp')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('Ladder painted steel vertex palette');mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.9;bsdf.inputs['Metallic'].default_value=0.
col=mat.node_tree.nodes.new('ShaderNodeVertexColor');col.layer_name='Color';mat.node_tree.links.new(col.outputs['Color'],bsdf.inputs['Base Color'])
STEEL='414e53';EDGE='7d898b';DARK='263239';GOLD='bc964d';BOLT='b3b9b1'
def colour(hex):
 c=[int(hex[i:i+2],16)/255 for i in (0,2,4)]
 return tuple(v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in c)+(1.,)
def finish(o,tint,bevel=0.):
 bpy.context.view_layer.objects.active=o
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
 o.data.materials.clear();o.data.materials.append(mat)
 attr=o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
 value=colour(tint)
 for item in attr.data:item.color=value
 return o
def box(at,size,tint,bevel=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.scale=size
 return finish(o,tint,bevel)
def bolt(at,r=.009):
 bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=r,depth=.012,location=at,rotation=(math.pi/2,0,0));return finish(bpy.context.object,BOLT,.001)
def export(name,objects):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_cameras=False,export_lights=False)
 return o
start=set(bpy.data.objects)
box((0,0,.5),(.065,.075,1.),STEEL,.009)
box((0,-.041,.5),(.025,.008,.96),EDGE,.002)
box((-.028,.025,.5),(.012,.025,.99),DARK,.002);box((.028,.025,.5),(.012,.025,.99),DARK,.002)
rail=export('rail_1m',[o for o in bpy.data.objects if o not in start])
start=set(bpy.data.objects)
box((0,0,0),(.49,.085,.042),STEEL,.006)
box((0,0,.024),(.415,.075,.009),DARK,.002)
for x in [-.18,-.135,-.09,-.045,0.,.045,.09,.135,.18]:box((x,-.004,.031),(.012,.061,.005),EDGE,.001)
box((0,-.045,0),(.43,.008,.014),GOLD,.0015)
for x in [-.216,.216]:box((x,.01,-.007),(.04,.07,.035),DARK,.003)
rung=export('grip_rung',[o for o in bpy.data.objects if o not in start])
start=set(bpy.data.objects)
box((0,.19,0),(.12,.025,.14),STEEL,.004)
box((0,.095,0),(.045,.17,.045),DARK,.003)
for x in [-.035,.035]:
 for z in [-.045,.045]:bolt((x,.169,z))
mount=export('wall_standoff',[o for o in bpy.data.objects if o not in start])
start=set(bpy.data.objects)
curve=bpy.data.curves.new('Rolled roof return','CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=.033;curve.bevel_resolution=2
points=[(0,.08-.08*math.cos(i*math.pi/16),-.08+.08*math.sin(i*math.pi/16)) for i in range(9)]+[(0,.37,0)]
spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
for p,co in zip(spline.points,points):p.co=(*co,1.)
o=bpy.data.objects.new('Rounded return',curve);bpy.context.collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True)
# Convert only the new curve, without the previous modular meshes selected.
for other in bpy.context.selected_objects:
 if other!=o:other.select_set(False)
bpy.ops.object.convert(target='MESH');finish(bpy.context.object,EDGE)
box((0,.345,-.025),(.115,.105,.025),STEEL,.005)
bolt((-.032,.34,-.017));bolt((.032,.34,-.017))
top=export('roof_return',[o for o in bpy.data.objects if o not in start])
# Save the editable modules arranged as a small parts sheet.
for i,o in enumerate([rail,rung,mount,top]):o.location.x=i*.9
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Source/Environment/BridgePlatforms/IndustrialLadder.blend'))
print('INDUSTRIAL_LADDER_READY',[(o.name,len(o.data.polygons)) for o in [rail,rung,mount,top]])
