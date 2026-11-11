# Metal crate

User source preserved as source.glb (989,231 triangles). The production game asset is Game/models/props/metal_crate.glb, 5,272 triangles / 0.8m nominal cube, about 3.4MB.

Production builder: build_clean_crate.py. It creates clean bevelled panel/frame/corner geometry, bakes the source panel/frame appearance to a packed 2048px atlas, and uses clean ivory corner fittings with small slot faces. Editable source: MetalCrate_Game.blend. Source appearance and rebuilt version are shown in source_preview.png and retopo_preview.png. Initial direct decimation damaged shading and was rejected; build_game_asset.py is a historical experiment that now writes only decimation_trial outputs.

The game script miko8_charge_box.gd uses the same physical box, charge expiry and magnetic-force interface as the previous placeholder. The material shader changes only geometric inset-panel regions; frames and corners retain their neutral materials. Charge states were rendered in Builds/Validation/MIKO8/art_revision/crate_states.png.

The tutorial has one crate near the far end, after its movement lesson completion point. It remains a walk/run/jump-only lesson; charging remains available in the separate movement/abilities review and through the normal crate API.

This clean frame can support a metal-framed wooden-panel variant. A traditional all-wood plank crate should be a separate mesh with recognisable joints, slats and silhouette rather than a wood-colour overlay on the metal box.
