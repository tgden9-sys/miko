# Connected miniature 2D screens

Open `Preview Miniature 2D.cmd` or `Preview Miniature Two Screens.cmd`. The one-screen prototype remains in `Game/scenes/miko8_miniature_2d.tscn`.

## Playable route

Two fixed world-space image cards span53.333m. An eased following camera shows26.667m at a time, clamping at the first/last screen. The physics floor is one continuous surface across the image boundary. The crate is on the second section at40m. Character controls/animation scripts are unchanged. MIKO remains25% smaller than the original framing, with grounded feet at720/1080, one-third up from the bottom.

The city is a separate image with15% relative parallax. Its20% overscan is centred over the full drift so no edge becomes visible at either camera limit. The scenery cards remain anchored in world coordinates; they no longer follow the camera like the first proof.

## Art and joining

The original bridge hero image has baked perspective and was not directly repeated. Built-in image generation made an edited bridge cutout and a new adjoining maintenance-yard section, with a second edit correcting its pavement/edge arrangements. These are installed as:

- `Game/art/tutorial/miniature_2d/bridge_stage_ortho.png` — source output `exec-d9c1dd23-58ba-4af4-93d5-f95768ea4db8.png`.
- `Game/art/tutorial/miniature_2d/service_stage.png` — source output `exec-39e36afc-ade9-4197-9ea0-4c6b3fb81f56.png`.
- Original service draft retained as `service_stage_v1.png` — output `exec-8957fbd4-5ab7-4222-a6cc-2c3356eb1dd3.png`.
- Complete prompts: `two_screen_prompt.txt`, `ortho_bridge_prompt.txt`, `ortho_service_prompt.txt` in the same art folder.

The generator did not produce mathematically identical projections from prompt text alone. `miniature_joined_plate.gdshader` registers measured rear pavement, foot and front coping bands to common normalized rows(.505,.54,.605). It also rectifies the slight pavement convergence around the measured vanishing point. The second screen's upper pipe bands are aligned to the first's edge. Sampling outside the upper art canvas is transparent, not texture wrap. No broad fill strip or full-height cover panel is used to hide a mismatched projection.

These are two specifically fitted sections, not a proven arbitrarily interchangeable tile library. New sections still need explicit shared edge datums and an in-game join review. Keep distant city perspective separate from the playable layer.

## Verification

`verify_miko8_miniature_two_screens.gd` passes: floor extent, actor scale, feet row, stage anchors, camera easing/start/middle/end,15% city parallax, walking across the seam in both directions without falling, and reset. Actual1920x1080 captures are under `Source/Environment/Miniature2D/TwoScreens`: `two_screens_first.png`, `two_screens_join.png`, `two_screens_end.png`.

This change provides the connected two-screen flat route. Independently climbable ledges are not added here.
