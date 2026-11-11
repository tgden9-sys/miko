import bpy,pathlib,tempfile,json
from mathutils import Vector
ROOT=pathlib.Path(r'C:/Users/tgden/Desktop/MIKO')
OUT=ROOT/'Builds/Validation/TowerArtRevision'
OUT.mkdir(parents=True,exist_ok=True);tempfile.tempdir=str(OUT)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'Source/Environment/PlatformTowers/large_original.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
 bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
pts=[v.co.copy() for o in meshes for v in o.data.vertices]
lo=Vector([min(v[i] for v in pts) for i in range(3)]);hi=Vector([max(v[i] for v in pts) for i in range(3)])
print('LARGE_BOUNDS',list(lo),list(hi),flush=True)
scene=bpy.context.scene;scene.render.engine='BLENDER_WORKBENCH'
scene.display.shading.color_type='TEXTURE';scene.display.shading.light='FLAT'
scene.display.shading.show_shadows=False;scene.render.film_transparent=True
scene.render.resolution_x=800;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
centre=(lo+hi)*.5;span=max(hi-lo)
for name,delta in [('front',Vector((0,-3,.1))),('back',Vector((0,3,.1))),('quarter',Vector((-1.2,-3,.65)))]:
 bpy.ops.object.camera_add(location=centre+delta*span);cam=bpy.context.object
 cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.12
 scene.camera=cam;scene.render.filepath=str(OUT/('large_'+name+'.png'));bpy.ops.render.render(write_still=True)
 bpy.data.objects.remove(cam,do_unlink=True)
(OUT/'large_bounds.json').write_text(json.dumps({'lo':list(lo),'hi':list(hi)},indent=2))
