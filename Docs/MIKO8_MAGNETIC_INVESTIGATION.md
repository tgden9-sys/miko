# Original magnetic mechanics and revised mesh colour investigation

Original source: Game/scripts/robot_player_layered.gd, crate.gd, magnetic_anchor.gd, magnetic_drain_fixture.gd, plasma_projectile.gd, shaders/suit_eyes.gdshader.

Red/blue are tagging beams. Aiming calls set_locked_on; releasing a locked beam calls lock_in_color to commit red or blue. The aim assist can select a nearby taggable crate, launch fixture or anchor within a forward cone. Leaving a target clears the temporary highlight without committing. Crates have charge timers and can return to neutral. Magnetic effects: like poles repel, unlike poles attract; opposite crates can follow the moving suit at a standoff distance. Launch fixtures attract/latch the opposite suit polarity, then matching polarity launches MIKO away/upwards. Neutral disengages.

Suit polarity is independent of hand selection: neutral, red, blue. Original controller Y toggles red; X toggles blue (pressing the same again returns neutral). C cycles. B also cycles in some original contexts; do not reuse that shortcut in the movement demo because B is jump.

Original sprite visuals recolour an eye-region shader and thruster light. Revised mesh has one base-colour texture and one metallic/roughness texture, rather than separate green materials. Prototype miko8_polarity_preview.gdshader masks green-dominant texels, changes only those accents to red/blue, and keeps base texture detail and metallic/roughness maps. Neutral preserves green. preview_miko8_polarity.gd rendered all three successfully; red and blue were visually inspected. This is a prototype preview, not yet connected to gameplay polarity controls or magnetic objects.

Current movement demo now has fine alpha-0.30 targeting guides and a two-branch/one-trunk plasma guide. Releasing plasma launches one travelling purple bolt. The original red/blue lock/highlight/commit mechanics and magnetic physics still need porting into the new 3D movement demo; visual beams alone do not reproduce them.

Original plasma_projectile.gd calls neutralize() on compatible hit objects, so plasma is also a way to remove magnetic charge. This behavior must be retained when porting interactive magnetic objects.


Suit polarity is now live in the movement demo: Y toggles red/off, X toggles blue/off, C cycles. Uses miko8_suit_polarity.gd and the tested green-mask shader. This provides suit state and colour; magnetic object tagging/forces still need porting.


Suit colour tuning: the green accent mask now softens saturation for neutral green as well as red/blue, mixing toward 65-percent-value grey with saturation factor .58. White and black texels remain outside this mask. All three suit states rendered successfully.

