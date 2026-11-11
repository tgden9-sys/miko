# Follow-up — 28 October 2026

## Camera and activity budget

Godot's normal 3D frustum culling remains in use. Additional camera-relative bounds now hide registered static visuals outside a buffered horizontal view, with extra margin for shadow-casting objects. This does not remove intentional distant backgrounds that are still visible in the scene.

`miko8_visibility_budget.gd` updates at 5Hz. Generated scene boxes/pipes/art panels register their bounds in `miko8_budget_visual`. Future non-player actors opt into `miko8_budget_actor`: their `set_camera_active(active)` hook is preferred; otherwise inherited processing/animation and visibility are paused outside a 5m activity margin and restored on approach. The player is explicitly exempt. Metadata `budget_activity_margin` adjusts the safety margin; `budget_always_simulate` opts critical actors out. Global puzzle controllers and mechanisms whose state must progress off screen should not use the generic actor pause; they need a specific hook or opt-out.

Crates use a dedicated hook. Their display hides offscreen; neutral, already-sleeping bodies stop unnecessary script ticks. Moving bodies can settle normally, and charge expiry continues offscreen. No distant object is deleted or reset. Air motes are compacted into a camera-local visible instance range so the batch does not draw the entire room's particle pool. Particle/shadow positions also support translated room roots.

## Opening animation

The 30-degree head correction is now weighted continuously: it fades out while sitting, remains at zero during the seated idle, and fades in during the first 80% of GroundSitExit. Full correction is reached before the clip hands off to locomotion. Reset restores full standing correction. The animation preview uses the same curves.

The frame-by-frame check recorded a maximum weight increment of .01538 per physics step, and full weight before completion. This replaces the previous inactive/active switch at the end, which caused the visible snap.

## Foreground

Each upper/lower foreground band is now a single 40m-wide piece spanning this 32m room. Texture ends remain beyond all legal camera views (including parallax travel), so no repeated asset edges meet inside the room. The original blurred artwork and lighting are retained. New room sizes must size their own foreground coverage rather than butt these non-tileable pictures together.

## Cube

Game-ready copy: 5,272 triangles, down from 989,231, with the original retained. A clean rebuild/bake replaced an unsuccessful direct-decimation trial. Red/blue charge affects inset panels; frame/corner colours remain neutral. One cube is placed at the far end of the tutorial, and the old ability-review placeholder boxes also use the model. The tutorial still teaches movement only. See Source/Props/MetalCrate/README.md for asset source and rebuild instructions.

For a wooden version, the frame can be reused for a wood-panel hybrid, while a conventional wood crate should have its own slats/joints and silhouette. Planned active enemies remain 3D, with smaller gameplay meshes, LOD where appropriate and this opt-in offscreen activity handling; distant decorative figures can remain painted.

## Checks

verify_miko8_followup.gd passed: monotonic seated head correction, offscreen visual/actor pause and restore, continuing offscreen charge expiry, particle compaction, crate reactivation and continuous foreground coverage. verify_miko8_crate.gd passed and neutral/red/blue renders inspected. Full tutorial sit/walk/run/jump/collision/recovery/completion/reset regression passed with the cube installed. Logs and images are in Builds/Validation/MIKO8/art_revision. These are functional and visual checks, not a new large-world or crowd performance benchmark.
