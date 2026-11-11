import bpy,json,os
bpy.ops.wm.read_factory_settings(use_empty=True)
p=os.path.dirname(__file__)
bpy.ops.import_scene.fbx(filepath=p+'/A_Ladder_Up_Loop.fbx')
for o in bpy.data.objects:
 print('OBJECT',o.name,o.type,list(o.scale),list(o.rotation_euler))
 if o.type=='ARMATURE':
  for b in o.data.bones: print('BONE',b.name,b.parent.name if b.parent else '',list(b.head_local),list(b.tail_local))
for a in bpy.data.actions:print('ACTION',a.name,list(a.frame_range))
print('FPS',bpy.context.scene.render.fps)
bpy.ops.wm.save_as_mainfile(filepath=p+'/VanillaLoop_source.blend')
