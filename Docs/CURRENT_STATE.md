# Current state — 24 October 2026

Baseline: Powered Climb v30. Main scene: `Game/scenes/industrial_city.tscn`.
1920 × 1080 sandbox with Miko, parallax city, catwalks, ladders and magnetic crates.

- Approved neckerchief torso, original aligned head and articulated arms.
- Sprite-based 2D runtime, with rendered body turns and arm layers for aiming.
- Movement while aiming, both magnetic beams and purple plasma.
- Full-port procedural flame/vapour, gentle idle, jump surge, climbing pulses.
- Fixed ladder grip; 126 px/s ascent, 75.6 px/s descent. Bottom release/turn ~0.42 s.
- Magnetic breakaway protection, plasma neutralisation and 15 s charge expiry.

Character master: `Source/Character/robot_neckerchief_aligned_v28.blend`.
Main player controller: `Game/scripts/robot_player_layered.gd`.
Exhaust: `Game/scripts/procedural_exhaust.gd` and its shader.

Treat `Game` as the canonical working build from this point onward. Keep active
documentation here; put superseded notes in Archive. Do not work in a historical
ZIP or the old prototype folder. No model/animation changes were made during this
workspace migration.
