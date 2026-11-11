# Restored block mechanics

**4 November 2026 gravity clarification:** the initial upward/outward repulsion kick is retained. Continuous suit/block fields are horizontal, so the kicked crates fall back to the floor instead of being suspended. Only a deliberately aligned ceiling magnet supplies sustained vertical lift. See [current gravity and switch follow-up](MIKO8_PRESSURE_SWITCH_V2_AND_AIM.md).

The 3D yard now shows the original block field language: translucent discs, dashed boundaries, orbiting chevrons, expanding pulses, bowed attraction streamlines with moving flux motes, matching-pole deflection barriers and pulsing lock brackets. Overlay positions follow the live 3D camera and moving bodies. Only charged blocks show fields; fields fade during discharge and the two-second breakaway period.

The original 200 px field radius is converted using the established 1.9 m / 96 px scale: 3.958 m radius, 7.917 m mutual coupling range. Opposite blocks attract, matching blocks repel. Close matching blocks kick apart, including a stronger upward/outward kick for the top block of a stack. Both participants receive two seconds of breakaway protection so recolouring cannot immediately cancel their separation. The charged suit attracts/follows blocks with the original 88 px equivalent standoff gap, or repels matching blocks. Existing 15-second expiry, charge refresh, plasma discharge, charge-hit sparks and level reset remain connected.

Stationary objects never magnetically translate MIKO or attach him to walls. Fixed bases remain frozen; their fields can affect movable blocks. The launcher remains a local walk-in brace and double-height launch interaction.

The ladder ankle/toe correction runs last as a SkeletonModifier3D, after source animations, aligned explicitly to skeleton forward (+Z), with mount/dismount blending. Both ankle yaw and the separately animated toe rotation are corrected. Source rung contact positions and climb speed remain unchanged.

Validation: `review_miko8_block_restore.gd` exercises long-range coupling, close repulsion, breakaway, discharge and foot direction, and captures field/ladder views. `review_miko8_magnetic_launcher.gd` checks suit/crate forces, fixed-object immobility, no force on MIKO, charge projectiles and launcher behaviour. Logs and images are in `Builds/Validation/Launcher/restore_visual*` and `restored*`.
