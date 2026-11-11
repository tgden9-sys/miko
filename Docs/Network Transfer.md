# Network transfer — 6 November 2026

The reusable section exit is a small floor emitter and projected hand glyph. Miko uses the supplied Interact Alternate 2 animation to reach towards it, dissolves from his feet upwards into six light strands, and reconstructs at the next section's arrival relay. No imported prop model is needed.

## Play it

Open `Preview Network Transfer.cmd` at the project root. This starts Pump Works beside its exit. Walk beside the glyph and press **T**, or **A / Cross** on a controller.

- Service Yard exit: X 75 → Pump Works.
- Pump Works exit: X 75 → Freight District.
- Arrival position: X 3.67, on the ground. Arrival relays cannot retrigger a transfer.
- Freight District has no outgoing destination yet.
- R cancels an in-progress transfer and restarts the current section normally.

Transfers are currently available without a collectible requirement. A later tutorial objective can gate activation in `can_activate()`; no canister insertion or collection prerequisite is implied by this version.

## Reuse

`Game/scripts/miko8_network_transfer.gd` owns the interaction and scene change. Its parent supplies the existing Miko actor, camera and level HUD. Place its origin on the walking plane at floor height and set `destination_scene` and `destination_label`. The destination consumes one arrival ticket in `_setup_transfers()`.

`miko8_transfer_visual.gd` builds the emitter, glyph, ribbons and motes. The transfer shader parameters default to zero, preserving Miko's regular appearance. The actor's outline is copied before animation so the world outline material is unaffected. Suit charge, suit shading mode and audio mute carry through the transition.

The native animation export is reproducible with `Source/Character/MIKO8/build_transfer_interact.py` and is stored as `Game/models/miko8/MIKO8_Interact.json`.

## Verification

`verify_miko8_network_transfer.gd` checks grounded activation, rejection in air/crouch, blocked approaches, duplicate input, independent world outlines, cancellation, reset during departure, actual input activation, the scene transition, restored movement and preserved suit state.

`review_miko8_network_transfer.gd` captures contact, departure and arrival at both the game camera distance and close inspection distance. Images are in `Builds/Validation/NetworkTransfer`.
