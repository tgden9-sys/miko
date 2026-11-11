import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
OUT=ROOT.parents[2]/'Game/models/environment/cel_diorama'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
palette={'Slate enamel':(.24,.32,.41),'Pale concrete':(.45,.49,.51),'Dark steel':(.055,.085,.12),'Edge metal':(.31,.38,.43),'Ceramic':(.13,.20,.26),'Amber trim':(.67,.39,.12),'Warm lamp':(1,.66,.30),'Cyan indicator':(.23,.85,.86)}
mats={}
for name,col in palette.items():
 m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=.73
 if 'lamp' in name or 'indicator' in name:
  p.inputs['Emission Color'].default_value=(*col,1);p.inputs['Emission Strength'].default_value=1.4
 mats[name]=m
def v(p):return Vector((p[0],-p[2],p[1]))
def box(name,p,s,mat='Slate enamel',bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=v(p));o=bpy.context.object;o.name=name;o.dimensions=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat])
 if bevel:
  b=o.modifiers.new('Precise edge bevel','BEVEL');b.width=bevel;b.segments=2
  o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return o
def cyl(name,a,b,r,mat='Dark steel',verts=16,r2=None):
 a=v(a);b=v(b)
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r,radius2=r if r2 is None else r2,depth=(b-a).length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(mats[mat])
 mod=o.modifiers.new('Rim bevel','BEVEL');mod.width=min(.012,r*.1);mod.segments=2
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return o
def line(name,pts,r,mat='Dark steel'):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=2;c.resolution_u=8
 sp=c.splines.new('POLY');sp.points.add(len(pts)-1)
 for q,p in zip(sp.points,pts):q.co=(*v(p),1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(mats[mat]);return o
def pipe_drop(x,top,bottom,z):
 # Rounded elbow from horizontal run into a vertical drop.
 pts=[(x-.8,top,z),(x-.25,top,z)]
 for i in range(9):
  t=math.pi/2*i/8;pts.append((x-.25+.25*math.sin(t),top-.25+.25*math.cos(t),z))
 pts.append((x,bottom,z));line('Bent service pipe',pts,.085)
 for y in [bottom+.3,top-.45]:cyl('Pipe coupling',(x,y-.045,z),(x,y+.045,z),.125,'Edge metal')
def lamp(x,y,z):
 box('Lamp backplate',(x,y,z),(.52,.26,.13),'Dark steel')
 box('Lamp hood',(x,y+.13,z+.08),(.66,.08,.32),'Edge metal',.018)
 box('Warm lamp lens',(x,y,z+.08),(.39,.11,.025),'Warm lamp',.018)
def wall():
 for z in [-6.8,-7.1]:line('Continuous overhead cable',[(i*.25,5.8-.45*math.sin(i/24*math.pi),z) for i in range(25)],.023)
 box('Foundation course',(3,-.6,-6.0),(6,2.8,1.8),'Pale concrete',.055)
 for x in [.07,5.93]:box('Structural end pier',(x,1.6,-6.9),(.14,6.7,1.9),'Pale concrete',.025)
 box('Rear enclosing wall',(3,1.5,-7.55),(5.8,3.9,.3),'Slate enamel')
 box('Wall coping',(3,3.52,-7.45),(5.9,.16,.6),'Edge metal')
 for y in [-1.4,-.5]:box('Foundation expansion joint',(3,y,-5.085),(5.8,.018,.018),'Dark steel',0)
 for x in [1.5,4.5]:box('Concrete joint',(x,-.6,-5.085),(.018,2.6,.018),'Dark steel',0)
 box('Cable tray',(3,.52,-5.0),(5.85,.16,.28),'Dark steel',.015)
 for x in [.5,2,4,5.5]:box('Tray support',(x,.38,-5.04),(.065,.3,.35),'Edge metal',.012)
def transformer():
 box('Concrete transformer plinth',(2.9,.7,-6.0),(4.45,.34,2.35),'Pale concrete',.055)
 box('Transformer tank',(2.65,2.53,-6),(3.5,3.3,1.7),'Slate enamel',.11)
 box('Tank lid',(2.65,4.25,-6),(3.75,.18,1.9),'Edge metal')
 box('Cooling bank shadow',(2.65,2.5,-5.06),(3.28,2.8,.2),'Dark steel',.03)
 for i in range(18):box('Radiator fin',(1.12+i*.18,2.5,-4.83),(.055,2.66,.43),'Edge metal',.012)
 for y in [1.12,3.89]:box('Radiator header',(2.65,y,-4.87),(3.52,.16,.48),'Slate enamel')
 for x in [1.5,2.65,3.8]:
  cyl('Insulator spindle',(x,4.3,-6),(x,5.7,-6),.065,'Edge metal')
  for j in range(7):cyl('Ceramic insulator skirt',(x,4.45+j*.17,-6),(x,4.54+j*.17,-6),.19-j*.009,'Ceramic',20,r2=.125-j*.005)
  cyl('Terminal cap',(x,5.7,-6),(x,5.88,-6),.09,'Amber trim')
 box('Side instrument cabinet',(5.02,1.9,-5.1),(.8,1.76,.58),'Slate enamel')
 box('Recessed cabinet door',(5.02,1.9,-4.79),(.64,1.54,.035),'Dark steel',.02)
 box('Door panel',(5.02,1.93,-4.76),(.57,1.4,.025),'Edge metal',.018)
 box('Cyan status strip',(5.02,2.3,-4.73),(.045,.35,.012),'Cyan indicator',.008)
 box('Cabinet handle',(5.22,1.8,-4.70),(.025,.17,.055),'Dark steel',.009)
 pipe_drop(.55,3.4,.65,-4.9);lamp(4.85,3.7,-5.0)
def fan_bay():
 box('Ventilation enclosure',(3,2.22,-6.1),(5.18,2.9,1.65),'Slate enamel',.08)
 box('Enclosure upper cap',(3,3.75,-6.1),(5.4,.17,1.9),'Edge metal')
 for x in [1.7,4.25]:
  cyl('Fan dark aperture',(x,2.28,-5.2),(x,2.28,-5.12),.92,'Dark steel',40)
  cyl('Outer fan rim',(x,2.28,-5.2),(x,2.28,-5.05),.95,'Edge metal',40)
  cyl('Fan inset',(x,2.28,-5.04),(x,2.28,-5.02),.83,'Dark steel',40)
  for i in range(7):
   a=i*math.tau/7
   blade=box('Fan blade',(x+math.cos(a)*.38,2.28+math.sin(a)*.38,-4.99),(.56,.16,.055),'Slate enamel',.035)
   blade.rotation_euler.y=-a
  cyl('Fan hub',(x,2.28,-5.02),(x,2.28,-4.88),.16,'Edge metal',20)
  for a in [0,math.pi/2]:
   dx=math.cos(a)*.86;dy=math.sin(a)*.86
   cyl('Fan safety grille',(x-dx,2.28-dy,-4.85),(x+dx,2.28+dy,-4.85),.018,'Edge metal',8)
 pipe_drop(5.65,4.1,.65,-4.85);lamp(3,4.2,-5.5)
def service_bay():
 box('Service room',(3,2.6,-6.5),(5.5,4.0,2.1),'Slate enamel',.055)
 box('Roof edge',(3,4.69,-6.5),(5.85,.22,2.65),'Edge metal')
 box('Door recess',(2.5,1.7,-5.42),(1.55,2.4,.05),'Dark steel',.015)
 box('Service door',(2.5,1.7,-5.37),(1.37,2.24,.045),'Slate enamel',.025)
 box('Door handle',(3.0,1.6,-5.31),(.035,.22,.06),'Edge metal',.01)
 for y in [2.12,2.18,2.24]:box('Door vent',(2.5,y,-5.33),(.58,.016,.012),'Dark steel',0)
 lamp(2.5,3.2,-5.23)
 box('Awning',(2.5,3.48,-5.1),(2.5,.12,1.0),'Edge metal')
 for x in [1.4,3.6]:cyl('Awning bracket',(x,3.05,-5.43),(x,3.45,-4.9),.025,'Dark steel',8)
 for x in [.55,4.7]:
  box('Wall equipment enclosure',(x,2.7,-5.3),(.64,1.14,.35),'Edge metal')
  box('Equipment dark panel',(x,2.7,-5.1),(.5,.98,.04),'Dark steel')
  box('Panel indicator',(x,2.83,-5.07),(.035,.3,.015),'Cyan indicator',.005)
 pipe_drop(4.1,4.15,.6,-5.25)
def export(name,func):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 wall();func()
 # Join evaluated geometry into one reusable mesh with shared palette surfaces.
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
 bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
 return sum(len(p.vertices)-2 for p in o.data.polygons)
stats={name:export(name,fn) for name,fn in [('transformer',transformer),('ventilation',fan_bay),('service_room',service_bay)]}
(ROOT/'geometry.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'SubstationCelKit.blend'))
print('CEL_KIT_BUILT',stats)
