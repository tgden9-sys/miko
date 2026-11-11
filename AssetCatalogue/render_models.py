"""Run with Blender --background --factory-startup --python render_models.py."""
from pathlib import Path
import hashlib
import bpy
from mathutils import Vector

folder = Path(__file__).resolve().parent
root = folder.parent
output = folder / "thumbnails"
output.mkdir(exist_ok=True)
for model in sorted((root / "Game").rglob("*.glb")):
    relative = model.relative_to(root).as_posix()
    if "/." in relative:
        continue
    key = hashlib.sha256(relative.lower().encode()).hexdigest()[:10]
    target = output / (key + ".png")
    if target.exists() and target.stat().st_mtime >= model.stat().st_mtime:
        continue
    try:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(model))
        points = [obj.matrix_world @ Vector(corner) for obj in bpy.context.scene.objects
                  if obj.type == "MESH" for corner in obj.bound_box]
        if not points:
            continue
        lower = Vector(min(p[i] for p in points) for i in range(3))
        upper = Vector(max(p[i] for p in points) for i in range(3))
        center = (lower + upper) / 2
        size = max(max(upper - lower), .01)
        bpy.ops.object.camera_add(location=center + Vector((-1.4, -3, 1.45)) * size)
        camera = bpy.context.object
        camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = size * 1.45
        camera.data.clip_end = size * 12 + 10
        scene = bpy.context.scene
        scene.camera = camera
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.color_type = "TEXTURE"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.show_cavity = True
        scene.render.resolution_x = 420
        scene.render.resolution_y = 340
        scene.render.resolution_percentage = 100
        scene.render.film_transparent = True
        scene.render.image_settings.file_format = "PNG"
        scene.render.filepath = str(target)
        bpy.ops.render.render(write_still=True)
    except Exception as error:
        print("PREVIEW FAILED", relative, error, flush=True)
