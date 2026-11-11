# Connected painted foundation library

Ten distinct front-wall paintings created as one planned construction family. Nine different fronts are installed on the existing nine concrete sections; the tenth is a quiet plain spare. The original 5 concrete / bridge / 4 concrete route and its collision remain unchanged. The bridge remains the actual 3D version.

Before bridge: quiet origin → descending main → quiet lower run → rising service bay → isolated termination. After bridge: twin origin → one crossover → manifold termination of the blue main → quiet copper termination. The separate pipe runs terminate before the open bridge and start again after it. Painted pipes disappear behind the native structural piers, then reappear at the common socket height; no literal exposed pipe end is meant to butt into the front of a pillar.

Artwork: `Game/art/tutorial/facade_library/`. `plan.json` records each left/right pipe identity and the sequence; `prompts.txt` preserves the built-in image-generation briefs. Shared reference was the first user-approved painted foundation, not the rejected 3D service-bay fittings. All are straight-on elevations with no pavement or railings. Some walls are intentionally quiet; the library is not ten valve cabinets.

## Socket fitting

The generated paintings did not precisely obey the requested endpoint coordinates. Source pipe centres and widths are recorded in `miko8_facade_library.gd`. Its shared material maps those bands to normalized heights 0.36 / 0.66 and a consistent 0.12 diameter, while fixing the top and bottom masonry courses. The crossover's lower endpoints use separate left/right measurements. This is material UV fitting on flat fronts, not an attempt to repair conflicting perspective. Raw PNG edges are not advertised as universally seamless tiles.

`validate_sequence()` checks the pipe identities in adjacent slots, including colour exchange across the crossover and empty bridge ports. A compatible facade's left socket list must match its predecessor's right list; arbitrary random shuffling is intentionally not used. Additional levels can select compatible sections and add plain relief sections where both sides are empty.

Fixed concrete-front point lights from the earlier 3D lamp housings are disabled with painted fronts: the image lighting is baked, and those lights would otherwise illuminate foliage where a particular painting has no lamp. Real overhead lamps and bridge lights remain.

## Validation

`verify_miko8_facade_library.gd` checks the ten resources, nine distinct installed fronts, port graph and unpainted 3D bridge. It captures normal-camera views of both runs and an overview under `Source/Environment/OrthographicJoinTest/facade_run_*.png` and `facade_library_overview.png`. Assess actual visible endpoints as well as the metadata test. Movement code and floor geometry are unchanged by this pass.

Result: FACADE_LIBRARY_PASS. Actual normal-camera captures inspected at x=6/24 before the bridge and x=42/51 after it, checking continuing upper/lower pipes, crossover, and termination. The plain spare is saved without forcing a tenth concrete section into the current route.
