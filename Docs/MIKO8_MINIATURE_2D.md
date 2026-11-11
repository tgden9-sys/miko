# Miniature scenery as 2D artwork — one-screen proof

## Framing revision

MIKO is now25% smaller in projection: camera height changed11.25→15 world units; character and collision dimensions did not change. Full16:9 field is26.667m wide. Floor y0 projects to720px at1080p, one-third up from the bottom. The near image shifts down136.8px to keep its baked walking line aligned with the physical floor; additional city appears above and less foundation occupies the bottom. Crate/spawn/light x positions maintain their original proportional placement.

Current framing captures: `Source/Environment/Miniature2D/game_4.0.png`, `game_13.333333.png`, `game_21.333333.png`. Earlier capture names below describe the initial framing.

## Actual game implementation boundary

This remains a fixed visual proof. The present card is camera-attached and cannot be treated as a scrolling platform kit. The next game test should use world-anchored individual platform scenes: a top-edge anchor, separate deck/front/foreground imagery where needed, and an aligned collision box. Build a two-screen route containing joined floor pieces, three low ledges, and a foreground railing. Validate camera following, jumps, landings, walking off, shadow placement and railing occlusion before authoring more artwork. Keep the city independent at slower parallax rates.

Initially use a few standard ledge heights and depths, with separate top caps and wall sections for taller structures. Do not stretch whole detailed images to arbitrary heights. Walls and ladders require their own art/collision/interaction assets. MIKO's grounded appearance needs local light matching, animated foot contact, shadows, and selective foreground occlusion; the new framing alone does not finish this work.

Open `Preview Miniature 2D.cmd`. Scene: `Game/scenes/miko8_miniature_2d.tscn`. Renderer: Compatibility/OpenGL at 1920x1080. This is a playable image-based scene; screenshots under `Source/Environment/Miniature2D` are actual Godot captures with the live 3D character.

## Installed artwork

Built-in image generation created both images using the bottom-right miniature-diorama panel of `Concepts/StyleAlternatives/four_directions.png` as reference. No CLI fallback, no generated paintover presented as a runtime screenshot.

- `Game/art/tutorial/miniature_2d/bridge_stage.png`: 1672x941 RGBA. Detailed near substation, ground, bridge, foundations and channel sides. Actual transparent upper sky/city opening and opening beneath the bridge. Source output `exec-141dc28e-a587-4378-bdbb-7abe92434239.png`.
- `Game/art/tutorial/miniature_2d/city_backdrop.png`: 1672x940 RGB. Recognisable layered city with selective bokeh and progressively softer depth. Source output `exec-328289ad-569f-4ba6-b099-cd5bd121e5f7.png`.
- Complete prompts: `Game/art/tutorial/miniature_2d/stage_prompt.txt` and `city_prompt.txt`.

Source resolution is approximately 1.6 MP, displayed at 1080p with linear sampling. These are not native 4K assets. Lossless imports, no mipmap blur, no extra fog or tint applied to the images.

## Integration

Two camera-facing cards preserve the source proportions and pre-rendered lighting. Stage depth24, opaque city depth28; live MIKO and crate remain closer to the camera. There is no visible native ground, 3D city, primitive replacement scenery, or additional native railing.

Camera is strictly orthographic at19 degrees downward,20m horizontal field and11.25m vertical field. The rendered art's common walking line was measured at54% of image height, not the60% requested in the prompt. Accordingly floor y0,z0 projects to583.2px at1080p. This keeps the feet on the bridge deck rather than the front girder. Actual actor shadow and foot patches remain. Collision is a hidden20m continuous floor with boundaries and the real 3D crate.

The one-screen camera is fixed. The city is overscanned4.5% and drifts at most12px against actor progression to demonstrate separate layers. This is not a completed four-layer scrolling level.

## Joins and long-level work

This image proves the visual direction and character integration. It is not a seamless terrain tile. The generated near image retains some baked perspective, so the orthographic game camera alone does not make its pavement lines suitable for arbitrary repetition.

Before extending the room, author dedicated concrete/bridge/concrete pieces with strictly parallel depth lines, a common source pixel density, identical walking/deck/front-edge rows, shared light direction and planned end sockets. Keep quiet overlap zones; mask edges with purpose-built structural caps/abutments. Test adjacent pieces at native gameplay scale before generating a library. City and skyline imagery remain separate so they can move at slower parallax rates. No claim is made that this screen can simply repeat unchanged for the full tutorial.

## Verification

`verify_miko8_miniature_2d.gd` passed: orthographic pixel alignment, transparent near layer, live wake, jump and landing, and crate collision. Existing character/animation scripts were not changed.

Short steady 1920x1080 test measured60.3 frames/s on the current laptop. Screenshot capture briefly stalls the renderer, so instantaneous FPS during PNG saving was excluded. This is a small scene result, not a full-level performance guarantee.

Actual game captures: `Source/Environment/Miniature2D/game_3.0.png`, `game_10.0.png`, `game_16.0.png`. Logs: `Builds/miniature_2d_verify.log` and `miniature_2d_review.log`.
