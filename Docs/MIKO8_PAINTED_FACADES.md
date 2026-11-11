# Painted foundation fronts

User rejected the procedural 3D service fittings and authorized high-quality 2D foundation-front artwork on the existing 3D platform structure. The first installation uses one repeating detailed service-wall painting for review before commissioning more variations.

The native six-metre deck, bridge, railings, piers, player and collision remain. Every concrete module uses `concrete_clean.glb`; crude service add-ons are disabled through `USE_PAINTED_FACADES`. The original service-bay experiment remains saved but is not instantiated. Clean export also removes old front ribs and lamp housings that would protrude through the new artwork. Native walking surfaces are unaffected.

`painted_foundation_front.png` is a 2172×724 straight-on elevation, no pavement or railing perspective. A six-metre by two-metre quad is placed on the physical foundation face below the coping, at local (3,-1.25,1.505). It uses an unshaded material to preserve the painted lighting, fine detail and colour. Physical piers frame its edges. The image's lights and relief shadows are baked artwork and do not dynamically respond to the player. This is intentional for a non-interactive, fixed-camera foundation.

Artwork created with built-in image generation using the approved detailed service-walkway concept as reference. Exact prompt: `Game/art/tutorial/ortho_materials/painted_facade_prompt.txt`. This is artwork installed in Godot, not a paint-over presented as a runtime screenshot. Runtime captures: `Source/Environment/OrthographicJoinTest/textured_7.0.png` and `textured_32.0.png`.
