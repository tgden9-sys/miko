# Working and building

## Godot

Open `Game/project.godot` in Godot 4.7.2 and press F5. Godot recreates `.godot`
imports on first open. Keep distributable builds under `Builds`. Export presets
for a distributable executable have not been configured yet.

Useful existing QA entry points (run from this workspace with your Godot executable):

```powershell
& 'C:\Users\tgden\Desktop\Godot_v4.7.2-stable_win64.exe' --headless --path .\Game --fixed-fps 60 --script res://scripts/verify_ladder_v30.gd
& 'C:\Users\tgden\Desktop\Godot_v4.7.2-stable_win64.exe' --headless --path .\Game --fixed-fps 60 --script res://scripts/verify_housekeeping_v29.gd
```

## Character source

Open `Source/Character/robot_neckerchief_aligned_v28.blend` in Blender 5.2.
It includes the retained animation library and packed materials. The Godot-only
powered climb reuses its fixed grip and reverse mount frames; exhaust is procedural.

The source bundle keeps the original versioned filenames for traceability.
The input GLB and pre-swap master are in `source_assets_v28`.
`rebuild_neckerchief_v28.ps1` rebuilds the character from those inputs; it overwrites
generated character files when explicitly run. Export preparation/render scripts
now target this workspace's `Game` folder. Render jobs remain versioned. Re-rendering
the whole library is substantial work; it was not needed for this migration.
`export_nozzle_anchors.py` projects attachment landmarks into Game from the model.

The archived release ZIPs are rollback snapshots. Never extract one over Game
without first preserving any newer work.
