import bpy, math, pathlib, json
from mathutils import Vector
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');folder=root/'Source/Environment/PressureSwitchV2';out=root/'Game/models/environment/pressure_switch_v2';out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Roughness'].default_value=.9;return m
steel=material('BrushedSteel',(.28,.31,.32));edge=material('EdgeSteel',(.39,.42,.43));dark=material('GraphiteSeals',(.065,.077,.082));panel=material('TreadSteel',(.23,.25,.265));signal=material('ReadySignal',(.12,.8,.36));bolt=material('FastenerSteel',(.16,.18,.19))
base=bpy.data.objects.new('SwitchBase',None);bpy.context.collection.objects.link(base)
plunger=bpy.data.objects.new('SwitchPlunger',None);bpy.context.collection.objects.link(plunger)
def finish(obj,name,mat,parent,bevel=0):
 obj.name=name;obj.data.materials.append(mat);obj.parent=parent
 if bevel:
  mod=obj.modifiers.new('Manufactured edge','BEVEL');mod.width=bevel;mod.segments=1;bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
 return obj
def box(name,at,size,mat,parent,bevel=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,mat,parent,bevel)
def ring(name,outer,inner,z_outer,z_inner,mat,parent):
 verts=[]
 for x,y,z in [(-outer[0],-outer[1],z_outer),(outer[0],-outer[1],z_outer),(outer[0],outer[1],z_outer),(-outer[0],outer[1],z_outer),(-inner[0],-inner[1],z_inner),(inner[0],-inner[1],z_inner),(inner[0],inner[1],z_inner),(-inner[0],inner[1],z_inner)]:verts.append((x,y,z))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);return finish(o,name,mat,parent)
box('ContinuousSealedFoundation',(0,0,.018),(2.4,2.,.036),dark,base,.012)
ring('TaperedApproach',(1.20,1.),(1.,.8),.002,.080,steel,base)
ring('MachinedFrame',(1.,.8),(.87,.665),.080,.080,edge,base)
ring('ClosedSlidingSeal',(.875,.67),(.839,.629),.077,.073,dark,base)
box('CentreTread',(0,0,.0525),(1.70,1.28,.045),panel,plunger,.008)
# The panel's overlapping skirt covers its moving seam at both travel limits.
ring('OverlappingCentreSkirt',(.86,.65),(.83,.62),.054,.075,steel,plunger)
ring('CentreLightBorder',(.826,.615),(.810,.599),.0758,.0758,signal,plunger)
def line(name,a,b,width,mat,parent):
 a=Vector(a);b=Vector(b);o=box(name,(a+b)*.5,(width,(b-a).length,.002),mat,parent,0);o.rotation_euler[2]=-math.atan2(b.x-a.x,b.y-a.y);return o
corners=[(0,.45,.0768),(.55,0,.0768),(0,-.45,.0768),(-.55,0,.0768),(0,.40,.0768),(.49,0,.0768),(0,-.40,.0768),(-.49,0,.0768)]
mesh=bpy.data.meshes.new('ContinuousPressureDiamond');mesh.from_pydata(corners,[],[(i,4+i,4+(i+1)%4,(i+1)%4) for i in range(4)]);obj=bpy.data.objects.new('ContinuousPressureDiamond',mesh);bpy.context.collection.objects.link(obj);finish(obj,'ContinuousPressureDiamond',signal,plunger)
box('ArrowStem',(0,.065,.077),(.070,.27,.002),signal,plunger,0)
mesh=bpy.data.meshes.new('ArrowHead');mesh.from_pydata([(-.16,-.055,.077),(0,-.225,.077),(.16,-.055,.077)],[],[(0,1,2)]);obj=bpy.data.objects.new('ArrowHead',mesh);bpy.context.collection.objects.link(obj);finish(obj,'ArrowHead',signal,plunger)
box('ArrowStop',(0,-.285,.077),(.29,.031,.002),signal,plunger,0)
for side in [-1,1]:
 for i in range(6):
  x=-.625+i*.25;y=side*.90;z=.043
  housing=box('IndicatorBezel',(x,y,z),(.222,.095,.010),dark,base,.006);housing.rotation_euler[0]=-side*math.atan(.078/.20)
  window=box('IndicatorWindow',(x,y,z+.006),(.180,.054,.006),signal,base,.004);window.rotation_euler[0]=-side*math.atan(.078/.20)
for x in [-.935,.935]:
 for y in [-.73,0,.73]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.026,depth=.005,location=(x,y,.082));finish(bpy.context.object,'RecessedFastener',dark,base)
  bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.015,depth=.003,location=(x,y,.085));finish(bpy.context.object,'HexFastener',bolt,base)
  box('FastenerSlot',(x,y,.0868),(.017,.003,.0008),dark,base,0)
# Restrained inset tread bars and service joins; no protrusions on the approach.
for y in [-.50,.50]:
 for x in [-.66,.66]:box('TreadWearInset',(x,y,.0759),(.17,.012,.001),edge,plunger,0)
for x in [-.81,.81]:box('PanelEdgeLine',(x,0,.076),(.007,1.08,.001),dark,plunger,0)
for parent,name in [(base,'BaseGeometry'),(plunger,'CentreGeometry')]:
 bpy.ops.object.select_all(action='DESELECT');parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==parent]
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();bpy.context.object.name=name
bpy.ops.wm.save_as_mainfile(filepath=str(folder/'pressure_switch_v2.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'pressure_switch_v2.glb'),export_format='GLB',export_animations=False)
report={'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons),'bytes':(out/'pressure_switch_v2.glb').stat().st_size,'base_size':[2.4,2.0],'panel_size':[1.7,1.28],'panel_top':.075,'travel':.02}
(folder/'asset.json').write_text(json.dumps(report,indent=2));print('PRESSURE_V2_BUILT',report)
