# Restored preview verification

Verified on 29 October 2026 with Godot 4.7.2, using the normal game LOD, a 1920×1080 viewport and the headless renderer. The independent verifier is `Game/scripts/verify_miko8_restored_preview.gd`. It does not save or overwrite any screenshots.

The continuous yard is now the enhanced default. Its sixth module uses the same native concrete ground as the rest of the route, with the same repeated photographic front. `--keep-bridge` retains the earlier enhanced five concrete / bridge / four concrete route. `--restored-baseline` keeps that route with its original connected foundation library.

Latest headless results:

| Mode | Checks | Failures | Foundation fronts | Bridge grating/fastener batches | Exit code |
| --- | ---: | ---: | ---: | ---: | ---: |
| Default enhanced yard | 166 | 0 | 10 | 0 | 0 |
| Enhanced `--keep-bridge` | 162 | 0 | 9 | 4 | 0 |
| `--restored-baseline` | 115 | 0 | 9 distinct | 4 | 0 |

All three modes verify:

- Ten six-metre native modules in the selected order, one continuous 60m floor and the expected number of flat 6×2m foundation fronts in their original positions. The active `module_order` matches the actual instantiated module names. Cel and diorama conversions remain disabled.
- The continuous yard disables bridge details and contains no leftover grating or fastener MultiMeshes. Retained-bridge modes keep their real lattice and have no painted replacement on the bridge front.
- Seated start, wake and movement through the full native sit-exit animation; walking through eight internal module boundaries, including x=30 and x=36, with no drop or required jump.
- The frozen physical crate at x=54 blocks horizontal movement. A real input-driven jump clears its 0.8m height and lands beyond x=55 on the same floor.
- The R-key reset handler returns MIKO to the seated start at x=2.4.
- Orthographic sizes 11.25 and 15 at the route's left, middle and right positions, correct horizontal clamps and the same 7:18 downward camera pitch. Enhanced mode defaults to the approved size 15; `--original-view` selects 11.25. `--wide-view` remains a force-wide option. The baseline defaults to 11.25.

Enhanced original framing places the floor at normalized Y 0.6656897, approximately 718.945px at 1080px. Approved wide framing adds 1.2m to the camera's target height while retaining its pitch, placing the floor at normalized Y 0.7402501, approximately 799.470px. The wide framing is therefore 80.525px lower at 1080px. Size 15 gives 75% of the original projected character scale. Each floor row remains constant across all three route positions. The baseline preserves its previous normalized floor row when its view size changes.

The enhanced routes additionally verify that all concrete fronts share the same new material and imported `miniature_concrete_repeat_v1.png` texture, without falling back to the older library. Projected city-card corners cover the viewport at all six combinations of camera size and route position, including the lower wide framing. The card faces the camera's fixed pitch. Air particles have a 60m simulation range and matching draw bounds, with actual motes in the far third of the route. Exactly one reflection probe is created with `UPDATE_ONCE`; its instance remains stable across frames and excludes the actor's rendering layer.

The baseline route additionally verifies that its original sequence of nine distinct connected foundation paintings is retained.

Run from the repository root, substituting the local Godot executable path:

```powershell
& 'C:/Users/tgden/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path Game --script res://scripts/verify_miko8_restored_preview.gd --fixed-fps 60 --resolution 1920x1080
& 'C:/Users/tgden/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path Game --script res://scripts/verify_miko8_restored_preview.gd --fixed-fps 60 --resolution 1920x1080 -- --keep-bridge
& 'C:/Users/tgden/Desktop/Godot_v4.7.2-stable_win64.exe' --headless --path Game --script res://scripts/verify_miko8_restored_preview.gd --fixed-fps 60 --resolution 1920x1080 -- --restored-baseline
```

The Windows GUI executable may detach from a PowerShell pipeline; use `Start-Process -WindowStyle Hidden -Wait -PassThru` with redirected output when collecting an exit code and complete logs. A writable temporary `--log-file` can be supplied when the default Godot user-data log location is unavailable.

These runs verify physics, scene configuration and mathematical projection. They do not measure GPU performance or establish the visual quality of the new photograph, reflected lighting or texture joins. No GPU render, FPS measurement or capture was made by this verifier.
