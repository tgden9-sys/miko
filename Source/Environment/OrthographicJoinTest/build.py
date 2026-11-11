import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
random.seed(42)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
def material(name,a,b,metal=0,scale=7,bump=.08):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links
 p=n.get('Principled BSDF');p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.78
 coord=n.new('ShaderNodeTexCoord');noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=scale;noise.inputs['Detail'].default_value=5;noise.inputs['Roughness'].default_value=.78;l.new(coord.outputs['Generated'],noise.inputs['Vector'])
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.28;ramp.color_ramp.elements[0].color=(*a,1);ramp.color_ramp.elements[1].position=.72;ramp.color_ramp.elements[1].color=(*b,1);l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color'])
 fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=180;fine.inputs['Detail'].default_value=2;l.new(coord.outputs['Generated'],fine.inputs['Vector'])
 relief=n.new('ShaderNodeBump');relief.inputs['Strength'].default_value=.32;relief.inputs['Distance'].default_value=bump;l.new(fine.outputs['Fac'],relief.inputs['Height']);l.new(relief.outputs[0],p.inputs['Normal'])
 return m
concrete=material('Mottled blue grey concrete',(.11,.135,.16),(.32,.34,.33),scale=5,bump=.055)
paving=material('Worn paving',(.13,.155,.18),(.32,.33,.30),scale=9,bump=.025)
rim=material('Chipped coping stones',(.22,.24,.25),(.42,.42,.36),scale=8,bump=.045)
steel=material('Oxidised blue black steel',(.025,.038,.048),(.11,.14,.16),.7,9,.018)
rust=material('Rust worn railing',(.045,.055,.06),(.22,.115,.055),.65,14,.018)
bolts=material('Bolt edges',(.17,.15,.12),(.29,.28,.23),.8,10,.005)
dark=material('Deep joints',(.012,.017,.022),(.035,.04,.043),.2,4,.008)
moss=material('Crevice moss',(.035,.06,.025),(.13,.17,.045),0,8,.012)
leafmat=material('Ivy green',(.025,.05,.025),(.14,.19,.055),0,4,.003)
paint=material('Faded amber warning paint',(.21,.15,.065),(.48,.37,.16),.1,15,.01)
lamp=bpy.data.materials.new('Warm lamp glass');lamp.use_nodes=True
p=lamp.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(1,.57,.19,1);p.inputs['Emission Color'].default_value=(1,.40,.09,1);p.inputs['Emission Strength'].default_value=5
collections={}
for name in ['A_ConcreteWalkway','B_SteelBridge','Shared_AbutmentAndLight','Presentation']:
 c=bpy.data.collections.new(name);scene.collection.children.link(c);collections[name]=c
active='A_ConcreteWalkway'
def own(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 collections[active].objects.link(o)
 return o
def cube(name,at,size,mat,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=own(bpy.context.object);o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  mod=o.modifiers.new('Worn edges','BEVEL');mod.width=bevel;mod.segments=2
  mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o
def pipe(name,a,b,r,mat=rust,verts=12):
 a=Vector(a);b=Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=(b-a).length,location=(a+b)/2)
 o=own(bpy.context.object);o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
 mod=o.modifiers.new('Metal rim','BEVEL');mod.width=min(.008,r*.13);mod.segments=2
 for face in o.data.polygons:face.use_smooth=True
 return o
def curve(name,points,r,mat):
 data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=r;data.bevel_resolution=1
 spline=data.splines.new('POLY');spline.points.add(len(points)-1)
 for p,v in zip(spline.points,points):p.co=(*v,1)
 o=bpy.data.objects.new(name,data);collections[active].objects.link(o);o.data.materials.append(mat);return o
def ivy(x,z,length):
 pts=[]
 for i in range(13):pts.append((x+.06*math.sin(i*.75),-1.445,z-length*i/12))
 curve('Trailing ivy stem',pts,.008,moss)
 for i in range(32):
  f=random.random();xx=x+.07*math.sin(f*9)+random.choice([-1,1])*random.uniform(.04,.16);zz=z-length*f
  w=random.uniform(.035,.075)
  verts=[(xx,-1.46,zz+w),(xx+w*.8,-1.47,zz),(xx,-1.48,zz-w),(xx-w*.8,-1.47,zz)]
  data=bpy.data.meshes.new('Ivy leaf');data.from_pydata(verts,[],[(0,1,2,3)]);data.materials.append(leafmat)
  o=bpy.data.objects.new('Individual ivy leaf',data);collections[active].objects.link(o)
def lamp_light(at,power=75):
 bpy.ops.object.light_add(type='AREA',location=at);o=own(bpy.context.object);o.data.energy=power;o.data.color=(1,.48,.19);o.data.shape='DISK';o.data.size=.8
 o.rotation_euler=(Vector((at[0],at[1]-.3,-.15))-o.location).to_track_quat('-Z','Y').to_euler()

# Six metre walkway. World coordinates are shared by both modules.
cube('Walkway foundation',(-3,0,-1.5),(6,2.8,2.8),concrete,.05)
for i in range(6):
 for j in range(3):
  o=cube('Individual paving slab',(-5.5+i,-.93+j*.93,-.065),(.985,.915,.13),paving,.018)
  # Fine physically modelled cracks, not converging painted perspective lines.
  if random.random()<.55:
   x=-5.5+i;y=-.93+j*.93
   curve('Hairline pavement crack',[(x-.34,y-.20,.003),(x-.17,y-.06,.003),(x-.21,y+.04,.003),(x+.05,y+.24,.003)],.0035,dark)
for i in range(8):
 cube('Front coping stone',(-5.625+i*.75,-1.38,-.12),(.735,.26,.27),rim,.025)
 cube('Foundation panel',(-5.625+i*.75,-1.425,-1.18),(.725,.10,1.78),concrete,.035)
for x in [-5.6,-2.8,-.42]:
 cube('Concrete structural rib',(x,-1.49,-1.6),(.24,.20,2.4),rim,.025)
for x in [-5.45,-4.9,-2.6,-1.2,-.45]:ivy(x,-.13,random.uniform(.4,1.5))
# Water stain traces and irregular moss along selected joints.
for i in range(36):
 x=random.uniform(-5.9,-.35);length=random.uniform(.12,.75)
 curve('Fine runoff trace',[(x,-1.485,-.27),(x+.008,-1.486,-.27-length)],random.uniform(.003,.009),dark)
for x in [-5,-3.8,-1.8]:
 cube('Moss in paving joint',(x,-1.1,.006),(.17,.032,.008),moss,.002)
# Front utility run with flanges that ends at the shared pier.
pipe('Utility pipe',(-5.95,-1.59,-.67),(-.48,-1.59,-.67),.095,steel,20)
for x in [-5.2,-3.6,-1.9,-.65]:
 pipe('Pipe collar',(x-.035,-1.59,-.67),(x+.035,-1.59,-.67),.125,rust,20)
 for angle in [0,math.pi/2,math.pi,3*math.pi/2]:
  xx=x;yy=-1.59+math.cos(angle)*.114;zz=-.67+math.sin(angle)*.114
  pipe('Flange bolt',(xx-.045,yy,zz),(xx+.045,yy,zz),.016,bolts,6)
cube('Service junction box',(-3.1,-1.57,-1.35),(.52,.17,.63),steel,.025)
cube('Box inset',(-3.1,-1.675,-1.35),(.43,.04,.54),rust,.012)
for x in [-3.27,-2.93]:
 for z in [-1.56,-1.14]:pipe('Box screw',(x,-1.71,z),(x,-1.72,z),.015,bolts,6)
curve('Bent electrical conduit',[(-3.1,-1.56,-1.67),(-3.1,-1.56,-2.15),(-2.9,-1.56,-2.25),(-.45,-1.56,-2.25)],.025,steel)
cube('Drain grille surround',(-4.0,.2,.006),(.65,.5,.015),steel,.012)
for i in range(11):cube('Drain slots',(-4.27+i*.053,.2,.018),(.018,.42,.008),dark,.002)
for x in [-5.1,-1.8]:
 cube('Recessed maintenance light housing',(x,-1.54,-1.05),(.36,.14,.13),steel,.015)
 cube('Protected light glass',(x,-1.625,-1.06),(.28,.015,.055),lamp,.009)
 lamp_light((x,-1.8,-.96),35)

active='B_SteelBridge'
cube('Level bridge deck',(3,0,-.065),(6,2.8,.13),steel,.012)
for i in range(30):
 x=.10+i*.20
 cube('Bridge non slip deck panels',(x,0,.008),(.185,2.69,.024),rust,.006)
 for y in [-.9,-.3,.3,.9]:cube('Raised grip strip',(x,y,.023),(.12,.025,.008),bolts,.002)
for y in [-1.35,1.35]:
 cube('Structural I girder web',(3,y,-.39),(6,.09,.57),steel,.008)
 for z in [-.105,-.685]:cube('I girder flange',(3,y,z),(6,.26,.07),rust,.008)
for i in range(6):
 x=.5+i
 cube('Girder reinforcing plate',(x,-1.415,-.4),(.14,.035,.48),rust,.005)
 for z in [-.22,-.57]:pipe('Girder plate bolt',(x,-1.44,z),(x,-1.465,z),.028,bolts,6)
 pipe('Under deck crossbeam',(x,-1.3,-.53),(x,1.3,-.53),.075,steel)
for i in range(3):
 x=i*2
 for y in [-1.28,1.28]:
  pipe('Diagonal structural brace',(x+.04,y,-.62),(x+1,y,-1.12),.055,steel)
  pipe('Diagonal structural brace',(x+1,y,-1.12),(x+1.96,y,-.62),.055,steel)
pipe('Longitudinal lower chord',(.05,-1.28,-1.12),(5.95,-1.28,-1.12),.06,steel)
for x in [.4,5.6]:
 cube('Bridge service lamp',(x,-1.4,-.48),(.30,.12,.12),steel,.012)
 cube('Bridge lamp diffuser',(x,-1.47,-.49),(.23,.02,.055),lamp,.008)
 lamp_light((x,-1.65,-.48),35)

active='Shared_AbutmentAndLight'
# One shared structural pier owns the joint. Both deck surfaces meet at z=0.
cube('Joint load bearing pier',(0,0,-1.6),(.52,3.05,3.0),concrete,.045)
cube('Joint stone cap',(0,0,-.16),(.62,3.0,.30),rim,.035)
cube('Deck expansion gap',(0,0,.001),(.035,2.79,.012),dark,.002)
for x in [-.09,.09]:
 cube('Expansion joint steel nosing',(x,0,.008),(.10,2.75,.018),steel,.004)
 for y in [-1.1,-.55,0,.55,1.1]:pipe('Joint countersunk fastener',(x,y,.02),(x,y,.025),.018,bolts,6)
# Rear rail uses the same post placement and pipe heights for BOTH pieces.
for x in [-6,-4,-2,0,2,4,6]:
 cube('Rail post foot',(x,1.30,.035),(.22,.22,.07),steel,.012)
 for dx in [-.07,.07]:
  for dy in [-.07,.07]:pipe('Rail anchor bolt',(x+dx,1.3+dy,.06),(x+dx,1.3+dy,.09),.016,bolts,6)
 pipe('Railing upright',(x,1.3,.08),(x,1.3,1.0),.045,rust,16)
 for z in [.43,.94]:
  pipe('Railing T collar',(x,1.3,z-.055),(x,1.3,z+.055),.057,steel,16)
for a,b in [(-6,0),(0,6)]:
 for z in [.43,.94]:pipe('Continuous level rear rail',(a,1.3,z),(b,1.3,z),.038,rust,16)
# Join light stands behind the lane, not in front of the actor.
cube('Lamp post concrete socket',(0,1.10,.13),(.32,.32,.26),rim,.03)
pipe('Rear corner lighting post',(0,1.10,.23),(0,1.10,2.65),.065,steel,16)
pipe('Lamp bracket',(0,1.10,2.6),(0,.67,2.6),.04,rust)
cube('Lamp head',(0,.55,2.55),(.52,.40,.14),steel,.025)
cube('Lamp diffuser',(0,.55,2.47),(.41,.30,.02),lamp,.015)
lamp_light((0,.55,2.42),200)
for z in [.3,.5]:cube('Amber post ID bands',(0,1.028,z),(.09,.007,.08),paint,.002)
cube('Opposite end abutment',(6,0,-1.6),(.52,3.05,3),concrete,.045)

active='Presentation'
# Shadowed environmental backing is separate from the modules.
cube('Distant indigo backdrop',(0,4,-.1),(40,.1,20),material('Backdrop',(.021,.033,.052),(.05,.068,.09),scale=3,bump=0),0)
scene.world=bpy.data.worlds.new('Blue hour ambient');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.16,.23,.38,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.40
def area(at,target,power,size,color):
 bpy.ops.object.light_add(type='AREA',location=at);o=own(bpy.context.object);o.data.energy=power;o.data.size=size;o.data.color=color;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
area((-4,-4,7),(0,0,0),1250,8,(.58,.72,1))
area((5,2,5),(0,0,0),1000,6,(.94,.64,.35))
area((0,-5,1),(0,0,-.5),220,7,(.40,.56,.78))
bpy.ops.object.camera_add(location=(0,-22,8));cam=own(bpy.context.object)
cam.rotation_euler=(Vector((0,0,-.45))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=14.7;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1920;scene.render.resolution_y=1080;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(ROOT/'two_piece_orthographic.png')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'TwoPiece_Orthographic.blend'))
json.dump({'camera':'Orthographic; no horizontal camera yaw; parallel pavement lines','length_m':12,'width_m':2.8,'walking_z':0,'join_x':0,'walkway':[-6,0],'bridge':[0,6],'rail_height_m':1,'join':'Shared load-bearing pier, expansion joint, rear-corner lamp. No obstacle in lane.','status':'Native 3D visual prototype. Not installed in the game. Procedural materials need baking for export.'},open(ROOT/'dimensions.json','w'),indent=2)
bpy.ops.render.render(write_still=True)
cam.location=(0,-15,5.4);cam.rotation_euler=(Vector((0,0,-.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.4
scene.render.resolution_x=1440;scene.render.resolution_y=1080;scene.render.filepath=str(ROOT/'join_detail.png')
bpy.ops.render.render(write_still=True)
print('ORTHOGRAPHIC_JOIN_READY',flush=True)
