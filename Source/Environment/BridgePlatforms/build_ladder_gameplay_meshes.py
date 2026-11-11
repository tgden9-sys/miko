"""Build low-detail ladder kit meshes for Level 4's gameplay camera."""
import bpy
from pathlib import Path

kit = Path(__file__).resolve().parents[3] / 'Game/models/environment/industrial_ladder'
for name in ('grip_rung', 'rail_1m', 'roof_return', 'wall_standoff'):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(kit / f'{name}.glb'))
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH':
            continue
        bpy.context.view_layer.objects.active = obj
        decimation = obj.modifiers.new('Gameplay detail', 'DECIMATE')
        decimation.ratio = .24
        decimation.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=decimation.name)
    bpy.ops.export_scene.gltf(filepath=str(kit / f'{name}_gameplay.glb'), export_animations=False)
