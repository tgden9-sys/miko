# Interchangeable concrete service bays

Three concrete facade types now appear in the sixty-metre preview: original straight pipe, valve/service bay and twin down-pipe bay. Three examples of each concrete type surround the existing sixth-section bridge. The route remains five concrete, one bridge, four concrete.

The two new facade assemblies are actual 3D geometry constructed in `Game/scripts/miko8_service_bay.gd`: rounded pipe bends, flange collars and hex bolts, a torus valve wheel with spokes and shaft, bolted junction boxes, conduit, warm maintenance lamps and a cyan status indicator on the twin-pipe control box. A projecting frame surrounds a darker service panel. Reused concrete, deck, railing and module-joint dimensions are unchanged.

`concrete_clean.glb` is exported from the original six-metre source with its old pipework/control box removed, so new fittings do not overlap the original. Export helper is `Source/Environment/OrthographicJoinTest/export_preview.py` and preserves the existing concrete, bridge and connector exports.

Service geometry is assembled once per variant, batched into one shared mesh with five/six material surfaces and reused by subsequent placements. Materials share the existing concrete/steel texture library. Added lights and meshes use the camera budget; all fittings are decorative and create no collision. Future module placements can choose a facade through `SERVICE_VARIANTS` while `ORDER` retains the structural route.

Validation: Godot captures at 1920×1080; valve raised to remain above the instruction banner. `verify_miko8_service_mesh.gd` checks curved tube winding against a native cylinder and bounds the batched material count. Result: SERVICE_MESH_PASS. New artifacts and runtime logs: `Source/Environment/OrthographicJoinTest/service_*` and `textured_7.0.png`. These are native Godot renders, not AI paint-overs.
