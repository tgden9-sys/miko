import bpy,os,json
BASE=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=30
report={}
for p,ds,fs in os.walk(os.path.join(BASE,'Turns')):
    for f in fs:
        if not f.endswith('.glb'):continue
        before=set(bpy.data.objects);ba=set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=os.path.join(p,f))
        rigs=[o for o in set(bpy.data.objects)-before if o.type=='ARMATURE']
        if not rigs:
            print('OBJECTS',[(o.name,o.type,o.parent.name if o.parent else '',list(o.location),list(o.rotation_euler)) for o in set(bpy.data.objects)-before],flush=True)
            print('ACTIONS',[(a.name,list(a.frame_range),[s.identifier for s in a.slots]) for a in set(bpy.data.actions)-ba],flush=True)
            continue
        rig=rigs[0];a=next(iter(set(bpy.data.actions)-ba))
        names=[b.name for b in rig.data.bones]
        print(f,rig.name,a.name,list(a.frame_range),'BONES',names,flush=True)
        print('REST',[(b.name,list(b.head_local)) for b in rig.data.bones if 'hip' in b.name.lower() or 'root' in b.name.lower() or 'pelvis' in b.name.lower()],flush=True)
        report[f]={'action':a.name,'frames':list(a.frame_range),'bones':names}
with open(os.path.join(BASE,'turn_source_analysis.json'),'w') as f:json.dump(report,f,indent=2)
