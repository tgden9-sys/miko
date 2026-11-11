# Neighbouring block connections

Blocks and fixed mag pads now form mutual nearest-neighbour connections in the left, right, above and below directions of the gameplay plane. Only charged neighbours within the existing coupling range can connect. A block cannot skip a closer charged neighbour in the same direction. Ties use stable instance IDs. This supports side-by-side puzzles and vertical stacks without long-range cross-chain forces.

R–B–R has two attraction links and no R–R link. Adjacent R–R still repels and retains the existing close-range kick/breakaway behaviour. Neutral blocks have no magnetic state and do not participate; when the middle B is neutralised, the outer reds become charged neighbours if within range. A charged block in breakaway still occupies its neighbour position but cannot exert an active connection, preventing remote blocks from suddenly connecting through it.

The shared `miko8_block_connections.gd` predicate gates both force application and field-link drawing. Rings continue to show field extent, but an overlap alone does not imply a connection. The pad's horizontal-only force, ordinary gravity after discharge and suit-to-crate controls remain unchanged. Fixed objects still cannot pull MIKO or attach him to walls.

Validation: `review_miko8_block_connections.gd` checks the R–B–R graph, actual inward motion with no red-red kick, adjacent same-pole repulsion, neutrality, breakaway, vertical stacks, range and the GPU's exact count of two links. Logs/capture: `Builds/Validation/MagPad/connections*` and `neighbour_RBR.png`.
