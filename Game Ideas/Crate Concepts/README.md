# Metal crate alternatives

Five concept images for MIKO's movable magnetic crates. Option 1 is now in
the Godot test scene as a new courier crate type. The original crate type is
still there for comparison.

1. **Courier cube** — compact stackable case with rounded corner guards and
   two magnetic conductor strips.
2. **Rail cargo block** — low, wide freight crate with a magnetic base; suited
   to bridge and sliding puzzles.
3. **Caged core** — open protective frame around a solid suspended inner mass;
   the frame makes its magnetic function visible.
4. **Hex shell** — squat faceted pod with a flat base and a central locking hub.
5. **Transit trunk** — upright transport case with a curved top and central
   polarity strip.

Generated with the built-in image generation tool. Prompt brief for all five:
one standalone movable metal crate, 2.5D side-view game readability with a
slight visible top edge, anime-leaning hand-painted texture, restrained
cyberpunk detail, neutral polarity, transparent background. Each image used
its numbered shape description above as the design variant.

The selected courier crate's current game sprites are the `-side-*.png`
images: flat orthographic front views with no top or side face. Neutral has
grey corners, red has red corners and a plus sign, blue has blue corners and a
minus sign. Godot uses copies under `Game/sprites/crates/`. Every crate in the
test level now uses this side-on type and begins neutral. The collision shape
was reduced from 90 × 82 to 54 × 50 pixels, about 40% smaller, and magnetic
tagging changes its artwork and polarity together. Earlier angled concepts
remain here for reference only.
