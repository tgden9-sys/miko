Current build: **v6** includes global head correction, faster walking, smooth jump preparation and rebuilt Sprint. See `Docs/MIKO7_REVIEW_V6.md` in the project root. Earlier details below describe preserved checkpoints.

# MIKO7 rig

## Latest: walk refinement v4

**Review MIKO7 Walk.cmd** is the focused walk-only Godot review. The regular movement test also uses this refined walk. The editable master is `MIKO7_Locomotion_v4.blend`; the engine files are under `Game/models/miko7/walk_v4`. Only the walk animation has changed; the other nine poses match v3. See `Docs/MIKO7_WALK_REFINEMENT.md` in the main project.

## Current controller build: locomotion v3

**Play MIKO7 Movement Test.cmd** opens the playable Godot test: analog walk/Sprint on the left stick, B/Circle jump, and four supplied turn clips. Sprint's head is tilted back 12 degrees. The editable master is `MIKO7_Locomotion_v3.blend`; the matching `.glb` and `.json` are exported under `Game/models/miko7/locomotion`. See `Docs/MIKO7_MOVEMENT_TEST.md` in the main project for controls, sources, validation and rebuild details. The older Sprint-only files remain available as a previous checkpoint.

## Previous review: corrected Sprint only

**Open MIKO7.cmd now opens `MIKO7_Sprint_Check.blend`.** Sprint is already loaded: move the mouse over the model and press Space to play/pause. The MIKO panel contains only this clip. `MIKO7_Sprint_Check.glb` is the matching one-clip export. The v1 bundle below is retained as history and has a confirmed animation-baking defect; do not use its animations.

The repair computes the hierarchy from independent parent matrices and keys complete position/rotation/scale values. All 21 frames were rendered for review; playback uses 1–20 and frame 21 is the exact matching loop endpoint. Sequential playback and jumping into the opening frames produce identical poses. Preview: `Builds/Validation/MIKO7/v2/MIKO7_Sprint_v2.gif` in the main project.

The rest of this document describes the original rig setup. The other animation clips have deliberately not been included in the current review file.

Open **Open MIKO7.cmd** in the main MIKO folder. It opens the Blender master and loads the **MIKO** sidebar. In the viewport press **N**, then choose **MIKO**.

## Files

- `MIKO7_Rigged_v1.blend`: editable, textured animation master, with 52 deform bones, a root and eight additional posing controls. Textures are packed.
- `MIKO7_Rigged_v1.glb`: portable textured skin with ten baked Quaternius test clips.
- `miko7_source.glb`: preserved original, copied from Downloads. The original file was not altered.
- `miko_controls.py`: the easy control panel. Also embedded as `MIKO Controls.py` in the Blender file. If opening the blend directly, run that text once in Blender's Text Editor to enable the sidebar.

## Hands

The sculpt already has curved fingers. **Grip = 0** keeps that original shape. Negative values open the hand; positive values close it. Start with small values, around ±0.3. Thumb and individual finger sliders add to Grip. Sliders can be keyframed with Blender's normal property keyframe command.

Finger bones remain available in the hidden **Finger bones (advanced)** bone collection. The hand surfaces are continuously skinned; the larger body sections rotate as rigid mechanical shells. Internal graphite cores cover moving joints. The source UVs and materials are retained.

## Posing and animation

Choose a clip in the MIKO panel, click **Load clip**, then **Play / pause**. **Reset to original pose** clears the active clip, IK and all hand sliders.

**Pose wrist (IK)** and **Pose foot L/R** snap a control to the current limb and activate IK. Select the control and press **G** to move it. The elbow/knee pole controls set the bend direction. Reset to the original pose before starting a new test. For FK, select a humanoid bone in Pose Mode and press **R**. Keep IK at zero for library playback.

Included test clips: Idle, Walk, Jog, Sprint, Jump Start, Jump Loop, Jump Land, Pistol Idle, Pistol Shoot and Interact. They were retargeted, rather than simply renaming animation channels. The arm rest-pose conversion accounts for MIKO's A-pose and the library's T-pose; translations use MIKO's fitted scale. Library finger channels are excluded so they do not double-curl his already curved hands. The grip controls provide hand posing instead.

The standard Quaternius humanoid hierarchy is retained (`root`, `DEF-hips`, spine, neck/head, shoulder/upper_arm/forearm/hand, thigh/shin/foot/toe and finger chains). Other libraries, including Mixamo, need their own bone map and rest-pose conversion. Matching bone names alone does not make clips interchangeable.

## Scope and practical limits

This is a high-detail sprite-rendering master, consistent with the earlier MIKO/droid workflow. It contains about 975,000 original triangles plus small internal joint cores. A separate optimisation pass would be needed for a lightweight live 3D game character. The active game has not been changed or replaced with this asset.

The input is mostly one welded generated surface rather than independently modelled armour plates. Mechanical boundaries have been separated while preserving its rest silhouette. Deep bends can expose cut edges or overlap adjacent shells. Keep finger poses moderate; the source has close, partly fused knuckle surfaces. The supplied human-library clips are retargeting tests, not final authored MIKO gameplay animation: large-head clearance, foot contacts, weapon alignment and extreme-pose intersections can still need adjustments per clip. No blaster has been added.

## Sources

Quaternius Universal Animation Library Standard, CC0, downloaded from the creator's OpenGameArt distribution on 26 October 2026. The downloaded archive and original `License.txt` are preserved in this folder. This is the OpenGameArt distribution, not a claim to include the newest paid Source edition.

- https://quaternius.com/packs/universalanimationlibrary.html
- https://opengameart.org/content/universal-animation-library

## Rebuild and verification

The original `build_rig.py` / `finalize_rig.py` animation pipeline is superseded. For the current Sprint review, run `repair_animation_v2.py`, then `prepare_sprint_only.py`, then `verify_sprint_export.py` in Blender. The repair starts from the preserved v1 geometry and replaces its animation bake; only Sprint is retained. `make_sprint_preview.py` assembles the rendered frame review with Pillow. No external Blender add-on is needed to use the resulting rig.

`final_validation.json` records actual mesh weight totals and calibrated IK errors. `glb_validation.json` checks the exported animation names, skin and embedded images. `review_rig.py` renders full-body and hand control checks. The master contains an orthographic preview camera and studio lighting.
