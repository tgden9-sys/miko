# Bridge channel trial

## Elevated camera revision

Replaced the eye-level converging corridor artwork with `service_channel_ortho.png`, an elevated parallel-view service recess generated using built-in image generation. Complete prompt: `Game/art/tutorial/bridge_channel/prompt_ortho.txt`. Previous image retained. Generated original: `exec-69afa06b-755f-41c7-b43f-13003ed3dc6c.png`.

Camera pitch is atan(7/18), approximately 21.25 degrees. The image card now faces that camera with rotation.x=-atan(7/18), anchored by its upper edge. This preserves the authored screen proportions without projecting an already tilted view onto another vertical wall. Image generation approximates the requested projection; it is not a calibrated architectural render. The back wall dominates the visible crop, avoiding the former central tunnel horizon.

Research: https://docs.godotengine.org/en/latest/classes/class_camera3d.html explains orthographic projection and world-to-screen projection. Placement tests now additionally verify that the artwork normal matches the camera normal. All three captures passed after this revision.

A separate painted dry service recess behind the existing bridge. No gameplay, collision, walkway or camera framing changes. No water. The overhead world remains reserved for subsequent parallax work.

Artwork: `Game/art/tutorial/bridge_channel/service_channel.png`, generated with built-in image generation from the approved substation courtyard concept. Original generated output: `exec-b5b37681-bc17-4649-a9a2-9ac566c5c299.png`. The maintenance illumination is painted into the artwork; a separate low-opacity shader adds slow mist.

The 12 by 6 metre image sits at z=-3.5, top y=-0.85, centred on bridge x=33. Local parallax offset is `(camera_x-33)*0.18`, keeping the recess anchored to the opening while providing depth motion. Foundations conceal the overscan edges.

Validation: `verify_miko8_bridge_channel.gd` passed at camera x=28,33,38. Checks placement behind the bridge, top below the projected rear deck edge, horizontal coverage, and anchored parallax. Actual 1920x1080 captures are `Source/Environment/OrthographicJoinTest/channel_view_*.png`. This is a visual trial, not a completed background layer.
