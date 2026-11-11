# Five concrete / one bridge / four concrete

Separate 60m playable preview: `Game/scenes/miko8_ortho_repetition.tscn`. Launcher: `Preview 5 Concrete - Bridge - 4 Concrete.cmd`. Uses the native orthographic geometry prototype, not the rejected independent-perspective ground pictures and not the later paint-over.

Six-metre sections, in order: concrete ×5, bridge ×1, concrete ×4. Shared structural connectors at the eleven section boundaries. Camera has no horizontal yaw and follows the actor with a fixed downward angle. A real crate near x=54 remains available for the jump test. Left stick moves, B/Circle jumps; keyboard A/D, Ctrl walk, Shift sprint, Space jump, R reset. The main tutorial and original movement demo remain separate.

Meshes and materials are shared between instances. Exported geometry: concrete 15,804 triangles, bridge 25,696, shared connector 4,376. All ten modules plus eleven connectors total approximately 216k triangles before the character and crate. Inactive offscreen visuals and lights use the existing camera budget. Static geometry shadow casting is disabled in this preview; MIKO's contact shadows and real local illumination remain. This is not a finished baked-lighting environment.

Validation: `verify_miko8_repetition.gd` checks the exact 5/1/4 order, wake-up, eight internal floor crossings and camera range. Result: REPETITION_PASS. Preview logs and screenshots reside in `Source/Environment/OrthographicJoinTest`. Offscreen automated FPS readings during shader compilation varied heavily and should not be represented as a stable visible-game benchmark. User reported the visible preview plays well.

## Textures

Requested after the user tested the layout. Shared 1254×1254 concrete and painted-steel surface textures are applied to the actual 3D geometry with object-space triplanar mapping; pavement and rail geometry determine perspective. These textures contain no baked perspective, panel layout, lamps or large architectural forms. Material colour, roughness and small derivative-based bump relief distinguish concrete, coping, painted steel and rusty railings; emissive lamp materials and green vegetation remain separate.

The same geometry can be reskinned later through shared material resources. Preserve connection dimensions and nominal floor height when changing materials or dressings.

## Ground detail pass

Added separate decoration layers: alpha-cutout trailing ivy at selected front joints, procedural runoff and crevice moss tied to module coordinates, worn coping colour, ambient occlusion bands beneath coping and pipework, and two MultiMesh draws for the bridge's raised steel grating. Bolt materials retain brighter metal edges. The bridge casts directional shadows; concrete geometry keeps the cheaper preview shadow setup. Small non-shadowed amber lights illuminate the foundation below the actual maintenance lamps and bridge fixtures. All added visuals/lights use the camera budget, and no detail nodes add collision.

The foliage cutout is `Game/art/tutorial/ortho_materials/trailing_ivy.png`, produced with built-in image generation. Brief: a front-on, transparent, detailed muted olive/blue-green hanging ivy cluster with an asymmetric crown, several fine trailing stems, individual heart-shaped leaves, no wall/background/pot/lighting glow, in grounded anime industrial painting style. Reused with restrained size and orientation variation. It is decoration attached to the geometry, not a replacement ground picture.

At the user's request, the repetition preview's ambient energy was reduced from 0.48 to 0.36 so its practical lamps read more clearly. Directional fill, MIKO, movement and floor collision are unchanged. Parallax artwork has not received a new art pass; the user requested tackling those layers individually after this ground review.

## Bridge refinement in Godot

Removed the old solid deck and slip-strip geometry from the runtime bridge export. Its visible walking surface is now an actual open steel lattice with transverse panel frames, perimeter strips and hex fasteners. Collision still uses the same continuous floor. Added small bolted gusset plates at the lower brace junctions and restrained ivy on the concrete bridge supports.

Local occlusion was raycast-baked into the bridge mesh's vertex colours with twelve hemisphere samples per vertex and a 0.65m radius. A second channel identifies bevel surfaces for restrained exposed-metal edge wear. Export uses the active vertex colour explicitly; verified COLOR_0 contains the baked data rather than an exporter-generated white placeholder. Runtime shader consumes those channels, so the effect is part of the real asset. No image-generation paint-over is used in these screenshots.

The underlying bridge mesh decreased from 25,696 to 9,388 triangles after removing the solid deck and strips; the extra runtime grating/frames/fasteners are instanced or simple meshes. Warm maintenance lights and the reduced ambient setting remain. Visual captures checked at 1920×1080, plus a separate closer review camera in `bridge_godot_detail.png`; the player's normal camera is unchanged. The native runtime does not claim parity with the earlier illustrative finish study.

Generated assets and exact prompts: `Game/art/tutorial/ortho_materials/`. The built-in image-generation tool produced both base-colour textures. They are surface textures, not complete normal/roughness PBR map sets. Runtime shaders supply roughness and derived micro-relief. No collision or movement changes are part of the texture pass.
