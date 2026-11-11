# Two-piece orthographic connection prototype

Separate visual test requested after rejecting the independent-perspective painted kit. This does not install another version of the tutorial.

`TwoPiece_Orthographic.blend` contains a six-metre concrete walkway, a six-metre steel bridge and the shared structural connection, constructed together in native 3D. Dimensions: 2.8 m deck depth; nominal deck z=0; rear railing 1 m high. No camera yaw along the walking axis; camera uses orthographic projection. Pavement joints remain parallel across both modules.

The shared connector owns the load-bearing concrete pier, coping, expansion joint and its steel nosings, rear rail junction and warm lamp post. The lamp is behind the walking lane. It marks a construction transition rather than hiding incompatible perspective. Future modules must connect to the same coordinate and dimensions, with exactly one connector at each shared boundary.

Collections separate the walkway, bridge, connector and presentation environment. `build.py` recreates the prototype; `dimensions.json` records the interface. Procedural materials and actual modelled surface details are used. Materials will need baking and geometry will need optimization before Godot integration; this is a visual/structural proof, not an assertion of production performance or concept-quality parity.

Outputs: `two_piece_orthographic.png` / `two_piece_orthographic0001.png` for the full pair and `join_detail.png` for the closer view. Geometry includes individual paving stones, cracks, coping stones, reinforcement plates and bolts, utility pipe collars and flanges, recessed lamps, a drain, cable conduit and localized ivy. Tiny anti-slip grip geometry sits above the nominal bridge deck.

Almost-dark blue-hour lighting uses cool ambient illumination and local amber practical lights. The deep indigo presentation backdrop is separate from the reusable modules.

`finish_study.png` is a separate AI paint-over using the native rendered layout and approved concept as references. It illustrates the intended richer finish. It must not be presented as a render of the current native materials. Those still require further texture work. Prompt and provenance: `finish_study_prompt.txt`.
