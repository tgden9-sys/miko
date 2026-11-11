"""Inventory the publisher's FBX clips without running Unreal or changing MIKO."""
import bpy
import json
from pathlib import Path
from mathutils import Vector

folder = Path(__file__).resolve().parent
report = []
for source in sorted((folder / 'Source').glob('*.fbx')):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(source), use_anim=True)
    rigs = [obj for obj in bpy.context.scene.objects if obj.type == 'ARMATURE']
    record = {'file': source.name, 'rig_count': len(rigs), 'rigs': []}
    for rig in rigs:
        action = rig.animation_data.action if rig.animation_data else None
        entry = {'name': rig.name, 'bones': [b.name for b in rig.data.bones]}
        if action:
            start, end = action.frame_range
            entry['frames'] = [start, end]
            entry['duration_s'] = (end - start) / bpy.context.scene.render.fps
            animated = set()
            for layer in action.layers:
                for strip in layer.strips:
                    for bag in strip.channelbags:
                        for curve in bag.fcurves:
                            if curve.data_path.startswith('pose.bones['):
                                animated.add(curve.data_path.split('"')[1])
            entry['animated_bones'] = sorted(animated)
            samples = {}
            for bone in rig.pose.bones:
                if any(part in bone.name.lower() for part in ['foot', 'hand', 'pelvis']):
                    samples[bone.name] = []
            for frame in range(11):
                at = start + (end - start) * frame / 10
                bpy.context.scene.frame_set(int(at), subframe=at-int(at))
                for name in samples:
                    samples[name].append(rig.matrix_world @ rig.pose.bones[name].matrix.translation)
            entry['sampled_travel_m'] = {
                name: max((a-b).length for a in positions for b in positions)
                for name, positions in samples.items()
            }
        record['rigs'].append(entry)
    report.append(record)
    print('FBX_PACK_CLIP', source.name, json.dumps(record), flush=True)
(folder / 'inventory.json').write_text(json.dumps(report, indent=2))
print('FBX_PACK_INSPECTED', len(report), flush=True)
