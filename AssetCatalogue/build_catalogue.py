"""Refresh catalogue data. Existing IDs survive additions and reordering."""
from pathlib import Path
from urllib.parse import quote
import hashlib
import json

folder = Path(__file__).resolve().parent
root = folder.parent
formats = {
    ".glb": "3D models", ".gltf": "3D models", ".obj": "3D models",
    ".tscn": "Scenes", ".blend": "Blender sources", ".fbx": "Animation and interchange",
    ".zip": "Animation and interchange", ".png": "Images", ".webp": "Images",
    ".jpg": "Images", ".jpeg": "Images", ".svg": "Images", ".gif": "Images",
    ".wav": "Audio", ".ogg": "Audio", ".mp3": "Audio",
}
featured = {}

def feature(path, identifier, name, use, preview=None):
    featured[path] = (identifier, name, use, preview)

models = "Game/models/"
for size, height in [("small", 2.8), ("medium", 3.55), ("large", 4.3)]:
    feature(models + f"environment/platform_towers_v2/{size}.glb", f"MIKO-TOWER-{size.upper()}",
            f"{size.title()} platform tower", f"{height:.2f} m deck. Matched steel and amber set with a 2.0 × 1.6 m cap and optional ladder.")
for file, identifier, title, note in [
    ("environment/level2_props/endcap.glb", "DECK-CLOSED", "Closed-end platform", "Closed end for the bottom of a stack. Current Level 2 modules are 5 m long."),
    ("environment/level2_props/platform.glb", "DECK-OPEN", "Open-end platform", "Open passage beneath its deck. Used on top of the closed-end module."),
    ("environment/level2_props/canister.glb", "CANISTER", "Energy canister", "Collectible with an upright, hovering cyan energy presentation in Level 2."),
    ("environment/pressure_switch_v2/pressure_switch_v2.glb", "SWITCH", "Sealed pressure switch", "Walk-on plate. Green when ready, purple under Miko or a crate."),
    ("environment/plain_block/plain_block.glb", "BLOCK", "Plain building block", "Reusable building body for reskinning and traversal layouts."),
    ("environment/ladder_building/ladder_building.glb", "BUILDING-LADDER", "Ladder building", "Building body for the existing front ladder and roof landing."),
    ("environment/overhang_building/overhang.glb", "OVERHANG", "Overhang building", "Industrial overhang for downward-facing magnetic pad puzzles."),
    ("environment/workshop/workshop.glb", "WORKSHOP", "Workshop building", "Workshop obstacle model."),
    ("environment/bridge_platforms/deck.glb", "BRIDGE-DECK", "Bridge deck", "Centre module for the rooftop bridge."),
    ("environment/bridge_platforms/cantilever.glb", "BRIDGE-CANTILEVER", "Bridge cantilever", "Supported end module for the rooftop bridge."),
    ("props/wooden_crate.glb", "CRATE-WOOD", "Wooden crate", "Breakable with the purple plasma bolt."),
    ("props/metal_crate.glb", "CRATE-METAL", "Metal crate", "Movable magnetic puzzle crate."),
    ("props/heavy_cargo/heavy_cargo.glb", "CRATE-HEAVY", "Heavy cargo crate", "Larger cargo model for magnetic puzzles."),
    ("props/charge_base/charge_base.glb", "LAUNCHER", "Charge launcher", "Stationary neutral, red and blue charge base."),
    ("props/mag_pad/mag_pad.glb", "MAG-PAD", "Magnetic pad", "Mount on walls or overhead for crate puzzles."),
    ("props/loader.glb", "LOADER", "Walk-through loader", "Walk-through prop with green, red and blue states."),
    ("miko8/MIKO8_Native.glb", "CHARACTER", "Miko", "Current playable character and native rig."),
]:
    feature(models + file, "MIKO-" + identifier, title, note)

for file, number, name, preview in [
    ("miko8_side_on_mockup", 1, "Service Yard", "toned_level1_height0.png"),
    ("miko8_level_02", 2, "Pump Works", "toned_level2_height0.png"),
    ("miko8_level_03", 3, "Freight District", "toned_level3_height0.png"),
]:
    feature(f"Game/scenes/{file}.tscn", f"MIKO-LEVEL-{number}", name, "Playable level.",
            "Builds/Validation/Level2Props/" + preview)

def relative_url(path):
    return "../" + quote(path, safe="/")

entries = []
roots = ("Game", "Source", "Concepts", "AnimationTemplates", "Previews")
for location in roots:
    for file in sorted((root / location).rglob("*")):
        if not file.is_file() or file.suffix.lower() not in formats:
            continue
        path = file.relative_to(root).as_posix()
        if any(part.startswith(".") for part in Path(path).parts):
            continue
        kind = formats[file.suffix.lower()]
        key = hashlib.sha256(path.lower().encode()).hexdigest()[:10]
        name = file.stem.replace("_", " ").replace("-", " ")
        identifier, name, use, preview = featured.get(path, ("MIKO-" + key.upper(), name, "", None))
        thumb = f"thumbnails/{key}.png"
        image = relative_url(path) if kind == "Images" else None
        if preview and (root / preview).is_file():
            image = relative_url(preview)
        if (folder / thumb).is_file():
            image = thumb
        entries.append(dict(id=identifier, name=name, note=use, category=kind, collection=location,
                            path=path, url=relative_url(path), image=image,
                            size=file.stat().st_size, featured=path in featured))

for identifier, name, source, image, note in [
    ("MIKO-STACK", "Closed + open platform stack", "Game/scripts/miko8_level2_props.gd",
     "Builds/Validation/Level2Props/two_storey_stack.png", "Reusable arrangement of MIKO-DECK-CLOSED and MIKO-DECK-OPEN. Jump into the upper frame at 2.63 m."),
    ("MIKO-TOWER-COURSE", "Tower course", "Game/scripts/miko8_platform_tower_course.gd",
     "Builds/Validation/TowerArtRevision/course_overview.png", "Level 2 traversal at X 40 m. Five towers lead to a final jump into a platform stack at X 57.65 m. The preview shows an earlier course layout."),
]:
    entries.append(dict(id=identifier, name=name, note=note, category="Assemblies", collection="Game",
                        path=source, url=relative_url(source), image=relative_url(image),
                        size=0, featured=True))

assert len({entry["id"] for entry in entries}) == len(entries), "Duplicate asset ID"
entries.sort(key=lambda entry: (not entry["featured"], entry["category"], entry["name"].lower(), entry["path"]))
(folder / "assets.js").write_text("const ASSETS = " + json.dumps(entries, ensure_ascii=True) + ";\n", encoding="utf-8")
print(f"{len(entries)} records, {sum(bool(entry['image']) for entry in entries)} previews")
