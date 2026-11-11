# Framing, presence and atmosphere — 28 October 2026

The orthographic view height is now 11.25m instead of 9m: MIKO occupies 80% of his former screen height, with 20m of room visible at 1920x1080. The room remains 32m long. Camera limits and parallax origin were rebased to this wider view, and the near backdrop panels extended slightly to avoid exposed side edges. The 76,123-triangle gameplay mesh is retained; another reduction is not needed to deliver the smaller framing.

Foreground: new generated transparent pipe/cable framing (`Game/art/tutorial/foreground_defocus.png`) is rendered in upper/lower bands on the foreground parallax plane. Explicit mip softness gives a defocused near layer; the central gameplay route stays clear. Old sharp foreground pipe primitives were removed. Two-sample MSAA softens geometry edges without a whole-screen blur.

Air and character presence: `miko8_scene_presence.gd` uses two MultiMesh batches for 156 depth-separated air/bokeh motes and a pool of short-lived boot dust/ion flecks. Warm/cool points drift and gently vary in brightness. Foot-contact and landing dust originate from actual floor queries. Sparse small suit-coloured flecks add life without restoring the previously rejected body halo or point-light glow. Two close foot-contact shadows supplement the existing broad shadow, fading as the soles lift away. Character material receives a small tutorial-only cool tint and roughness bias; movement-review defaults remain unchanged.

The instructions now span the full bottom edge as a single 108px banner. Existing movement/control actions are unchanged. F3 still toggles actual window size and FPS.

Verification: tutorial walk/run/jump, safe recess recovery, collision, sit transitions and reset checks passed with the new camera limits. 1080p renders checked for foreground occlusion and banner placement. Particle geometry/colour was checked with an isolated render probe to confirm instancing and visibility. Evidence is under `Builds/Validation/MIKO8/art_revision/presence_*` and `air_probe_*`.

Foreground asset generated with built-in image_gen using the approved substation concept as style reference. Prompt brief: transparent 16:9 close industrial pipe/cable frame, soft dark charcoal-blue dawn silhouettes, overhead conduit and upper-corner machinery, low pipe/brace band, central area transparent, no floor/city/people/UI/neon. Runtime crops the upper/lower artwork into bands and applies explicit blur. Original output preserved under Codex generated_images; project copy at the path above.

Follow-up: the foreground bands now each use one 40m-wide continuous piece, with ends outside every legal camera view. Camera activity budgeting and the installed crate are documented in MIKO8_CAMERA_BUDGET_AND_CRATE.md. Asset planning and the wooden-crate/enemy split are in MIKO8_ASSET_PLAN.md.
