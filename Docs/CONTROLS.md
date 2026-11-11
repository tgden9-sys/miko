# Current MIKO8 combat controls � 8 November 2026

- **L2 / G:** green lightsabre. Hold for a three-strike chain, or tap for individual attacks. Works while moving and jumping; no aiming required.
- **R2 / F:** hold a forward-facing energy shield. Release to recharge. Turning changes the protected side. Sustained fire breaks the shield briefly.
- **R3 / P:** hold and release plasma (moved from R2/F to preserve cargo discharge puzzles).
- **L1 / Q and R1 / E:** magnetic tagging remains available.
- Movement review shortcuts: **Pause** pauses, **F8** changes game size (freed P/G for combat).

The sabre ignites on attack, remains visible for 2.4 seconds after the last strike begins, and disappears while shielding or traversing ladders. Launch **Play Level 4.cmd** for the first gate warden encounter. See [combat notes](SWORD_COMBAT.md).

The older controls below describe the original 2D baseline; the MIKO8 combat bindings above take precedence.

# Controls

| Input | Action |
|---|---|
| A/D or Left/Right | Move |
| Space | Jump; release early for a shorter jump; jump off a ladder |
| Shift or K | Dash |
| W near ladder; S/Down at ladder top | Mount and climb up; mount and descend |
| Up arrow away from ladder | Jump |
| Q or left mouse | Red magnetic beam |
| E or right mouse | Blue magnetic beam |
| Mouse while aiming | Aim elevation; horizontal movement can turn MIKO |
| Hold F or both mouse buttons, then release | Charge and fire purple plasma |
| Escape | Toggle mouse visibility |
| B | Preview MIKO's death cycle (temporary sandbox control) |
| H | Preview non-lethal knockback (temporary sandbox control) |
| C | Cycle MIKO's suit: neutral → red → blue → neutral. When latched to the freight lock, C switches directly to its matching colour and launches MIKO. |

Red and blue beams start at 200 px and can be extended or retracted while aiming. They snap to a visible, chargeable target in the initial 200 px search range; otherwise an open targeting receptacle marks the beam's end. Release a magnetic beam to commit its colour to a crate. Plasma restores neutral
state; charge otherwise expires after 15 seconds and can be refreshed by a beam.
Both weapon arms use steel-blue armour; red/blue identify their weapon effects.
The ground freight lock in the industrial city test scene can also be charged with a beam. Stand on it with the opposite suit colour to latch, then press C or the controller's east face button to launch upward. Its charge persists until changed by another beam.

## Bluetooth controller (standard gamepad layout)

| Input | Action |
|---|---|
| Left stick or D-pad left/right | Move |
| South face button (Xbox A / PlayStation Cross) | Jump, including jumping off a ladder |
| East face button (Xbox B / PlayStation Circle) near a ladder | Mount the ladder |
| Left stick or D-pad up while on a ladder | Climb up |
| Left stick or D-pad down at ladder top | Mount and descend |
| West face button (Xbox X / PlayStation Square) | Toggle blue suit polarity on/off |
| East face button (Xbox B / PlayStation Circle) away from ladders | Cycle suit polarity; when latched to the freight lock, switch to its colour and launch |
| North face button (Xbox Y / PlayStation Triangle) | Toggle red suit polarity on/off |
| Left stick click (L3) | Dash |
| L1 / LB | Hold to aim the red beam; release to tag |
| R1 / RB | Hold to aim the blue beam; release to tag |
| R2 / RT | Hold to charge plasma; release to fire |
| L2 / LT or G | Hold to fire a destructive green bolt every half-second. Walk while firing. Breaks wooden crates and damages targets. |
| Right stick up/down while using a beam or plasma | Adjust elevation slowly |
| Right stick forwards/backwards while using plasma | Extend/retract plasma aim from a short 55 px start |
| Right stick forwards/backwards while using a laser | Extend/retract the beam from a 200 px start; hold backwards at minimum reach to turn MIKO |

Plasma starts at short aim reach when selected, but the fired bolt continues until impact or its normal lifetime ends. The controller and keyboard/mouse controls can be used in the same session. MIKO uses the first controller Godot detects. Controller button labels may differ on Nintendo-layout devices.
