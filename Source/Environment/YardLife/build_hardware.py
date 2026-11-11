import bpy,math,tempfile
from pathlib import Path
ROOT=Path(r'C:\Users\tgden\Desktop\MIKO');OUT=ROOT/'Game/models/environment/yard_life'
tempfile.tempdir=str(ROOT/'Builds/Validation/BridgePlatforms/tmp')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mat=bpy.data.materials.new('Yard equipment painted palette');mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.94
col=mat.node_tree.nodes.new('ShaderNodeVertexColor');col.layer_name='Color';mat.node_tree.links.new(col.outputs['Color'],bsdf.inputs['Base Color'])
STEEL='4a5356';EDGE='939a94';DARK='252d31';GOLD='b99751';CERAMIC='575f59'
def colour(h):
 c=[int(h[i:i+2],16)/255 for i in (0,2,4)];return tuple(v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in c)+(1.,)
def finish(o,tint,bevel=.002):
 bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  m=o.modifiers.new('Manufactured edge radius','BEVEL');m.width=bevel;m.segments=2;bpy.ops.object.modifier_apply(modifier=m.name)
 o.data.materials.clear();o.data.materials.append(mat);a=o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
 for d in a.data:d.color=colour(tint)
 return o
def box(p,s,t=STEEL,b=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s;return finish(o,t,b)
def cylinder(p,r,h,t=STEEL,vertices=16,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=h,location=p,rotation=rotation);return finish(bpy.context.object,t,.002)
def export(name,start):
 bpy.ops.object.select_all(action='DESELECT');parts=[o for o in bpy.data.objects if o not in start]
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_cameras=False,export_lights=False)
 return o
start=set(bpy.data.objects)
cylinder((0,0,.028),.17,.056,DARK);cylinder((0,0,.062),.15,.022,EDGE)
cylinder((0,0,.18),.105,.23,STEEL);cylinder((0,0,.30),.14,.048,EDGE)
cylinder((0,0,.328),.105,.008,DARK)
for x in [-.095,.095]:
 for y in [-.095,.095]:cylinder((x,y,.068),.013,.014,GOLD,6)
for x in [-.055,0.,.055]:box((x,0,.341),(.012,.17,.013),DARK,.001)
vent=export('exhaust_outlet',start)
start=set(bpy.data.objects)
box((0,0,.03),(.58,.42,.06),DARK,.012);box((0,0,.34),(.51,.34,.59),STEEL,.018)
box((0,-.18,.35),(.44,.035,.49),DARK,.008);box((0,-.203,.35),(.40,.016,.45),STEEL,.006)
for z in [.17,.22,.27]:box((-.045,-.216,z),(.23,.009,.012),DARK,.002)
box((-.09,-.216,.48),(.13,.012,.052),GOLD,.003);box((.13,-.218,.34),(.021,.018,.11),EDGE,.004)
for x in [-.18,.18]:
 for z in [.15,.55]:cylinder((x,-.22,z),.012,.012,EDGE,6,(math.pi/2,0,0))
for x in [-.17,.17]:
 cylinder((x,0,.69),.033,.14,DARK)
 for z in [.65,.69,.73]:cylinder((x,0,z),.06,.025,CERAMIC)
 cylinder((x,0,.79),.043,.10,EDGE);cylinder((x,0,.845),.052,.026,GOLD)
terminal=export('service_terminal',start)
start=set(bpy.data.objects)
cylinder((0,0,.035),.15,.07,DARK);cylinder((0,0,.078),.12,.016,EDGE)
for x in [-.088,.088]:
 for y in [-.088,.088]:
  cylinder((x,y,.083),.012,.014,GOLD,6)
  box((x,y,.173),(.014,.014,.18),DARK,.003)
cylinder((0,0,.273),.122,.036,DARK);cylinder((0,0,.296),.07,.01,EDGE)
beacon=export('beacon_housing',start)
for i,o in enumerate([vent,terminal,beacon]):o.location.x=i*1.2
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Source/Environment/YardLife/YardHardware.blend'))
print('YARD_HARDWARE_READY')
