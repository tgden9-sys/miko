# MIKO7 movement review v6

Open **Play MIKO7 Movement Test.cmd**. Tilt the left stick to walk, push fully to sprint, and press B/Circle to jump. Keyboard: A/D or arrows, Shift to sprint, Space to jump. **Review MIKO7 Walk.cmd** limits movement to walking for focused review.

The head mounting correction now applies across all ten clips, with pitch compensation during torso movement so jumping and landing keep a forward gaze. Walking is 0.72 m/s with a 0.8-second cycle. Jump preparation blends from the visible pose, including planted leg positions, before takeoff.

Sprint has been rebuilt at 2.2 m/s with a 0.6-second cycle. Its head height variation fell from about 10 cm to 1.3 cm. Foot planting matches travel speed, and braking retains Sprint until speed drops into walking range.

Editable master: `Source/Character/MIKO7/MIKO7_Locomotion_v6.blend`. Godot asset and metadata: `Game/models/miko7/review_v6/MIKO7_Locomotion_v6.glb` and `.json`. Earlier versions remain as checkpoints. The main game scene is unchanged.

Validation under `Builds/Validation/MIKO7/v6`: deterministic bake and loop checks passed; the other nine clips match v5 exactly. Godot checks passed for Sprint speed, bounce, foot contact, braking, reversal, controller B input, all turn variants, both jump directions, raised-platform landing, deadzone and pause. The v5 walk/jump phase test also passed six takeoff phases in both directions. Engine captures are saved alongside the reports.
