# Chargeable wall support — concept

The [concept sheet](magnetic_wall_concepts.png) explores a narrow structural support with a visible conductive face. The first panel is neutral; the second compares red and blue charge states; the third shows the intended side-on room use.

The first playable wall is now `Game/scenes/magnetic_wall_anchor.tscn`, placed at the left edge of the upper-right catwalk in `industrial_city.tscn`. Its transparent neutral sprite is in `Game/sprites/fixtures/magnetic_anchors/wall_neutral.png`; charged red and blue channels are drawn over the inset. A dedicated neutral test crate starts to its left.

## Intended behavior

- The support is anchored and never moves. Its conductive face can be targeted with either polarity tag; ordinary wall material cannot.
- An oppositely charged metal crate is pulled toward the face and stops flush against it. The crate can become a step to the ledge above.
- A matching charged crate is pushed away. Neutral crates do not react until tagged.
- Charged metal enemies can be drawn into the support. Impact damage should depend on their collision speed, so simply touching it does not destroy them.
- The illuminated red or blue spine makes its state legible from the 2D camera. The surrounding ceramic and steel frame still reads as a room edge or platform support when neutral.

The current wall collision is 56 by 246 world pixels. The solid support itself is laser-targetable and crates settle against its face. Enemy impact damage is still a future behavior.
