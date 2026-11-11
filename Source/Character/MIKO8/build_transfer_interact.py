"""Export the supplied interaction using Miko's established native retarget mapping."""
import json
import math
import os
import struct
import zipfile
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

source_dir = Path(__file__).resolve().parent
workspace = source_dir.parents[2]
output = workspace / "Game/models/miko8/MIKO8_Interact.json"
template = source_dir / "Templates/Interact/quaternius-ual1-interact.glb"
template.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(Path.home() / "Downloads/interact-alternate-2-1.0.7.zip") as archive:
    template.write_bytes(archive.read("public/humanoid-animation/quaternius-ual1-interact.glb"))

bpy.ops.wm.open_mainfile(filepath=str(source_dir / "MIKO8_Actions_Animated.blend"))
sc = bpy.context.scene
sc.render.fps = 30
rig = bpy.data.objects["MIKO8_Rig"]
rig.animation_data.action = None
for track in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(track)
for bone in rig.pose.bones:
    bone.matrix_basis = Matrix.Identity(4)
rest = {bone.name: bone.matrix_local.copy() for bone in rig.data.bones}
names = list(rest)
C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
D = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
meta = {"clips": {}}
validation = {}
B = str(source_dir)
path = str(template)
native = (source_dir / "export_native_clips.py").read_text()
exec(native[native.index("mapping={'DEF-hips'"):native.index("keep={'Idle_Loop'")])
conversion = native[native.index(" raw=open(path,'rb').read()"):native.index("# Inspect native contact trajectories")]
conversion = "\n".join(line[1:] if line.startswith(" ") else line for line in conversion.splitlines())
conversion = "\n".join('label="RelayInteract"' if line.startswith("label=") else line for line in conversion.splitlines())
exec(conversion)

rig.animation_data.action = action
rig.animation_data.action_slot = action.slots[0]
clip = meta["clips"]["RelayInteract"]
clip["frames"] = []
for frame in range(count + 1):
    sc.frame_set(frame)
    bpy.context.view_layer.update()
    pose = {}
    for bone in rig.data.bones:
        matrix = rig.pose.bones[bone.name].matrix.copy()
        local = rig.pose.bones[bone.parent.name].matrix.inverted() @ matrix if bone.parent else matrix
        rotation = ((D @ local.to_3x3()) if not bone.parent else local.to_3x3()).to_quaternion()
        position = D @ local.translation if not bone.parent else local.translation
        pose[bone.name] = {"p": list(position), "q": [rotation.x, rotation.y, rotation.z, rotation.w]}
    clip["frames"].append(pose)
output.write_text(json.dumps(meta))
(workspace / "Builds/Validation/NetworkTransfer/retarget.json").write_text(json.dumps(validation, indent=2))
print("TRANSFER_INTERACT_EXPORTED", clip["duration"], len(clip["frames"]))
