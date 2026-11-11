# Magnetic ceiling anchor — artwork concept

The [concept sheet](magnetic_ceiling_concepts.png) shows a compact ceiling piece matching the approved chargeable wall support: neutral, red, blue, and a 2D room example lifting a metal crate.

Its conductive face points down. Opposite polarity pulls a tagged crate upward, matching polarity pushes it down, and neutral has no magnetic effect. The anchored fixture itself never moves. The crate should stop just below the face with a small visible gap; this is the intended puzzle position rather than a physical clamp.

The shell uses the same ivory ceramic, dark steel, and copper fasteners as the wall support, while the underside light makes its active polarity readable at game scale.

The first playable anchor is `Game/scenes/magnetic_ceiling_anchor.tscn`, mounted below the middle catwalk in `industrial_city.tscn`. Its transparent neutral sprite is in `Game/sprites/fixtures/magnetic_anchors/ceiling_neutral.png`; red and blue channels are drawn over the underside. A neutral test crate starts beneath it. The prototype pulls an oppositely charged crate upward and holds it below the illustrated face with a visible air gap. Matching polarity pushes it away.
