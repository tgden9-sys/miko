"""Reproducible lab-only exports. Never saves over a character master."""
import bpy, bmesh, json, pathlib, sys, math, os, struct, glob, tempfile
import numpy as np
from mathutils import Matrix, Vector, Quaternion

ROOT = pathlib.Path(__file__).resolve().parents[3]
B = str(ROOT / 'Source/Character/MIKO8')
OUT = ROOT / 'MovementLab/models'
QA = ROOT / 'Builds/Validation/MovementLab'
temporary = QA / 'export_temp'
temporary.mkdir(exist_ok=True)
tempfile.tempdir = str(temporary)
bpy.context.preferences.filepaths.temporary_directory = str(temporary)
bpy.ops.wm.open_mainfile(filepath=B + '/MIKO8_Actions_Animated.blend')
sc = bpy.context.scene
rig = bpy.data.objects['MIKO8_Rig']
mesh = bpy.data.objects['MIKO8_Mesh']
rig.animation_data.action = None
for t in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(t)
for p in rig.pose.bones:
    p.matrix_basis = Matrix.Identity(4)
sc.frame_set(0)
sc.render.fps = 30
bpy.context.view_layer.update()

# Use the already verified source-basis conversion, with additional lab clips.
text = open(B + '/export_native_clips.py').read()
exec(text[text.index("mapping={'DEF-hips'"):text.index("keep={'Idle_Loop'")])
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
names = list(rest)
meta = {'clips': {}}
validation = {}
C = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
D = Matrix(((1,0,0),(0,0,1),(0,-1,0)))
conversion = text[text.index(" raw=open(path,'rb').read()"):text.index('# Inspect native contact trajectories')]
old = "label=('SprintEnter' if 'enter' in path else 'SprintExit' if 'exit' in path else 'Sprint' if 'sprint' in path else ('Turn180' if '180' in path else 'Turn90')+('Left' if '-l' in os.path.basename(path) else 'Right'))"
conversion = conversion.replace(old, 'label=clip_label')
sources = {
    'GroundPound': ROOT / 'Source/Character/MovementLab/GroundPound/public/humanoid-animation/quaternius-ual2-sword-ground-pound-rm.glb',
    'Dash': next((ROOT / 'Source/Character/MovementLab/Templates/sword-dash-root-motion-1.0.6').rglob('*.glb')),

}
extra = {
    'AirCombo': 'sword-aerial-combo-loop-alternate-2-1.0.4',
    'DoubleJump': 'double-jump-1.0.5',
    'Uppercut': 'sword-upper-cut-root-motion-1.0.3',
    'AirRecovery': 'sword-aerial-a-rec-1.0.4',
    'AirA': 'sword-aerial-a-1.0.4',
    'SwordBlock': 'sword-block-alternate-2-1.0.6',
    'AirIdle': 'sword-aerial-idle-loop-1.0.4',
}
for label, folder in extra.items():
    sources[label] = next((ROOT / 'Source/Character/MovementLab/Templates' / folder).rglob('*.glb'))
for clip_label, src in sources.items():
    path = str(src)
    exec('\n'.join(line[1:] if line.startswith(' ') else line for line in conversion.splitlines()))
    data = meta['clips'][clip_label]
    action = bpy.data.actions['MIKO8_' + clip_label]
    rig.animation_data.action = action
    rig.animation_data.action_slot = action.slots[0]
    data['frames'] = []
    for f in range(round(data['duration'] * 30) + 1):
        sc.frame_set(f)
        bpy.context.view_layer.update()
        values = {}
        for bone in rig.data.bones:
            m = rig.pose.bones[bone.name].matrix.copy()
            local = rig.pose.bones[bone.parent.name].matrix.inverted() @ m if bone.parent else m
            q = ((D @ local.to_3x3()) if not bone.parent else local.to_3x3()).to_quaternion()
            v = D @ local.translation if not bone.parent else local.translation
            values[bone.name] = {'p': list(v), 'q': [q.x,q.y,q.z,q.w]}
        data['frames'].append(values)
    rig.animation_data.action = None
    for p in rig.pose.bones: p.matrix_basis = Matrix.Identity(4)
json.dump(meta, open(OUT / 'LabActions.json', 'w'))
json.dump(validation, open(QA / 'animation_conversion.json', 'w'), indent=2)

# The user deferred further polygon reduction. Retain the exact current
# gameplay geometry, atlas, skin weights and rig; expose only required clips.
source = ROOT / 'Game/models/miko8/MIKO8_FastLOD.glb'
raw = source.read_bytes()
json_size = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20+json_size])
bin_start = 20+json_size
bin_size = struct.unpack_from('<I', raw, bin_start)[0]
binary = raw[bin_start+8:bin_start+8+bin_size]
keep = {'Idle','Sprint','Run','JumpStart','JumpAir','JumpLand'}
doc['animations'] = [a for a in doc['animations'] if a['name'].removeprefix('MIKO8_') in keep]
header = json.dumps(doc,separators=(',',':')).encode()
header += b' ' * ((-len(header))%4)
result = struct.pack('<III',0x46546C67,2,28+len(header)+len(binary))
result += struct.pack('<II',len(header),0x4E4F534A)+header
result += struct.pack('<II',len(binary),0x004E4942)+binary
(OUT/'Miko.glb').write_bytes(result)
triangles = sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
report = {'source':str(source.relative_to(ROOT)),'triangles':triangles,'bones':len(doc['skins'][0]['joints']),
    'bytes':len(result),'geometry_policy':'Exact established FastLOD geometry, UVs, weights and textures. Further reduction deferred at user request.',
    'base_clips':[a['name'] for a in doc['animations']],'extra_clips':{n:c['duration'] for n,c in meta['clips'].items()}}
json.dump(report,open(QA/'asset_report.json','w'),indent=2)
print('LAB_ASSETS_COMPLETE',report,flush=True)
