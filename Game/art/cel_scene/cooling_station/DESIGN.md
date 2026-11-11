# Thermal 08 — cooling station

The integrated reusable asset is `res://scenes/reusable_cooling_station.tscn`.
The duct alone remains available as `res://scenes/reusable_cooling_crossing.tscn`.
The complete assembly replaces building plot 08 in Pump Works at X=66.

The 7.2m × 4.4m facade was composed around the projecting duct: a blank docking panel, structural anchor plates, upper cooling fans, and connected electrical conduits. The building occupies the original plot and includes roof coping, plant curbs, service lights, a ground sill and sparse weeds at the wall junction.

The duct uses three removable access cassettes, top covers, sleeve seals, a framed intake, tension rods with adjusters, and small amber running lights. Geometry supplies the silhouette, contact and joints; the painted atlas supplies consistent illustrated metal detail. Lighting uses the existing scene's directional cel tones. The near end extends to Z=1.62, beyond the visible deck edge. Clearance remains 1.38m and travel length 2.20m.

Textures generated with the built-in image-generation tool:

- `facade_v1.png`: custom front elevation, 1536 × 1024.
- `duct_atlas_v1.png`: four-quadrant atlas, 1536 × 1024. Upper left intake, upper right side access panel, lower left top cover, lower right bare steel.

References were the existing `tall_arrival_facade_v1.png` and the new station facade. The atlas was revised to replace the first generation's pale stone-like borders with folded painted metal. No external image API or fallback CLI was used.

## Generation prompts

Facade: Production full-bleed strict orthographic front elevation of a 7.2m wide × 4.4m tall industrial cooling station. Match the existing cel-shaded facade's greige concrete, charcoal metal, warm edge wear and inked seams. Upper cooling fan band with THERMAL / 08 plaque; left and right service panels, connected conduits and amber lamps. Reserve the central lower machinery docking plate for a real 3D duct. Place solid structural suspension anchors above the plate, clear of vents. Dark sage plinth below. No perspective, roof, ground, sky or people.

Atlas: Four equal edge-to-edge quadrants in a strict 2×2 grid, all flat orthographic. Top left: framed horizontal cooling intake, amber corner indicators and LOW CLEARANCE marking. Top right: slate access panel with cream 08 stencil, small recessed slots and warning marks. Bottom left: top cover with reinforcing strips and access hatch. Bottom right: unframed painted steel wear patch. Match the station's precise cel-shaded edge wear and metal palette; avoid photographic grit and excessive rust.

Final atlas correction prompt: Edit this exact 2x2 production texture atlas. Preserve quadrant layout, every detail, text, grille, bolts, panel placement, light positions and style. Crucial correction: replace ALL pale beige stone/concrete framing in the top left and top right quadrants with cool slate-grey painted METAL trim, worn SILVER edge highlights and tiny ochre paint chips. No concrete, no masonry joints, no porous stone texture anywhere on the top two quadrants: these are lightweight metal duct panels, folded fabricated steel. Top-left intake's border should be slender graphite-blue metal with steel edges, same overall layout and thickness. Top-right panel border should be slate painted metal matching bottom-left frame. Keep yellow accents and amber lamps. Bottom two quadrants unchanged. Strict exact flat orthographic texture atlas, no perspective, no margins.

Validation: `res://scripts/review_miko8_cooling_crossing.gd`. Standing blocked; crouching works both directions; releasing Down underneath keeps Miko crouched; standing restores after either exit. Review screenshots are in `Builds/Validation/CoolingStationArt`.
