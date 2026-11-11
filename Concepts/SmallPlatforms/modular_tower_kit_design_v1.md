# MIKO modular tower kit v1

Generated with the built-in image generation tool, 4 November 2026.

Output: `modular_tower_kit_v1.png`.

## Design

Use the narrow service mast as the core, with independent left/right landings inspired by the offset-spine design. Concept art only; no runtime changes or new game-ready 3D meshes have been made.

Five independent authored pieces:

- Base: grounded concrete/steel socket and feet.
- Mast bay: repeatable straight vertical section, with shared joining planes and attachment sockets.
- Ladder section: independent repeatable rails/rungs, aligned to the existing animation rather than stretched with the mast.
- Side landing: a mirrored left/right deck and gusset attachment at a bay boundary.
- Top landing: a full deck cap with enough rear landing depth for MIKO's existing forward ladder exit.

Proposed assembly controls: number of mast sections, list of side-platform bay indices and their left/right orientation, top-deck enabled, ladder enabled. Changing platform count must not require changing the tower height. A platform can be moved to another join or mirrored without reauthoring the core. Core sections should remain the same dimensions and share matching attachment positions.

The current BPG ladder documentation specifies 0.2648 m rung spacing. A candidate bay containing four rung intervals is 1.0592 m tall; exact bay/base/deck heights must be confirmed during 3D authoring and gameplay placement. Build the ladder to that pitch rather than taking counts and dimensions from the concept illustration. Adjacent duplicate seam plates should be avoided when authoring the actual joins.

Keep the front ladder climb path clear of side-platform attachments. A platform needs a supported rear landing at the required depth before assigning a ladder dismount there; a visible side shelf alone is insufficient. Collision, mount/dismount markers and roof support should be derived from the assembled geometry. Verify the native exit animations at the shortest supported configuration and at each enabled ladder landing.

The illustrated example labels communicate assembly options; the generated rendering is not a dimensioned construction drawing or a validation of bay counts, jump distances or ladder transitions.

For reconstruction from images, create the five meshes as separate source assets and align the joining planes in Blender before exporting. A whole assembled tower reconstructed as one mesh would require separation before it can function as this modular kit.

## Final generation prompt

Use case: stylized-concept.
Asset type: modular asset-kit concept sheet for MIKO, a cel-shaded 2.5D industrial platform game.
Primary request: redesign the supplied platform-tower concepts as ONE coherent BUILDABLE MODULAR KIT. The user wants to alter tower heights AND the number/positions of platforms independently. This image must make that modular idea immediately clear, while retaining the handsome tall, narrow industrial look of reference tower 01 and the side landings of tower 02.

Reference role: the supplied image is the style and design reference. Preserve its muted steel, concrete, ochre deck edges, graphic outlines, tall service-mast architecture, warm highlights and dark side faces. Use the SERVICE MAST as the common core. Do not create four unrelated tower designs again.

Composition: polished wide landscape concept presentation on a pale warm-grey studio background. Title "MODULAR TOWER KIT". LEFT approximately 40%: five separate fully visible kit pieces, neatly spaced in two columns, each clearly isolated and at sensible presentation scale. RIGHT approximately 60%: three assembled examples of EXACTLY THE SAME KIT side by side, base feet on a shared ground baseline, consistent world scale; increasingly tall 2-bay, 4-bay, 6-bay structures. The shortest tower has a top landing only, middle tower has one intermediate side landing plus top, tallest has two intermediate landings on alternating sides plus top. Thus viewers can clearly see different heights and platform counts, with exactly repeating core units. Keep enough visual space to prevent parts or examples overlapping. No full environment or characters. Straight grounded upright vertical supports, all landing surfaces level.

The five separate pieces on the left, small clean captions:
"BASE": a squat concrete anchoring foot with steel fixing plates, chunky anchor bolts and a square socket to accept the first mast bay. Just a base, no tower attached.
"MAST BAY": a short repeatable approximately one-metre upright section of square steel service mast, with four vertical corner members, recessed side maintenance plate/brace, horizontal level top and bottom mating collars, and visible standardized side bracket sockets. It is open-ended top/bottom so identical copies stack cleanly. Nothing projects above its joining plane. Modest industrial panel details, NOT a long whole tower. No external ladder attached to this isolated part.
"LADDER SECTION": one short straight clip-on ladder segment, two steel rails and four evenly spaced rungs, sized to match one mast bay. Clean rail ends so copies join into a continuous straight climb. Shown separately. No ladder cage.
"SIDE LANDING": a broad usable rectangular flat steel shelf with worn amber front edge, thick deck and strong triangular underside gusset terminating at a matching bolted connector plate. One modular attachment that can be mirrored left or right on a mast joint. Clear unobstructed horizontal top; no back wall, no railings, no machinery. Not a tiny footstep.
"TOP LANDING": a flat wide cap deck with square connection underside fitting the top of any mast bay, bevelled reinforced edges, restrained amber lip, clear walkable surface, no antenna, top railings or protruding machinery. Front edge accommodates the ladder ending flush at deck height; no ladder extending high above the roof.

Assembled examples: all reuse the SAME square steel mast bay at exactly the SAME dimensions and rung spacing. Two bays, four bays and six bays in height; don't stretch the geometry. Seam collars and bracket sockets occur at every bay boundary. First shorter structure: base, 2 bays, continuous front ladder, cap deck. Second: base, 4 bays, front ladder, one right-facing side landing at a middle bay joint, cap deck. Third tallest: base, 6 bays, continuous front ladder, one left-facing and one right-facing side landing at separate intermediate bay joints, cap deck. Three different heights and three platform counts, but clearly one family assembled from identical parts. Ladders on the front, side shelves project along horizontal left/right travel direction without interrupting the ladder face. Every shelf visibly supported by a proper bolted gusset into the mast. Top decks have enough depth behind the ladder for a character to step onto; upper decks stay clear. A few tiny muted amber markings, no glow.
Small clean captions beneath the three assemblies: "2 BAYS / 1 PLATFORM", "4 BAYS / 2 PLATFORMS", "6 BAYS / 3 PLATFORMS". These words and the part labels are the only other text.

Art style: premium cel-shaded stylized 3D game-environment concept art, graphic-novel linework, deliberate three-tone light/mid/shadow bands, deep cool charcoal side shadows, warm pale top highlights, dark contour edges, selective crisp panel lines and restrained painted wear at edges. Match the reference exactly in finish and palette. Steel is desaturated dark grey-green; concrete warm pale grey; small worn ochre edge markings. Modular boundaries are attractive engineered collars, not oversized cubes.
Avoid: low tables or low stepping blocks as the main result, cranes, radio antennas, broad buildings, huge multi-storey gantries, twisting ladders, mismatched part designs between pieces and assemblies, wildly different mast widths, ladder cages, front railings blocking jumps, fragile cantilevers, brown rusty overall tint, photoreal PBR noise, excessive small junk details, sloping roofs, perspective-distorted joints, floating unsupported platforms, rendered gameplay HUD.
Make a persuasive concept illustration for a real reusable modular kit, not a complicated CAD blueprint.

