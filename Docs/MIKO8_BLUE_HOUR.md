# Blue hour art direction — 28 October 2026

The user changed the target from early morning to almost dark. This supersedes the dawn lighting brief. Prioritize visual quality on this laptop rather than cross-device support. Measure changes on the actual Intel Iris Xe at 1920×1080; do not infer performance from triangle counts.

## Current room

- One continuous cutout substation panorama replaces the two mismatched near-wall pictures and seam-covering post. The source generation contained sky; the final game asset has real alpha above and between the equipment. Alpha inspection: RGBA, 27.8% fully transparent pixels.
- Four background planes remain: procedural dusk sky, far city, apartments and equipment wall. Their horizontal movement factors remain 0, .10, .28, .70; the close foreground uses 1.15. City haze and tints now use a night palette.
- The equipment wall meets the rear walking edge at z=-1.32. Removed the rear filler deck and railings in front of solid machinery. Reserve railings for visible drops and elevated walkways.
- A continuous painted concrete service foundation replaces repeating thin fascia, flat backing bands and diagonal sticks. The shallow channel retains the accepted collision dimensions, with side returns, a lower floor and cropped service-wall artwork. Removed the framed trench picture.
- Continuous paving replaces individually offset, differently toned slab texture patches.
- Real metal crate at x=25 replaces the low placeholder housing. It is frozen for this movement lesson so the obstacle remains consistent. The general charge-box script and movement-demo physics are unchanged.
- Cool ambient/moon fill with localized amber and cyan lights. 4× MSAA, existing particles, contact shadows and blurred foreground remain. Bottom instruction banner remains full width.

## Longer tutorial

User expects a substantially longer tutorial, approximately seven screens with some vertical sections. The current room is a visual benchmark, not the completed level. Build distinct connected areas: equipment yards, service passages, stacked decks and rooftops. Share materials and structural rules while varying massing, landmarks, lighting and props. Author joins around physical corners, buttresses or intentional transitions; do not butt incompatible painted images together. Vertical areas need taller layer coverage and camera rules. Current explicit activity budget is horizontal; extend it for vertical level sections when building them. Native camera frustum culling already operates in all directions.

## Validation

`dusk_test.log`: TUTORIAL_PASS — 48 clips, sit transitions, walking/running, channel jump and recovery, crate collision/clearance, camera bounds and parallax.

`dusk_followup.log`: FOLLOWUP_PASS — monotonic seated head lift, offscreen visual/activity suspension, charge expiry, particle compaction and continuous foreground coverage. Offscreen crate check explicitly relocates the fixture because its lesson position moved nearer.

Final 1080p room captures and runtime logs: `Builds/Validation/MIKO8/art_revision/`. Visual captures inspected at the opening, channel and far end. Runtime launches with F3 performance display enabled. A frame-rate snapshot is not a worst-case performance benchmark.

## New artwork provenance

Built-in image generation, using `Concepts/Tutorial/03_substation_courtyard.png` as the style reference. Project assets:

- `Game/art/tutorial/foundation_panorama.png`: straight-on panoramic foundation; chipped substantial concrete, recessed services, pipes, ivy, warm service lamps; no repeated diagonal supports or blank bands. Generated under the original dawn brief then dusk-graded by the foundation shader.
- `Game/art/tutorial/substation_dusk_panorama_source.png`: coherent blue-hour equipment façade, indigo ambient, amber practical lights, restrained cyan indicators, detailed anime mecha painting. Source preserves generated sky for reference only.
- `Game/art/tutorial/substation_dusk_panorama.png`: edit of that panorama removing all sky to transparent alpha while preserving equipment and fine cables. This is the runtime asset.

Full prompt texts are saved in `Game/art/tutorial/blue_hour_prompts.txt`. Original dawn assets remain preserved and unused where replaced. Generated panoramas are 2172×724; do not describe them as native 4K.
