# BP Games ladder animations — direct FBX source

Publisher page: https://www.patreon.com/BPGame/posts/free-fbx-first-151481680

Public attachment: https://www.patreon.com/file?h=151481680&m=618791696

Downloaded 29 October 2026 as `LadderAnimationSet.zip`; original preserved here.
The publisher labels this a first-person ladder pack. Inspection in Blender
confirms a complete 91-bone character hierarchy and animated pelvis, legs and
feet in the top-entry and both top-exit clips. These are suitable candidates
for full-body retargeting; visual quality on MIKO has not yet been established.

The 16 FBX files in `Source/` contain:

- Bottom entry (1), bottom exit left/right (2).
- Ladder idle left/right (2).
- Climb up left/right (2), climb down left/right (2).
- Top entry (1), top exit left/right (2).
- Four additional idle/look clips: centre, down, left and up.

`inspect_fbx_pack.py` imports all 16 individually using Blender's normal FBX
importer and records skeletons, action ranges and sampled effector movement
in `inventory.json`. All 16 imported successfully. No Unreal Editor was used.

These source clips are now retargeted in `../../MIKO8_BPG_Ladder.blend` and
installed on MIKO. The yard and movement-review ladders use this set. See
`Docs/MIKO8_BPG_LADDER.md` in the project root for controls and implementation.
