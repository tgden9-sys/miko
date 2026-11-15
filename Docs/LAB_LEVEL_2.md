# Lab Run Level 2 — Relay Works

Launch **Play Lab Run.cmd** and stand still on the level 1 network node for
1.6 seconds to transfer. **Play Lab Level 2.cmd** opens the level directly.

The route climbs through the pump stair, crosses the coolant return, climbs
the West Lift, crosses the upper exchange, and drops down the Cascade.
The distribution gallery now leads to a switchyard and an east riser. The last
climb turns left onto a mezzanine with the outbound relay. Grounded checkpoints
use safe spawn pads. The level has no droids.

## Environment boundaries

- Corridor panels start on actual decks. Shaft lining spans floorless sections.
  Adjacent wall quads meet at shared edges to prevent depth conflicts.
- The West Lift and east riser use cropped sections of a continuous shaft
  texture. Pipe details continue across the cropped edges.
- Bulkheads close the camera bounds. The overhead steel, low foundation
  supports and machinery in the recessed intake chambers show how the facility
  continues above and below the play lane. Amber and teal accents mark route
  signs, platform edges and the relays.
- The backdrop uses static meshes and prelit textures. Background supports and
  scenery sit outside the player's collision lane.

The approach to lighting and depth was informed by [Playdead's lighting
breakdown for INSIDE](https://blog.playdead.com/articles/the_lighting_of_inside/lighting_of_inside.html).

### Room and camera review

Plan the room silhouette, playable edges, and camera bounds before placing
detail. A shaft should read as one room from its entrance through the lowest
visible point. Where corridor art meets an opening, place the join on a jamb,
floor edge, or ceiling return. Use the room's lighting to keep interactive
surfaces distinct from background machinery. Space beyond the playable
structure can fall into charcoal shadow with a little depth at the edge.

Before treating a room as finished, inspect it at gameplay scale from each
entrance and exit, while airborne, and while looking down.
Check that the next usable landing remains readable, seams stay hidden, and
the camera never reveals an unframed edge. Do a route playthrough after the
visual pass. A passing traversal script confirms the route, while screenshots
confirm the composition at the sampled angles.

## Puzzle gaps

Select the RelayWorks root in MovementLab/lab_level_2.tscn to edit the three
gap widths. Collision and deck dressing are rebuilt from those values.

| Setting | Default width | Center x | Deck height |
| --- | --- | --- | --- |
| coolant_gap | 2.5 m | 24 | 6 |
| upper_gap | 3 m | 32 | 12 |
| exit_gap | 2.5 m | 87 | 4 |

The original setting name exit_gap now refers to the gap in the distribution
gallery.

## Camera

The camera smoothly follows Miko at a constant view height of 8.9 world units.
It leads in the direction of travel. Holding crouch lowers the view to help
inspect a drop.

## New panel art

Built-in image generation created the three-panel texture
[relay_works_panels.png](../MovementLab/art/relay_works_panels.png), using
lab_shaft_finished.webp as the material and lighting reference.

> Generate a NEW production game texture atlas for three distinct bespoke wall backdrops for the MIKO side-on industrial platformer. The attached shaft texture is a STYLE REFERENCE ONLY: replicate its photorealistic hand-weathered graphite steel, aged warm gray concrete, brass edge wear, blue-green shadow and localized amber lights. Exact composition: wide 3:2 aspect ratio, THREE equal-width vertical panels side by side, strict hard joins at x=1/3 and x=2/3, no gutters, no frames around atlas, each independent floor-to-ceiling facing camera entirely frontally, perfectly vertical/horizontal wall lines, NO perspective tilt, no walking floor, no game character, no words, no logo. Left third is a sealed industrial elevator pressure bulkhead, a solid dark steel slab recessed in a thick chamfered surround, single small cyan pilot, flanking pipe feed and warm wall lantern. Center third is the side elevation of an undercroft / pump intake cross section: dim layered pipes and one broad dark turbine aperture behind sparse structural steel, cooler low contrast, deep navy teal; architecture fills the entire panel including upper and lower edges. Right third is an electrical switchyard/induction chamber wall with one large copper-wound transformer behind a steel portal, conduit terminations, chalky graphite/khaki panels with sparse warm amber practical lighting. Each third visually composed as its own complete architecture. Moderate contrast, texture and believable physical construction, built-in ambient occlusion, broad readable forms. No overlays, no rendering glitch, no black blank sections. This image will be cut at exactly thirds into three distinct scenery pieces.


The four dedicated wall images below were made with built-in image generation.
Each is framed for its opening and mapped at a uniform scale in the scene.

### Pump Access

[relay_pump_access.png](../MovementLab/art/relay_pump_access.png) fits a 9 × 6 m opening.

> Create a single bespoke replacement background texture for the highlighted Pump Access bay in the attached MIKO gameplay screenshot. Use the screenshot only for visual style, surface scale and setting. Recompose the machinery from scratch to fit a LANDSCAPE 3:2 canvas (1536 × 1024 or exact 3:2), the game wall is 9 metres wide by 6 metres tall. Render only the wall panel, straight on, side-scroller orthographic elevation, full bleed to all edges, no floor, no ceiling perspective, no characters, no HUD, no signs, no text, no outer white margin, no collage. The result is a recessed industrial pump room seen through the open wall bay above a service shaft. Design it around ONE visibly ROUND heavy intake turbine seen directly from the front, with a bolt ring of the same pixel diameter horizontally and vertically, around 410 pixels in diameter in the 1536 × 1024 image. Locate the turbine slightly right of centre at around 58% of image width and 56% of height. Give the left third its own vertical pipes, isolation valve and a dark worn metal electrical service case. Fit the full width with physically plausible pipe runs, flange elbows and irregular steel bracing; narrow chamfered structural jambs on left and right. Lower edge reads as a dark narrow structural crossmember above a lower shaft, with several vertical pipes naturally continuing downward to the frame edge. Match reference industrial photographic realism: scuffed cast steel and aged graphite paint, warm grey concrete at the thin edges, muted brass fasteners, oily blue-green shadows and soft amber highlights. Subdued lighting, midtones visible, dark detailed recesses, one small warm practical, high-resolution natural texture. Maintain lifelike natural proportions on the circular fan, rivets and pipes; the scene is purposefully composed wide with different equipment across it, never a stretched portrait design.

### Distribution Gallery plenum

[relay_distribution_plenum.png](../MovementLab/art/relay_distribution_plenum.png) fits a 17 × 9.2 m opening.

> Generate ONE bespoke production texture for the overhead service plenum above the Distribution Gallery in the attached MIKO game screenshot. Screenshot is a material and context reference only. Redesign the machinery ABOVE the grey hallway's existing top edge. Deliver ONLY this new overhead plenum texture, no lower hallway, no HUD, no lettering, no people, no platforms. Compose for a landscape opening 17 metres wide by 9.2 metres tall (1.85:1), with the most important design within central 80 percent height so a little top/bottom may be cropped. Perfectly straight-on orthographic side elevation, photographic game background. Full bleed, physical panel structure to all edges, NO blank or black strips or margins. Grounded industrial architecture: continuous straight narrow steel sill all along bottom, reading as the top of the corridor and mounting the plenum; far left narrower enclosed electrical maintenance case in faded charcoal olive with hand-sized vents and a few conduit risers, the middle a wide recessed run of two horizontal coolant mains with round flange collars and hangers that actually attach them to the structure, far right a downturned insulated duct with a pipe elbow and inspection housing. Use one or two vertical heavy uprights and supporting gussets to divide these visually different zones, selected warm amber inspection lights, same layered teal-dark recesses, graphite gray steel with worn brass hardware and oil stains as the screenshot. Include background wall, anchored support, architectural depth and refined photographic surface wear. Natural round pipes and fasteners, horizontal spans designed for this width, avoid huge turbine, oversized greebles, repeated texture tiles, fisheye, perspective tilt, overly bright highlights and fake glow. The lower quarter should have good legible construction detail and a deliberate steel base seam because it is the first area visible from the gallery below.

### Distribution Gallery undercroft

[relay_distribution_undercroft.png](../MovementLab/art/relay_distribution_undercroft.png) fits a 17 × 9.6 m opening.

> Create a new game texture, exact landscape 16:9 if possible, an industrial service undercroft wall, straight-on flat architectural elevation. This image itself is ONLY what is visible in a lower section BEHIND the in-game walkways. No floor, NO decks, NO walkways, NO platforms, no railings, no ceiling viewed in perspective, no borders, no text, no characters, no UI. Do not draw any walkway anywhere in this image. Fill the entire frame edge to edge with the dark machinery recess, with its painted, weathered walls and vertical panel supports all the way up to the very first pixel row. Across the TOP 40% of the image, compose a pair of dark diagonal bolted steel support braces rooted in walls at left and right, with a wide uninterrupted open dark teal recess between them centered at 47% of canvas width. The braces lead up and out of frame. No bright horizontal lines here, no beam across the center. In the BOTTOM 60%, on the left below the brace, put a compact copper-valved coolant pump, pipe elbow and one warm caged maintenance lamp. On the right, distinct filter canisters, small pressure gauge, conduit, and a muted amber practical. The equipment is framed by riveted graphite metal with worn old olive paint, rubbed bronze flanges and blue-green ambient shadow. Keep the recessed center subdued, with two vertical small pipes and dark angular structure receding downward. Moody but legible, physically plausible attachment points and natural ROUND valve wheels and fittings, sophisticated realistic surface wear. Visually cohesive with a worn metal science-fiction industrial side scroller, a convincingly wide composition with different local features. Absolutely no framing device from a game screenshot: this is only the static lower wall and machinery.

### Switchyard sump

[relay_switchyard_sump.png](../MovementLab/art/relay_switchyard_sump.png) fits a 6 × 8 m opening.

> Create ONE bespoke static game background texture to continue the Switchyard Drop shaft DOWNWARD in the attached screenshot. Use the screenshot as reference only. The requested artwork replaces the large blank blue-gray block BELOW the teal machinery, spanning a 6m wide x 8m tall wall recess. Portrait, target 3:4 or closest, straight-on orthographic elevation, full bleed to all four edges. Artwork only, no HUD, no labels, no character, no platform or walkable surfaces. Along the top edge put a dark weathered teal steel structural crossmember with a slim brass-worn edge, believable round bolts and two pipe penetrations through it. It should form a deliberate junction to the machinery bay directly above, where the existing machinery ends in dark teal riveted panels. Below it, two or three naturally proportioned vertical pipe drops in graphite and blue-green steel continue down the shaft, with a pressure elbow on the left and a small rugged electrical cabinet mounted back on the right wall. Visible layered structure, slender steel jambs on both edges, subdued dark graphite / blue-green background, sparse amber maintenance lamp off to one side and realistic diffuse light and scuffed materials. Toward the bottom, machinery recedes into deeper shadow with distinct vertical structural shapes. The middle stays visually recessed and readable as a pit. No giant cylinders or fan, no repeated tiles, no stretched detail, no uniform blank fill. Match the industrial material rendering and small bolts of the screenshot.

### Pump Stair

Built-in image generation created [relay_pump_stair.png](../MovementLab/art/relay_pump_stair.png)
as one continuous 11 × 20 m shaft backdrop. It replaces the separate pump,
stair and sump views in the level. The lower section fades into shadow within
the same image, and the landing brackets reach the wall.

> Create ONE original production-ready STATIC backdrop texture of the Pump Stair, a tall interior shaft for the MIKO industrial sidescroller. Reference image is ONLY a material/lighting style sample, create a completely new continuous shaft composition. Very tall portrait aspect 11:20 (0.55 width:height), fill all edges. Straight-on orthographic architectural elevation, camera faces a single rear wall, no perspective framing, no 3D stage floor, no platforms, no catwalks, no characters, no letters, no UI. Full shaft from its deepest shadow at the bottom to pump machinery and cable feeds at the top, with vertical construction running uninterrupted the whole way. Use slim uprights and insulated vertical lines at left and right. At about 20% across and 64% across, dark graphite steel wall channels with real inset fasteners, intended to visually receive in-game platform anchor mounts. Arrange a compact round cast pump housing slightly right of center and in the TOP quarter only, detailed but subdued. Pipes travel down and continue around elbows, flanges and smaller utility fittings through the middle. A few localized amber inspection lamps at the sides illuminate the middle, with the bottom 35 percent smoothly receding into deep charcoal-teal, faintly readable metal structure and pipe silhouettes in shadow. The main wall just below the middle should look like it continues farther down, no abrupt horizontal texture boundary, no abrupt change in scale, no standalone tile edges, no repeated pattern. Keep the leftmost 20 percent subdued so adjoining corridor wall and rim can join it. Natural circular proportions on wheel and fittings. Photoreal detailed weathered olive graphite industrial steel, patina, tiny worn brass highlights, dark teal recession, localized light. A narrow gameplay shaft with believable physical structure and clear hierarchy, not a wall of decorative noise.

## Verification

The route check drives Miko across the level and verifies fixed camera scale,
checkpoint recovery, completion, and the level 1 transfer.
Run with Godot --fixed-fps 60 --path MovementLab --script
res://scripts/verify_lab_level_2.gd --quit-after 6000. The review script renders
views of the affected shafts, endpoints and new areas under Builds.
