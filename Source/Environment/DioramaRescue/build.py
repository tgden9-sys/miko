"""Native, deliberately modelled miniature substation props for the bridge.

All modelling coordinates below are Godot coordinates (Y up, front is +Z).
The exported GLBs contain genuine bevelled geometry and core glTF PBR materials.
No view-dependent billboards, baked lighting, or screen-space facades are used.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'Game/models/environment/diorama_rescue'
OUT.mkdir(parents=True, exist_ok=True)
random.seed(81)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def vec(p):
    return Vector((p[0], -p[2], p[1]))

def mat(name, color, metal=0, rough=.7, texture=None, emission=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*color, 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    if texture:
        n = m.node_tree.nodes.new('ShaderNodeTexImage')
        n.image = bpy.data.images.load(str(ROOT / texture), check_existing=True)
        n.interpolation = 'Linear'
        m.node_tree.links.new(n.outputs['Color'], p.inputs['Base Color'])
    if emission:
        p.inputs['Emission Color'].default_value = (*color, 1)
        p.inputs['Emission Strength'].default_value = emission
    return m

M = {
    'concrete': mat('DR Warm aggregate concrete', (.40, .395, .36), rough=.91,
                    texture='Game/art/tutorial/ortho_materials/concrete.png'),
    'paint': mat('DR Weathered slate enamel', (.19, .24, .27), .28, .67,
                'Game/art/tutorial/ortho_materials/painted_steel.png'),
    'edge': mat('DR Slate enamel edgework', (.22, .265, .275), .35, .61),
    'iron': mat('DR Graphite iron', (.055, .067, .071), .72, .53),
    'rust': mat('DR Oxidised brown iron', (.19, .112, .066), .48, .76),
    'metal': mat('DR Satin zinc hardware', (.31, .315, .285), .82, .43),
    'ceramic': mat('DR Glazed brown porcelain', (.094, .063, .039), .07, .29),
    'ochre': mat('DR Faded ochre safety rail', (.53, .32, .105), .43, .64),
    'ivory': mat('DR Aged instrument ivory', (.64, .62, .52), .02, .73),
    'glass': mat('DR Smoked instrument glass', (.018, .033, .033), .22, .23),
    'lamp': mat('DR Warm frosted lamp', (1, .56, .17), .04, .38, emission=1.9),
}
objects = []

def finish(o, name, material):
    o.name = name
    o.data.materials.append(M[material])
    objects.append(o)
    return o

def bevel(o, width=.025, segments=3):
    if width:
        b = o.modifiers.new('Small manufactured edge radius', 'BEVEL')
        b.width = width
        b.segments = segments
        b.harden_normals = True
        n = o.modifiers.new('Area weighted corner normals', 'WEIGHTED_NORMAL')
        n.keep_sharp = True
        n.weight = 50
    return o

def box(name, p, size, material='paint', edge=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=vec(p))
    o = bpy.context.object
    o.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return bevel(finish(o, name, material), edge)

def tube(name, a, b, radius, material='iron', vertices=24, radius2=None, edge=.009):
    a, b = vec(a), vec(b)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
                                  radius2=radius if radius2 is None else radius2,
                                  depth=(b-a).length, location=(a+b)/2)
    o = bpy.context.object
    o.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    finish(o, name, material)
    for f in o.data.polygons:
        f.use_smooth = len(f.vertices) == 4
    return bevel(o, min(edge, radius*.15), 2)

def torus(name, p, radius, minor=.025, material='iron', axis=(0,1,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=8,
                                    major_radius=radius, minor_radius=minor,
                                    location=vec(p))
    o = bpy.context.object
    o.rotation_euler = vec(axis).to_track_quat('Z', 'Y').to_euler()
    for f in o.data.polygons:
        f.use_smooth = True
    return finish(o, name, material)

def pipe(name, points, radius=.035, material='iron'):
    c = bpy.data.curves.new(name, 'CURVE')
    c.dimensions = '3D'
    c.bevel_depth = radius
    c.bevel_resolution = 3
    c.resolution_u = 12
    s = c.splines.new('POLY')
    s.points.add(len(points)-1)
    for q, p in zip(s.points, points):
        q.co = (*vec(p), 1)
    o = bpy.data.objects.new(name, c)
    bpy.context.collection.objects.link(o)
    return finish(o, name, material)

def bolt(p, axis=(0,0,1), r=.025, length=.025, material='metal'):
    p, a = Vector(p), Vector(axis).normalized()
    tube('Hexagonal zinc bolt head', p, p+a*length, r, material, 6, edge=.003)
    tube('Bolt washer', p-a*.006, p+a*.004, r*1.3, material, 16, edge=.002)

def panel_bolts(x,y,z,w,h,material='metal'):
    for dx in [-w/2+.055,w/2-.055]:
        for dy in [-h/2+.055,h/2-.055]:
            bolt((x+dx,y+dy,z), r=.019, length=.016, material=material)

def flange(a, b, radius=.14, material='rust'):
    a,b=Vector(a),Vector(b)
    tube('Circular bolted pipe flange', a,b,radius,material,32,edge=.009)
    axis=(b-a).normalized()
    u=axis.cross(Vector((0,1,0)))
    if u.length < .01:
        u=axis.cross(Vector((1,0,0)))
    u.normalize(); w=axis.cross(u).normalized()
    for i in range(8):
        t=math.tau*i/8
        p=b+(u*math.cos(t)+w*math.sin(t))*(radius*.75)
        bolt(p,axis,r=.015,length=.018)

def round_drop(name,x,y,z,bottom,r=.065,material='rust',direction=1):
    pts=[(x-direction*.53,y,z),(x-direction*.22,y,z)]
    for i in range(13):
        t=math.pi*.5*i/12
        pts.append((x-direction*.22+direction*.22*math.sin(t),y-.22+.22*math.cos(t),z))
    pts.append((x,bottom,z))
    pipe(name,pts,r,material)
    for yy in [y-.42,bottom+.22]:
        tube('Cast pipe union',(x,yy-.045,z),(x,yy+.045,z),r*1.32,'metal',20)

def foot(x,z,width=.23):
    box('Machine isolation foot',(x,.365,z),(width,.15,width),'iron',.018)
    box('Bolted foot plate',(x,.275,z),(width+.14,.045,width+.14),'metal',.009)
    for dx in [-width*.40,width*.40]:
        for dz in [-width*.40,width*.40]:
            bolt((x+dx,.30,z+dz),(0,1,0),.021,.026)

def lid_bolts(x,y,z,width,depth):
    for dx in [-width*.42,width*.42]:
        for dz in [-depth*.37,0,depth*.37]:
            bolt((x+dx,y,z+dz),(0,1,0),.023,.022)

def insulator(x,y,z,height=.94):
    tube('Porcelain bushing mounting socket',(x,y,z),(x,y+.12,z),.19,'metal',32)
    tube('Central bushing stem',(x,y+.06,z),(x,y+height,z),.065,'ceramic',24)
    for i in range(7):
        yy=y+.17+i*.102
        tube('Glazed overhanging porcelain shed',(x,yy,z),(x,yy+.055,z),.16-i*.004,'ceramic',32,.103-i*.003,.006)
        torus('Porcelain rolled drip lip',(x,yy+.012,z),.143-i*.004,.009,'ceramic')
    tube('Terminal collar',(x,y+height-.10,z),(x,y+height,z),.085,'metal',24)
    tube('Copper terminal connector',(x,y+height,z),(x,y+height+.12,z),.051,'rust',16)
    bolt((x,y+height+.125,z),(0,1,0),.07,.035)

def cabinet(x,y,z,w,h,d):
    box('Folded sheet metal cabinet',(x,y,z),(w,h,d),'paint',.05)
    front=z+d/2
    box('Dark door gasket',(x,y,front+.012),(w-.085,h-.085,.035),'iron',.022)
    box('Inset cabinet access door',(x,y,front+.037),(w-.13,h-.13,.035),'edge',.021)
    panel_bolts(x,y,front+.06,w-.13,h-.13)
    for yy in [y-h*.27,y+h*.27]:
        box('Raised cabinet hinge',(x-w/2+.10,yy,front+.08),(.05,.16,.055),'metal',.012)
    # Folded handle stands clear of its door, casting a fine shadow.
    pipe('Cabinet pull handle',[(x+w*.28,y-.11,front+.07),(x+w*.28,y-.11,front+.14),
                               (x+w*.28,y+.09,front+.14),(x+w*.28,y+.09,front+.07)],.018,'iron')
    for yy in [y+h*.23,y+h*.23+.065,y+h*.23+.13]:
        box('Recessed door ventilation slot',(x-.04,yy,front+.061),(w*.38,.024,.007),'iron',.004)
    box('Embossed equipment maker plate',(x-.09,y-h*.28,front+.064),(.25,.10,.008),'metal',.006)
    for dx in [-.09,.09]: bolt((x-.09+dx,y-h*.28,front+.073),r=.008,length=.004)
    # Small raised datum marks, deliberately not unreadable fake lettering.
    for i in range(4):box('Maker plate engraving',(x-.15+i*.043,y-h*.28,front+.073),(.021,.014,.003),'iron',0)
    return front

def gauge(x,y,z,rad=.14):
    tube('Gauge rear body',(x,y,z-.06),(x,y,z),rad,'iron',32)
    tube('Gauge knurled rim',(x,y,z),(x,y,z+.035),rad*1.06,'metal',40)
    tube('Aged analog dial face',(x,y,z+.036),(x,y,z+.043),rad*.84,'ivory',40,edge=.003)
    for i in range(9):
        a=math.radians(-40+i*32)
        p=(x+math.cos(a)*rad*.69,y+math.sin(a)*rad*.69,z+.048)
        q=(x+math.cos(a)*rad*.52,y+math.sin(a)*rad*.52,z+.048)
        tube('Individual gauge tick',p,q,.005,'iron',6,edge=0)
    tube('Analog gauge needle',(x,y,z+.051),(x-rad*.40,y+rad*.32,z+.051),.007,'rust',8,edge=0)
    tube('Gauge needle pivot',(x,y,z+.05),(x,y,z+.06),.018,'iron',16)

def rail(x1,x2,z,height=.77):
    for x in [x1,x2]:
        box('Rail shoe',(x,.29,z),(.16,.06,.16),'iron',.009)
        for dx in [-.05,.05]:bolt((x+dx,.325,z),(0,1,0),.014,.017)
        tube('Tubular guardrail upright',(x,.32,z),(x,height+.25,z),.032,'ochre',16)
    # Broad-radius elbows and return feet are visible in silhouette.
    pts=[(x1,.53,z),(x1,height+.10,z)]
    r=.15
    for i in range(9):
        t=math.pi*.5*i/8
        pts.append((x1+r-r*math.cos(t),height+.10+r*math.sin(t),z))
    pts.append((x2-r,height+.25,z))
    for i in range(9):
        t=math.pi*.5*i/8
        pts.append((x2-r+r*math.sin(t),height+.10+r*math.cos(t),z))
    pts.append((x2,.53,z))
    pipe('Bent ochre guardrail',pts,.034,'ochre')
    tube('Guardrail lower horizontal',(x1,.64,z),(x2,.64,z),.025,'ochre',16)

def crate(x,z,w=.68,h=.55,d=.56):
    box('Transport crate rubber feet',(x,.30,z),(w*.89,.10,d*.9),'iron',.014)
    box('Steel parts crate',(x,.35+h*.5,z),(w,h,d),'paint',.04)
    box('Overlapping crate lid',(x,.35+h+.015,z),(w+.035,.07,d+.035),'edge',.016)
    for dx in [-w*.33,w*.33]:
        box('Crate reinforcing vertical strap',(x+dx,.35+h*.5,z+d*.5+.014),(.043,h,.027),'iron',.006)
        box('Crate lid retaining strap',(x+dx,.35+h+.055,z),(.045,.022,d*.95),'metal',.004)
        box('Over centre crate clasp',(x+dx,.35+h-.10,z+d*.5+.04),(.065,.13,.035),'metal',.008)
    pipe('Crate carry handle',[(x-.12,.35+h*.5,z+d*.5+.028),(x-.12,.35+h*.5-.055,z+d*.5+.08),
                               (x+.12,.35+h*.5-.055,z+d*.5+.08),(x+.12,.35+h*.5,z+d*.5+.028)],.015,'metal')

def can(x,z):
    tube('Oil can rolled base',(x,.27,z),(x,.31,z),.17,'iron',32)
    tube('Small oil can body',(x,.31,z),(x,.68,z),.165,'rust',32, .145,.013)
    tube('Oil can shoulder',(x,.68,z),(x,.75,z),.145,'rust',32,.072)
    tube('Oil can spout',(x,.75,z),(x+.12,.88,z),.027,'metal',16,.018)
    torus('Can base rolled seam',(x,.315,z),.16,.012,'metal')
    pipe('Oil can loop handle',[(x-.10,.69,z),(x-.24,.69,z),(x-.27,.53,z),(x-.17,.44,z)],.019,'iron')

def concrete_block(p,size):
    box('Separate cast concrete equipment footing',p,size,'concrete',.035)
    x,y,z=p;w,h,d=size
    for yy in [y-h*.25,y+h*.25]:
        for dx in [-w*.30,w*.30]:
            # Actual shallow form-tie sleeves, kept flush rather than black decals.
            tube('Cast concrete form tie recess',(x+dx,yy,z+d*.5+.001),(x+dx,yy,z+d*.5+.006),.021,'iron',12,edge=.002)

def base():
    concrete_block((0,.125,0),(5.75,.25,3.5))
    for x in [-2.0,-.8,.4,1.6]:
        box('Plinth expansion seam',(x,.253,1.30),(.012,.006,.83),'iron',0)
    # A tiny drain has individually modelled slots and concrete reveal.
    box('Drain inset',(2.25,.257,.98),(.62,.02,.35),'iron',.01)
    for i in range(9):box('Drain crossbar',(2.0+i*.061,.274,.98),(.022,.019,.31),'metal',.003)

def left():
    base()
    concrete_block((-.30,.41,-.35),(3.48,.32,2.25))
    for x in [-1.45,.85]:
        for z in [-1.05,.35]:foot(x,z)
    box('Transformer reinforced tank',(-.30,1.81,-.37),(2.68,2.43,1.40),'paint',.105)
    box('Tank lower welded seam',(-.30,.69,-.37),(2.75,.13,1.46),'iron',.022)
    box('Tank top sealing gasket',(-.30,3.036,-.37),(2.78,.045,1.50),'iron',.016)
    box('Transformer overhanging lid',(-.30,3.10,-.37),(2.91,.12,1.62),'edge',.04)
    lid_bolts(-.30,3.17,-.37,2.91,1.62)
    # Fins are separate thin folded sheets with visible thickness and header pipes.
    box('Radiator dark rear chamber',(-.3,1.80,.385),(2.37,1.98,.16),'iron',.03)
    for i in range(22):
        x=-1.41+i*.106
        box('Individually bevelled cooling fin',(x,1.81,.615),(.040,1.82,.43),'edge',.009)
    for yy in [.84,2.77]:
        tube('Radiator circular header',(-1.52,yy,.61),(.92,yy,.61),.088,'paint',24)
        for x in [-1.43,.83]:round_drop('Radiator curled return',x,yy+.1,.48,yy-.15,.046,'iron')
    for x in [-1.16,-.30,.56]:insulator(x,3.17,-.42,.92)
    # Oil expansion vessel on the rear shoulder makes a three-dimensional silhouette.
    tube('Rear conservator oil barrel',(-1.40,2.95,-1.13),(.79,2.95,-1.13),.235,'paint',40,edge=.018)
    for x in [-1.22,.62]:
        torus('Conservator rolled end band',(x,2.95,-1.13),.238,.022,'metal',(1,0,0))
        tube('Conservator cradle leg',(x,2.73,-1.13),(x,2.56,-1.13),.055,'iron',16)
    round_drop('Transformer right service oil pipe',1.16,2.6,.22,.62,.062,'rust')
    flange((1.16,1.05,.22),(1.16,1.12,.22),.118)
    tube('Drain valve branch',(1.16,.82,.22),(1.16,.82,.49),.057,'rust',20)
    torus('Drain valve handwheel',(1.16,.82,.57),.115,.018,'ochre',(0,0,1))
    for a in range(4):
        t=a*math.pi/2
        tube('Valve wheel spoke',(1.16,.82,.57),(1.16+.10*math.cos(t),.82+.10*math.sin(t),.57),.009,'ochre',8)
    gauge(1.10,2.30,.40,.13)
    for xx in [-1.59,.98]:
        box('Lifting lug block',(xx,2.86,-.35),(.12,.15,.13),'metal',.018)
        torus('Forged lifting eye',(xx,2.99,-.35),.070,.019,'metal',(0,0,1))
    # Open stepped castings rather than a solid rear wall.
    concrete_block((-2.22,1.01,-.79),(.89,1.52,1.45))
    concrete_block((-2.16,2.05,-1.0),(.78,.56,1.00))
    cabinet(-2.23,1.14,.03,.60,.98,.32)
    round_drop('Stepped concrete service conduit',-2.69,2.74,-.55,.33,.041,'iron',-1)
    for yy in [.68,1.50,2.30]:
        box('Pipe saddle fixing strap',(-2.69,yy,-.55),(.15,.055,.12),'metal',.009)
    tube('Cable conduit branch',(-2.69,.44,-.55),(-1.96,.44,-.55),.038,'iron',16)
    cabinet(2.03,1.13,-.51,1.0,1.58,.76)
    for x in [1.73,2.33]:
        foot(x,-.70,.18)
        foot(x,-.29,.18)
    gauge(1.88,1.21,-.096,.10)
    pipe('Switchgear lower conduit',[(2.03,.36,-.5),(2.03,.28,-.5),(1.68,.28,-.5),(1.68,.28,.70)],.031,'iron')
    rail(-1.45,.99,1.04,.70)
    crate(-1.87,1.20,.68,.53,.55)
    can(1.59,1.04)

def cylinder_tank(x,z,height=2.6,r=.55):
    bottom=.55; top=bottom+height
    for dx in [-.32,.32]:
        for dz in [-.29,.29]:
            foot(x+dx,z+dz,.15)
            tube('Tank tubular support',(x+dx,.37,z+dz),(x+dx,.72,z+dz),.049,'iron',16)
    tube('Vertical oil filled transformer tank',(x,bottom,z),(x,top,z),r,'paint',48,edge=.045)
    tube('Rolled bottom tank flange',(x,bottom-.02,z),(x,bottom+.10,z),r+.035,'edge',48)
    tube('Tank lid sealing gasket',(x,top,z),(x,top+.035,z),r+.027,'iron',48,edge=.007)
    tube('Tank flanged top lid',(x,top+.04,z),(x,top+.12,z),r+.07,'edge',48,edge=.019)
    for i in range(12):
        a=math.tau*i/12
        bolt((x+math.cos(a)*(r+.025),top+.13,z+math.sin(a)*(r+.025)),(0,1,0),.024,.027)
    for yy in [bottom+.27,top-.27]:
        torus('Split tank reinforcement band',(x,yy,z),r+.008,.028,'metal')
    insulator(x,top+.12,z,.87)
    gauge(x,top-.54,z+r+.015,.12)
    # End-on oval footings and lifting ears articulate the cylindrical silhouette.
    for dx in [-r,r]:
        torus('Vertical transformer lifting loop',(x+dx,top-.18,z),.071,.021,'metal',(0,0,1))
    tube('Tank drain fitting',(x,bottom+.13,z+r),(x,bottom+.13,z+r+.17),.062,'rust',20)
    flange((x,bottom+.13,z+r+.13),(x,bottom+.13,z+r+.19),.102)
    return top

def right():
    base()
    concrete_block((-.68,.40,-.42),(3.05,.30,2.20))
    cylinder_tank(-1.44,-.46,2.13,.52)
    cylinder_tank(-.13,-.55,2.40,.58)
    # Interconnecting pipe bends are deliberately real rounded pipework.
    pipe('Twin tank connecting pipe',[(-1.44,2.52,-.46),(-1.44,2.78,-.46),(-1.39,2.86,-.46),
                                      (-.24,2.86,-.46),(-.13,2.95,-.46)],.045,'rust')
    round_drop('Oil circulation descending pipe',.69,3.23,-.58,.55,.07,'rust')
    flange((.69,.80,-.58),(.69,.87,-.58),.134)
    pipe('Tank lower linking return',[(.69,.60,-.58),(.69,.48,-.58),(.54,.40,-.58),(-1.43,.40,-.58)],.069,'rust')
    # Raised separate control equipment leaves substantial negative space behind it.
    for xx in [1.30,2.19]:
        box('Control stand base shoe',(xx,.29,-.82),(.30,.075,.42),'metal',.012)
        tube('Control equipment tubular support',(xx,.33,-.82),(xx,1.51,-.82),.054,'iron',20)
        for zz in [-.95,-.68]:bolt((xx,.34,zz),(0,1,0),.022,.025)
    cabinet(1.75,2.05,-.80,1.35,1.38,.75)
    box('Control cabinet projecting rain hood',(1.75,2.80,-.75),(1.49,.09,.98),'edge',.024)
    gauge(1.40,2.11,-.34,.12)
    for xx in [1.48,1.70,1.92]:
        tube('Control switch bezel',(xx,1.81,-.37),(xx,1.81,-.31),.047,'metal',20)
        tube('Small dark rotary control',(xx,1.81,-.31),(xx,1.81,-.28),.029,'iron',16)
    # Square bend conduit bundle below cabinet with clips and separation.
    for i in range(3):
        zz=-.58+i*.095
        pipe('Three separate bent control conduits',[(1.43+i*.13,1.37,zz),(1.43+i*.13,.61,zz),
                                                     (1.31+i*.13,.48,zz),(.87,.48,zz)],.018,'metal')
    for yy in [.75,1.14]:box('Conduit bank securing clip',(1.57,yy,-.51),(.46,.043,.39),'iron',.007)
    concrete_block((2.50,.79,-.84),(.53,1.06,1.07))
    box('Grounded terminal pillar cap',(2.50,1.36,-.84),(.61,.10,1.17),'metal',.023)
    # Tall cable riser at the outer corner, well below the maximum bushing height.
    for x in [2.56,2.72]:
        round_drop('Outer cable riser',x,3.42,-1.19,.34,.038,'iron')
        for yy in [.70,1.54,2.38,3.14]:
            box('Riser saddle clip',(x,yy,-1.19),(.13,.04,.11),'metal',.007)
    # A small compressor on the front corner supplies a separate low silhouette.
    cabinet(1.63,.76,.77,1.06,.82,.60)
    box('Service box pedestal',(1.63,.30,.77),(1.18,.10,.70),'iron',.014)
    tube('Round recessed fan aperture',(1.50,.81,1.075),(1.50,.81,1.092),.21,'iron',32)
    torus('Compressor fan protection rim',(1.50,.81,1.11),.205,.016,'metal',(0,0,1))
    for i in range(7):
        xx=1.50+(i-3)*.051
        dy=math.sqrt(max(0,.19**2-(xx-1.50)**2))
        tube('Individual fan grille bar',(xx,.81-dy,1.125),(xx,.81+dy,1.125),.009,'metal',8,edge=.002)
    rail(-2.25,.63,1.06,.71)
    crate(-2.31,.50,.55,.42,.52)
    can(.63,1.35)

def convert_and_export(name, builder):
    global objects
    bpy.ops.object.select_all(action='DESELECT')
    objects=[]
    builder()
    source_count=len(objects)
    for o in objects:
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.convert(target='MESH')
        # Meter-scaled world projection makes material detail independent of box size.
        uv=o.data.uv_layers.active or o.data.uv_layers.new(name='World scale PBR')
        mw=o.matrix_world
        for poly in o.data.polygons:
            normal=mw.to_3x3()@poly.normal
            axis=max(range(3),key=lambda k:abs(normal[k]))
            material=o.data.materials[poly.material_index].name if o.data.materials else ''
            scale=.48 if 'concrete' in material else .26
            for loop_index in poly.loop_indices:
                co=mw@o.data.vertices[o.data.loops[loop_index].vertex_index].co
                if axis==0:u,v=co.y,co.z
                elif axis==1:u,v=co.x,co.z
                else:u,v=co.x,co.y
                uv.data[loop_index].uv=(u*scale,v*scale)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    o=bpy.context.object;o.name=name
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # Remove duplicated material slots created by joining the many small parts.
    old=list(o.data.materials); unique=[]; remap={}
    for i,m in enumerate(old):
        if m not in unique:unique.append(m)
        remap[i]=unique.index(m)
    indices=[remap[p.material_index] for p in o.data.polygons]
    o.data.materials.clear()
    for m in unique:o.data.materials.append(m)
    for p,i in zip(o.data.polygons,indices):p.material_index=i
    # Join origin is fixed at the bridge deck surface, not a primitive centre.
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',
                              use_selection=True,export_apply=True,export_yup=True,
                              export_materials='EXPORT',export_texcoords=True,
                              export_normals=True,export_image_format='AUTO')
    coords=[o.matrix_world@v.co for v in o.data.vertices]
    godot=[(p.x,p.z,-p.y) for p in coords]
    stats={'source_parts':source_count,'vertices':len(o.data.vertices),
           'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),
           'surfaces':len(unique),'materials':[m.name for m in unique],
           'bounds_godot':{'min':[round(min(p[i] for p in godot),4) for i in range(3)],
                           'max':[round(max(p[i] for p in godot),4) for i in range(3)]}}
    o.hide_render=True
    o.hide_set(True)
    return o,stats

left_obj,left_stats=convert_and_export('machinery_left',left)
right_obj,right_stats=convert_and_export('machinery_right',right)
stats={'machinery_left':left_stats,'machinery_right':right_stats,
       'coordinate_system':'Godot Y up; exposed detailed fronts face +Z; origin at deck Y=0',
       'placement':'Left (25,0,-5), right (40,0,-5). No rotation. Keep near side Z=-3.25 behind walking lane.',
       'authoring':'Manufactured bevels and fasteners are physical geometry. Textures are only material albedo. Core glTF metallic/roughness PBR; 11 surfaces maximum.'}
(OUT/'geometry.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')

# Store a useful editable scene and two studio checks, excluded from GLB exports.
scene=bpy.context.scene
scene.world=bpy.data.worlds.new('Quiet charcoal studio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.11,.15,.18,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.42
for o,offset in [(left_obj,-3.4),(right_obj,3.4)]:
    o.hide_render=False;o.hide_set(False);o.location.x=offset

def area(p,target,power,size,color):
    bpy.ops.object.light_add(type='AREA',location=vec(p))
    o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color
    o.rotation_euler=(vec(target)-o.location).to_track_quat('-Z','Y').to_euler()

area((-3,8,7),(0,1.4,0),1500,7,(1,.84,.65))
area((5,4,-4),(0,1.5,0),1150,6,(.67,.78,1))
area((0,3,7),(0,1.0,0),250,8,(.76,.86,1))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.012))
floor=bpy.context.object;floor.name='Studio floor (not exported)'
floor.data.materials.append(mat('Studio floor',(.065,.079,.084),rough=.95))
bpy.ops.object.camera_add(location=vec((9,7.2,14)))
cam=bpy.context.object
cam.rotation_euler=(vec((0,1.8,0))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.type='ORTHO';cam.data.ortho_scale=15.4;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=True
scene.render.resolution_x=1800;scene.render.resolution_y=950;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(OUT/'machinery_studio.png')
bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).resolve().parent/'DioramaRescue.blend'))
bpy.ops.render.render(write_still=True)
cam.location=vec((0,5.8,16));cam.rotation_euler=(vec((0,1.65,0))-cam.location).to_track_quat('-Z','Y').to_euler()
cam.data.ortho_scale=13.8
scene.render.filepath=str(OUT/'machinery_front.png')
bpy.ops.render.render(write_still=True)
print('DIORAMA_RESCUE_BUILT',json.dumps(stats),flush=True)
