# Side-on playable mockup

Launch `C:/Users/tgden/Desktop/MIKO/Preview Side-on Mockup.cmd`.

The playable room is now64m long, doubled from32m. The existing Substation Yard and bridge previews are preserved. The approved wide framing remains: a15m orthographic view, with MIKO's floor at80% down the screen,64.8px below the earlier74% framing at1080p. This closes the bottom gap behind the message banner. The default camera pitch is6degrees. F6, or the top-right camera selector, compares the earlier21.25degree angle while keeping MIKO at the same size and floor height.

## What is 3D

MIKO retains his rig, animation, material lighting, movement and ground contact. The real crate and floor collision remain 3D. The narrow visible deck, foundation piers and coping remain 3D; the camera compresses the deck's depth to approximately 21px at1080p. The front foundation images are flat textures on the physical stage.

The original rear rails and pole furniture are removed from duplicated runtime meshes only in this mockup, so they do not separate the actor from the nearby yard buildings. Source GLBs are unchanged. A small rear apron joins the pictured yard to the physical deck and shares the actual paving material. The crate is atx24; a real end collider stops the room atx64. Eleven six-metre visual modules cover one continuous64m physical floor. Movement remains on the original single play plane, apart from the short supported depth step on the ladder landing.

The earlier projecting join piers/caps are hidden in this scene. One thin coping course now separates the dark paving surface from the textured foundation wall. The ground's wall artwork meets the thinner coping directly; there are no raised connector blocks breaking the floor line. Ground coping, the ladder backing and the balcony coping use a shared material sampled from the same concrete photograph as the wall faces, with colour compensation for the scene's blue lighting. The functional floor collision is unchanged.

## Ladder and raised service platform

The 3.20 m service-yard ladder now uses the supplied BP Games FBX set, retargeted onto MIKO. All 16 clips are installed. The rejected generated top pair has been removed from his installed animations. See [current ladder notes](MIKO8_BPG_LADDER.md).

The ladder is at x18.3, with rails ending at the floor height and no extra rungs above the roof. The source top exit pulls MIKO over the floor edge onto the supported rear landing. That landing runs from x17.7 to x18.70 behind the shaft; the main deck runs from x18.70 to x26. Rails are 0.43 m apart and the rung pitch is 0.2648 m, fitted to the retargeted motion. The paving, photographic concrete fascia and worn yellow coping remain.

W/up mounts, climbs and exits automatically. S/down near the landing mark gets back on and descends. Releasing settles the current short step into a supplied idle; Space detaches. While holding, the right stick or I/K/J selects up/down/left look poses. The upper walking lane retains the source's short forward step onto the roof; descent returns to the lower lane. Horizontal walking stays level.

`Game/scripts/review_miko8_bpg_ladder.gd` drives the input sequence and compares live bone/root movement with the retargeted source. It checks the actual floor handoff, foot support, walking, nearby activation, hold, reversal, jump and reset. `verify_miko8_side_on_climb.gd` and `verify_miko8_direct_ladder.gd` run this verification. Reports and captures are in `Builds/Validation/BPGLadder/`. Launch `Preview Ladder Top Animations.cmd` for the closer playable view.

## Independent scenery layers

All parallax cards now default to 70% material brightness. The top-right Scenery brightness slider adjusts them together from 25% to 100%, retaining the setting across actor resets. This affects image cards without changing actor, prop or ground lighting. The middle city card is raised 2.4m in screen-up space so its rooftop silhouettes clear the nearer yard buildings, while retaining its independent parallax. Actual GPU view: Builds/Validation/NewProps/darker_raised_parallax.png.

- Distant city: an opaque cleaned background, relative parallax factor0.10.
- Nearer city rooftops: a transparent extraction of the industrial roof silhouettes, relative factor0.40.
- Service yard: a transparent near building/equipment elevation, relative factor0.95.
- Actor and ground: fixed in the gameplay world, factor1.0.
- Foreground: five independently cropped and blurred pipe, vent and cable silhouettes, relative factor1.12.

The city images share UV space. The cleaned far image replaces the old city image, so the extracted roofs do not sit over a duplicate of themselves. The far and middle cards have shared dimensions and enough overscan for the full37.33m camera journey. The pictures face the actual camera, including the comparison angle. This is an authored64m room, not an indefinitely tiled level kit.

Two34m×8m service-yard cards cover the route. The added collection contains a corrugated annex, a twin-fan pump house and a brick workshop with warm windows. Both use the same ground line and parallax origin. Their2m overlap places a structural corner over the join nearx32. Foreground objects are separate cutouts with transparent margins, rather than strips that must meet edge to edge. They are cropped below the banner or above the upper screen edge to keep the walking route readable.

## Atmosphere

Five localized lamp-haze cards, four vent exhaust wisps, four low drifting mist ribbons,40 warm lamp motes and96 additional airborne particles accompany the existing general air. Mist sits in front of the walking plane, so it can pass across MIKO's legs. Lamp haze and vent exhaust remain behind him, following the yard's parallax and the camera basis. Effects outside the view are hidden; the particles use instanced batches.

Five pictured work lights have matching real warm lights that illuminate MIKO and the deck. A soft warm bounce light balances the blue night light on his suit. The body contact-shadow footprint is0.95m×1.0m, with separate0.44m×0.40m foot shadows. All still ray-check the physical floor and fade with height. Footstep and landing dust use1.5times the original size/count only in this scene. Existing rooms retain their original setting.

F7, or the Atmosphere switch, now controls both the added atmosphere and the original general airborne particles. Turning it off preserves physical contact shadows and footstep/landing feedback. Reset retains the selected option. The effect is layered local air rather than a full-screen fog wash. The scene uses2×MSAA.

## Artwork and prompts

Created using built-in image generation and saved in the project:

- `C:/Users/tgden/Desktop/MIKO/Game/art/tutorial/side_on_mockup/service_yard_cutout.png` — near building/equipment cutout;2172×724 with alpha.
- `C:/Users/tgden/Desktop/MIKO/Game/art/tutorial/side_on_mockup/city_far.png` — cleaned distant city;1672×940, opaque.
- `C:/Users/tgden/Desktop/MIKO/Game/art/tutorial/side_on_mockup/city_mid.png` — nearer rooftop extraction;1672×941 with alpha, mapped to the same UV canvas.
- `C:/Users/tgden/Desktop/MIKO/Game/art/tutorial/side_on_mockup/service_yard_extension.png` — three additional near building fronts;2172×724 with alpha.
- `C:/Users/tgden/Desktop/MIKO/Game/art/tutorial/side_on_mockup/foreground_cutouts.png` — separate pipes, vent and hanging cables;2172×724 with alpha.

Full prompts:

- `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/scenery_prompt.txt`
- `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/city_far_prompt.txt`
- `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/city_mid_prompt.txt`
- `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/extension_building_prompt.txt`
- `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/foreground_cutouts_prompt.txt`

All textures use mipmaps. Actual Godot1080p captures are under `C:/Users/tgden/Desktop/MIKO/Source/Environment/SideOnMockup/`. `Game/scripts/review_miko8_extended.gd` captures six route positions, the atmosphere on/off comparison, and input-driven running/landing. Its final motion check observed up to9 live foot-dust particles during running and confirmed a real airborne/landing transition. Screenshots are not painted over. The GPU review log is `C:/Users/tgden/Desktop/MIKO/Builds/side_on_atmosphere_review.log`.

Physics, grounding, reset, camera and parallax integration are verified by `Game/scripts/verify_miko8_side_on_mockup.gd`. The extended-room run passes171 checks, including actual movement over six new floor joins, end-barrier collision, crate blocking and a real jump. The split images have distinct textures/materials and verified10%/40%/95% relative motion. F7 and the checkbox stop/restart airborne effects and retain their setting across reset. The separate climb verifier passes, including116 supported top-approach walking frames with zero unsupported frames. The headless Dummy renderer does not expose per-mote MultiMesh transform readback; the verifier reports that limit rather than treating identity readbacks as real positions. Actual GPU captures were separately inspected for placement, opacity and scene coverage.

The old32m benchmark predates the ladder and this extension, so its249–251FPS result does not describe the current scene. The new real OpenGL1080p check measured69.5–80.9FPS across three route positions with atmosphere enabled, and92.9FPS at the courtyard comparison position with it disabled. GPU time was7.47–8.26ms with atmosphere on. This is a short uncapped offscreen check without image readback, not a locked60FPS or thermal guarantee. Full results and limits are in `C:/Users/tgden/Desktop/MIKO/Builds/benchmark_extended_1080.md`, with the reproduction script, raw JSON and logs alongside.



## Gentle 3D camera, level walkway
The default now uses 8 degrees of horizontal camera offset and the existing 6-degree downward pitch. Screen-right is aligned with the projected world walking axis, so the entire level deck remains horizontal instead of appearing uphill. This introduces a small camera roll correction (less than one degree), rather than tilting the level geometry. The workshop is again aligned with the walkway, retaining its 85% scale. F6/the camera selector cycles Gentle 3D, Straight side-on, and Earlier raised view.
Grounded yard artwork now stands on world X/Y planes so its lower edges share the deck direction. Far/mid city cards and blurred foreground remain camera-facing. Camera travel, parallax, atmosphere and culling use the focus position on the walking lane rather than the offset camera's world X. The 15m orthographic height and 80% floor row are retained.
review_miko8_gentle_camera.gd passed across 0/6/8/10-degree comparisons and five positions in the 64m room. It checks a horizontal floor over a 20m projected span, framing, scenery orientation, camera options, aligned/smaller building and direct ladder entry. GPU captures and logs are under Builds/Validation/Workshop/camera_* and gentle_camera*.

## Grass and weeds
The active yard includes 57 curved 3D grass/weed tufts in uneven clusters along the deck rim, rear joints and workshop base. Five MultiMesh batches share native tapered blade meshes and restrained green/ochre vertex colours; their tips move slightly in the wind while their roots stay fixed. Seven small moss ground-cover patches reuse the existing photographic moss texture. Vegetation uses the neutral architecture lighting, has no collision or navigation, and leaves the crate approach/landing surfaces clear. Native tuft code is miko8_yard_foliage.gd; wind/material shader is miko8_yard_grass.gdshader. The actual ground/single-crate/stack/roof jump route still passes. Latest GPU view and logs: Builds/Validation/Workshop/crate_steps_approach.png and foliage*.
