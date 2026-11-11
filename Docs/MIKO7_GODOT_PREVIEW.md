# MIKO7 Sprint in Godot

The newer **Play MIKO7 Movement Test.cmd** adds controller walk/Sprint, four turn options and the complete jump sequence on B. See `MIKO7_MOVEMENT_TEST.md`. This Sprint-only viewer now reads the latest locomotion model, including the lifted Sprint head pose.

Double-click **Preview MIKO7 in Godot.cmd** in the main MIKO folder. Sprint starts automatically. This is a separate review scene inside the existing project; Play MIKO.cmd still starts the normal game.

- **Space** or **Pause / Play**: playback.
- **Left / Right** or the frame buttons: inspect one frame at a time.
- **Side / Front / Three-quarter**: change camera angle.
- **Speed**: full speed, half speed or quarter speed.
- **Game size: 96 px** / **G**: toggle close-up and a 96-pixel reference height on the project's 1080p canvas. This is a size reference, not a claim that the old character has exactly this height.
- **R**: restart. **Escape**: close the preview.

The model is `Game/models/miko7/MIKO7_Sprint_Check.glb`; the scene is `Game/scenes/miko7_sprint_preview.tscn`. In the Godot editor, open that scene and use F6 to run it.

Only the corrected Sprint clip is included. It loops in place at 30 fps; it does not control movement or collision. This viewer draws the detailed 3D model with Godot lighting. The existing game still uses its original sprite character, and a final sprite-rendering pass would have its own lighting and image sizing.

The Godot export has its time origin shifted from frame 1 (0.0333 seconds) to zero, removing the leading one-frame hold. The matching end pose is at 0.6667 seconds. `Source/Character/MIKO7/prepare_godot_sprint.py` regenerates this engine copy from the preserved approved GLB.

Verification and captures: `Builds/Validation/MIKO7/godot`. The engine check verifies the imported clip, animated skeleton, loop endpoint, stepping, playback and size toggle, and captures the actual Compatibility-renderer output.
