import bpy,pathlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO');bpy.ops.wm.open_mainfile(filepath=str(root/'Source/Environment/TowerCatwalk/catwalk.blend'))
o=next(o for o in bpy.context.scene.objects if o.type=='MESH');tree=BVHTree.FromPolygons([v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons])
print('DECK_HEIGHT',[tree.ray_cast(Vector((0,y,2)),Vector((0,0,-1)))[0] for y in [-.6,0,.6]])
