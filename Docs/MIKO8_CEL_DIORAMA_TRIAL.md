# Cel scenery with diorama background lighting

Playable trial: `Game/scenes/miko8_ortho_repetition.tscn`, opened by the existing `Preview 5 Concrete - Bridge - 4 Concrete.cmd`. The separate older tutorial main scene and movement demo remain available. This is a real Godot art-direction trial, not the generated comparison board.

## Changes

- Replaced the painted near-background images with three native bevelled 3D kits: transformer, twin ventilation fans and service room. Ten placements share these resources. Source: `Source/Environment/CelDiorama/build.py`; exports: `Game/models/environment/cel_diorama`.
- Preview ground uses the original native concrete services, coping, rails, deck and bridge geometry with cleaner materials and softened cel-light bands. Painted front cards and texture foliage are omitted in this trial. The existing ground script defaults remain available to other scenes.
- Darkened and lowered the equipment so it does not obscure the distant city. Shared overhead cables join consistently across the six-metre bays.
- Visible warm lamp lenses, restrained additive halos, cyan instrument strips and real local light pools. The bridge opening is a quiet native 3D recess with descending pipes, replacing the painted tunnel.
- Two independent city layers at parallax factors 0.10 and 0.25; equipment at 0.70. Far city has more haze and blur. Camera depth offsets are compensated using the fixed pitch atan(7/18).
- City uses one transparent soft-focus bitmap shared between both layers. Built-in image generation created a miniature-render-style panorama, with full prompt saved at `Game/art/tutorial/cel_diorama/prompt.txt`. Source output: `exec-0a8556cd-5568-4d64-954d-9a68f0409deb.png`; installed asset: `Game/art/tutorial/cel_diorama/bokeh_city.png`. This is a bitmap background, not real-time city geometry or camera depth-of-field.

Compatibility rendering does not support native depth-of-field blur; the fixed soft-focus layer is deliberate. See [Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html). The lighting shader follows [Godot spatial light processing](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html).

## Validation

`verify_miko8_repetition.gd`: PASS for wake, all eight tested joins, 5/1/4 layout and room-end camera bounds. Movement/animation scripts and continuous collision floor are unchanged.

`verify_miko8_cel_trial.gd`: PASS for ten native bays, omitted painted front cards, native bridge recess, separate city layers, parallax offsets and off-camera bay culling. Five actual 1920x1080 gameplay captures: `Source/Environment/CelDiorama/game_view_*.png`.

No claim of locked FPS is made. Art direction is a first playable test; three kit types repeat across the long room. Original artwork remains on disk; the prior preview script is preserved at `Source/Environment/CelDiorama/painted_preview_before.gd.txt`.
