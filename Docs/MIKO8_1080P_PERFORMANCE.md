# 1080p check and gameplay mesh

27 October 2026, Godot 4.7.2 Compatibility renderer, Intel Iris Xe. Confirmed actual window, viewport texture and render target 1920x1080; monitor approximately 60Hz. These are desktop development-build samples, not a guarantee for every future scene or hardware configuration.

## Measurements

Uncapped benchmarks explicitly disabled V-sync and the frame limiter. Eight-second idle and running samples, with looping travel on the first flat section. Warm-up before each scene; final confirmation increased warm-up to 20 seconds. Samples include frame-time percentiles. Other desktop activity/system state was not controlled, and measurements varied appreciably between runs.

| Latest long-warm-up pass | Idle average | Running average | Running p95 / p99 frame time |
|---|---:|---:|---:|
| Original 951,548-triangle character, simplified ambience geometry | 38.98 FPS | 37.97 FPS | 38.45 / 50.10 ms |
| Gameplay 76,123-triangle character, same environment | 74.83 FPS | 74.69 FPS | 25.90 / 27.85 ms |

The earlier repeated comparison, before reducing tiny bulb/dust sphere tessellation, measured approximately 77 FPS original versus 140–141 FPS reduced. Those higher numbers are retained as evidence, not presented as a guaranteed current rate. The first short cold sample measured 33 FPS and was unsuitable as a steady baseline. Hiding MIKO's rendered model in the initial isolation pass reached 158 FPS with actor logic retained. Automatic mesh LOD-bias changes did not materially remove the original geometry or improve the warm repeat.

Latest running frame time is substantially improved, but percentile measurements still include frames above 16.67ms. This is not a certified locked-60 result. Normal play restores default V-sync in a separate process, targeting the 60Hz display; F3 toggles a live FPS/resolution label. The label logs one live snapshot after ten seconds when visible. No permanent uncapped setting was added to normal play.

## Changes

Only the tutorial selects `Game/models/miko8/MIKO8_GameLOD.glb` by default. `use_game_lod` on the tutorial scene or the `--full-mesh` user argument selects the full source for comparison. The movement/ladder/spell review still defaults to the original mesh for detailed examination.

- Triangles: 951,548 to 76,123 (92% reduction).
- Exported vertex entries: 915,653 to 107,297.
- GLB file: 64.4MB to 11.9MB.
- Same 53-bone skeleton, texture/UV data and base actions; supplementary animation JSON remains shared.
- Original character and animation masters remain untouched. Reduced editable source: `Source/Character/MIKO8/MIKO8_GameLOD.blend`; reproducible builder: `build_game_lod.py`.
- No unweighted vertices; glTF normalizes the strongest four weights as in the existing export pipeline. Animation compression/optimizer disabled in the reduced import to match the original's motion policy.
- Dust motes now use 6 radial segments / 2 rings instead of full-detail sphere defaults; tiny bulbs use 12 / 4. Their shape and placement are retained. This removes roughly 160,000 otherwise unnecessary rendered primitives from the ambience.

## Verification and evidence

`verify_miko8_lod.gd`: all 48 clips, 53 bones, five phases per clip against the full-resolution rig. Maximum sampled local position difference 0; quaternion angular comparison approximately .00138 radians (.079 degrees, including floating-point comparison effects). `verify_miko8_tutorial.gd` passed using the reduced asset: seated opening/transitions, lesson progress, collision, both jump challenges, missed-jump recovery, completion and reset.

Rendered idle, run, jump and seated comparisons are saved under `Builds/Validation/MIKO8/reactions/lod_original_*` and `lod_optimized_*`; run/jump gameplay-size frames visually inspected. Small surface differences are expected from topology reduction; the full model is retained for close-ups.

Benchmark evidence in the same folder:

- fps_1080_baseline.json / .log: initial isolation and LOD-bias experiment.
- fps_1080_lod.json / .log: repeated original/reduced asset comparison.
- fps_1080_final.json and fps_1080_warm_final.log: latest long-warm-up pass reflected in the table.
- game_lod_build.json, lod_rig_check.log, lod_tutorial_check.log: asset and regression checks.

`Play MIKO Tutorial.cmd` now launches 1920x1080. Toggle F3 for live FPS, R / View to restart, M to mute. No PNG replacement of MIKO is needed for this improvement.
