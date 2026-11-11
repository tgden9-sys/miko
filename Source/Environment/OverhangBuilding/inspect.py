import bpy,pathlib,json
from mathutils import Vector
root=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'Source/Environment/OverhangBuilding/original.glb'))
points=[o.matrix_world@v.co for o in bpy.context.scene.objects if o.type=='MESH' for v in o.data.vertices]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
low=[p for p in points if p.z<lo.z+(hi.z-lo.z)*.4]
print('PROFILE',list(lo),list(hi),'LOW_X',min(p.x for p in low),max(p.x for p in low))
sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_cavity=True
sc.render.resolution_x=1200;sc.render.resolution_y=900;sc.render.resolution_percentage=100
bpy.ops.object.camera_add(location=(3,-6,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,(hi.z+lo.z)*.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.4;sc.camera=cam
sc.render.filepath=str(root/'Builds/Validation/Overhang/source.png');bpy.ops.render.render(write_still=True)
(root/'Builds/Validation/Overhang/profile.json').write_text(json.dumps({'lo':list(lo),'hi':list(hi),'low_min_x':min(p.x for p in low),'low_max_x':max(p.x for p in low)}))
