# Substation ground kit — design assets

Four transparent ground designs matching the approved `substation_ground_v1.png`. Generated with the built-in image tool, using that artwork as reference. The running game is unchanged.

1. `01_service_walkway.png`: concrete walkway with recessed valve/service niche.
2. `02_pipe_walkway.png`: concrete walkway with returning utility pipes.
3. `03_raised_service_bay.png`: minor raised mesh-front obstacle, no ladders.
4. `04_bridge_span.png`: bridge and concrete abutments, open transparent channel below.

All images are 2172×724 RGBA. Rear rails, level end decks, shallow downward camera, blue-hour ambience and amber practical lights share the same construction family. Keep original files intact.

## Assembly rules

These are design assets, not pixel-perfect seamless tiles. Generative output varied the deck baseline despite a common prompt. Normalize their deck depth and align front AND rear deck edges before placement; using canvas bottoms would create steps. Approximate source front/rear edge y coordinates for preparation:

| Piece | Front edge y | Rear deck edge y |
|---|---:|---:|
| Service | 317 | 242 |
| Pipes | 392 | 326 |
| Raised | 396 | 337 |
| Bridge, at concrete ends | 330 | 250 |

Verify exact edge positions against the image at runtime scale. Rails and underside pipes also need a join pass: some generated pipes cross the raised-piece ends. Do not claim arbitrary raw PNG edge combinations are seamless. Use deliberate structural bays/expansion joints, match rail height and repair any interrupted services during game preparation. Never hide a mismatched ground level behind a thin post.

Suggested sequences: service → pipes → bridge → raised; alternate service and pipes with different lengths and localized props. Keep recognizable bridge/raised landmarks occasional rather than repeating mechanically. Vertical levels will require additional end, ledge, wall and transition pieces; these four are the first horizontal design kit.

Collision and any raised platform gameplay will be authored separately when the approved kit is integrated. Keep sky, city, machinery and blurred foreground out of the ground image so parallax remains independent.

Full shared prompt and per-piece briefs are in `prompts.txt`.
