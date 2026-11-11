# MIKO three-tone character preview

The side-on yard starts with MIKO's new three-tone material. Press F8 or use
the top-right MIKO selector to compare it with the original material while
walking, turning or climbing. Other review scenes retain their original
default. The original materials remain available and the imported character,
rig, animation clips and scratch/paint textures are unchanged.

`Game/shaders/miko8_three_tone.gdshader` groups a single world-space upper-front
key into shadow, middle and light tones, with a narrow softened boundary. The
three tone multipliers are slightly cool in shadow and warm in the light. The
existing suit texture and polarity recolouring are shared with the original
shader. Realistic metallic reflections are removed in this mode. There is no
outline or texture cleanup in this first comparison.

This is a character-only art-direction test. The fixed key intentionally avoids
accumulating extra bands from all the yard's point lights. It currently uses
unshaded output with its own normal-based shading, so local lamp lighting and
received cast shadows are not part of the three-tone mode. The environment
remains in its existing style for comparison; converting it is a separate art
decision. Its architecture lighting improvements from the preceding pass stay
active. The newly generated side/roof textures have not been applied while
the broader style direction is under discussion.

The shader switch is managed by `miko8_suit_polarity.gd`, retaining theme values
and the current suit polarity in both directions. The yard selector is in
`miko8_side_on_mockup.gd`.

Validation: `Game/scripts/review_miko8_three_tone.gd` captures matching idle,
walk and run phases in both styles, plus a closer idle pair. It checks shared
texture identity, unchanged hand pose, polarity retention, the F8 toggle and
normal turning/walking/stopping. Captures and GPU logs are in
`Builds/Validation/ThreeTone/`.
