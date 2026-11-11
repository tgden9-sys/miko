import bpy
from pathlib import Path

root = Path(bpy.data.filepath).resolve().parents[3]
parts = {"Drone_Body": 10500, "Left_Blaster": 1800, "Right_Blaster": 1800}
bpy.ops.object.select_all(action="DESELECT")
for name, budget in parts.items():
    part = bpy.data.objects[name]
    bpy.context.view_layer.objects.active = part
    for modifier in list(part.modifiers):
        if modifier.type == "ARMATURE":
            part.modifiers.remove(modifier)
    part.data.calc_loop_triangles()
    decimate = part.modifiers.new("Gameplay triangle budget", "DECIMATE")
    decimate.ratio = min(1.0, budget / len(part.data.loop_triangles))
    decimate.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    part.data.calc_loop_triangles()
    part.select_set(True)
    print(name, len(part.data.loop_triangles), flush=True)
bpy.ops.export_scene.gltf(
    filepath=str(root / "Game/models/enemies/security_drone/security_drone.glb"),
    use_selection=True, export_animations=False, export_apply=True, export_yup=True,
)
