import bpy, json, os
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r'C:\Users\tgden\Desktop\MIKO\Source\Character\MIKO7\miko7_source.glb')
for o in bpy.context.scene.objects:
    print('OBJECT',o.name,o.type,tuple(o.dimensions),tuple(o.location),len(o.data.vertices) if o.type=='MESH' else '')
    if o.type=='MESH':
        print('BOUNDS', [tuple(o.matrix_world@Vector(c)) for c in o.bound_box])
        print('MATS',[m.name for m in o.data.materials])
bpy.ops.wm.save_as_mainfile(filepath=r'C:\Users\tgden\Desktop\MIKO\Source\Character\MIKO7\miko7_inspect.blend')
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=12
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
meshes=[o for o in scene.objects if o.type=='MESH']
pts=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
low=Vector(tuple(min(p[i] for p in pts) for i in range(3))); high=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
center=(low+high)/2; size=max(high-low)
def aim(o,p):o.rotation_euler=(p-o.location).to_track_quat('-Z','Y').to_euler()
world=bpy.data.worlds.new('Studio');scene.world=world;world.use_nodes=True
world.node_tree.nodes.get('Background').inputs[0].default_value=(.18,.18,.18,1)
world.node_tree.nodes.get('Background').inputs[1].default_value=.7
for loc in [(2,-4,5),(-3,-1,3),(0,3,4)]:
    bpy.ops.object.light_add(type='AREA',location=center+Vector(loc)*size/3)
    o=bpy.context.object;o.data.energy=500*size*size;o.data.shape='DISK';o.data.size=size*2;aim(o,center)
bpy.ops.object.camera_add(location=center+Vector((0,-3,0))*size)
cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=size*1.13;aim(cam,center);scene.camera=cam
for name,vec in [('front',(0,-3,0)),('back',(0,3,0)),('side',(3,0,0))]:
    cam.location=center+Vector(vec)*size;aim(cam,center)
    scene.render.filepath=os.path.join(r'C:\Users\tgden\Desktop\MIKO\Builds\Validation\MIKO7',name+'.png')
    bpy.ops.render.render(write_still=True)
