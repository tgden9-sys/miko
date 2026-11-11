# Cel scene conversion

The playable `miko8_side_on_mockup.tscn` yard enables `miko8_cel_scene.gd` after scenery and props are assembled. Other standalone historical review scenes retain their original artwork.

## Art treatment

- Redrawn near yard and extension, middle city, foreground cutouts, ladder facade, concrete and foundation maps in `Game/art/cel_scene`.
- Workshop has a cel-painted UV atlas, retaining the existing mesh and UVs. The alternate flat facade map is retained as source artwork but is not projected onto the sculpted doors and fittings.
- Shared broad light, middle and shadow bands replace overlapping specular lighting on buildings, paving, ladders, loader, crates and grass. Selective silhouette outlines are used on suitable meshes; the irregular workshop sculpt retains painted contours without an inflated hull pass.
- Moss and ivy retain their cutout shapes with a simplified three-colour olive palette. Grass remains instanced and animated. Newly spawned wooden crate fragments receive the same material treatment.
- MIKO retains the approved three-tone material and original scratches. F8 / the MIKO selector still compares his original shading.
- The far city now defaults to a newly generated cel-painted bokeh image, `Game/art/cel_scene/city_far_bokeh_v1.png`, with graphic tower planes, blue haze and soft amber light discs. It uses the existing card, scale and parallax. F9 / the City selector compares this with the previous image and its subtle shader treatment. The brightness slider controls both. The new image has no additional posterisation applied.
- Scenery brightness defaults to 50%. Stronger source-anchored atmosphere, reusable hardware and local sound are described in `Docs/MIKO8_YARD_ATMOSPHERE.md`.
- Ladder walls use the richer `ladder_facade_v2.png` and `ladder_panels_v2.png`: bolted repairs, stronger slab variation and a worn olive/ochre service band. Roofs and paving keep the quieter concrete tile.
- Rung travel uses a 2.45 playback rate in both directions, with root motion synchronized. Entry, exit and idle retain their 1.7 rate; the animated turn retains its accepted timing.

Original GLBs, textures, animation clips, physical sizes and collision geometry remain available. Materials are converted after assembly, preserving the shader material objects referenced by the colour-changing targets.

## Artwork provenance

Bitmap artwork was generated with the built-in image_gen tool. Prompts and reference paths are recorded in `Source/Environment/cel_scene_prompts.md`. The generated source mapping is in `Source/Environment/cel_scene_assets.json`; final runtime assets are saved inside the project.

Ladder wall revision prompts are in `Source/Environment/cel_wall_revision_prompts.md`; final textures are `Game/art/cel_scene/ladder_facade_v2.png` and `ladder_panels_v2.png`.

The new city image was made with built-in image_gen; its prompt and reference are recorded in `Source/Environment/cel_city_bokeh_prompt.md`.

## Retired MIKO energy wake trial

The user retired the energy wake. Its source remains available but the playable scene no longer loads it or its control. MIKO's approved shading remains unchanged. The legacy `review_miko8_city_wake.gd` now checks the city comparison, brightness, unchanged suit shader and absence of the wake.

`review_miko8_city_wake.gd` passed (`city_wake_accepted.log`, zero failures / no runtime or shader errors). It checks the new and previous city selections, brightness control, actual run/jump emission, idle cleanup, polarity colours, climbing suppression, off toggle and preservation of MIKO's shader. Inspected `city_new.png`, `city_previous.png`, `wake_running.png`, and `wake_jump.png` in the validation folder.

## Review

`review_miko8_cel_scene.gd` captures the start, ladder, courtyard, workshop and roof, verifies the unchanged far texture, climbs up and down the actual ladder, and checks target red/blue/reset state. Logs and captures are in `Builds/Validation/CelScene`.

`verify_miko8_crate_break.gd` exercises an actual released plasma shot, twelve-piece destruction, cleared collision, walking through debris, cleanup and reset. Use the GPU result in `crate_gpu.log`.

Launch `Preview Cel-shaded Scene.cmd` for the playable yard with the normal wider gameplay camera. The `--ladder-top-review` flag is reserved for close inspection. Existing side-on scene launchers also use the new art.

Final GPU review: `final.log` reports `CEL_SCENE_REVIEW failures=0 converted=44`, with no runtime/shader errors in `final_error.log`. Crate GPU verification reports `CRATE_BREAK_PASS failures=0`; all destruction, cleanup and reset assertions passed. Captures inspected at the start, ladder, courtyard, workshop, roof and crate impact.

Wall/bokeh/speed revision: `wall_review.log` passes scene traversal, target colours and the bokeh brightness control. `ladder_speed.log` reports `BPG_LADDER_PASS failures=0`, with 1,128 hand/foot samples and maximum source-motion error 0.00456m. This covers both ladders, floor support, top/bottom entry/exit, holding, reversing, jumping and reset. GPU captures use the normal wider gameplay camera. `--ladder-wall-review` starts beside the ladder without changing camera size.
