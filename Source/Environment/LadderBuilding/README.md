# Ladder building

User-supplied Trellis GLB preserved as source.glb and source.blend. The unwanted
underside extends below the main base at source Z 0.0927. prepare.py cuts it
away, caps the open underside and puts the flat base at zero, then exports a
lighter textured mesh to Game/models/environment/ladder_building/.

The yard's previous raised platform is replaced by this model. Roof height
2.83364 m matches the end workshop. The bay is fitted around the existing
ladder at x18.3. Collision follows the actual mesh, including the recess and
roof. Materials use the same neutral architecture light layer and grounding
shader as the end workshop. Additional grass grows at the base and roof rear.
Original texture and UVs remain available in the GLB; the source file is unchanged.

## Industrial skin

The runtime building now uses `miko8_ladder_building_skin.gdshader` with two
new PNGs in `Game/art/materials/ladder_building/`. The main service-wall artwork
has a complete pipe run returning through bolted wall flanges at both ends,
plus a connected electrical conduit/cabinet and low vents. That assembly is
mapped once inside the broad front panel; it does not repeat or get clipped
at corners. Its placement and width are shader uniforms.

The quieter matching concrete tile is projected in metres across side walls,
the ladder recess and roof, with a darker roof finish. Corner transitions use
triplanar projection. The material keeps the existing architecture light layer.
The fittings are depicted in the texture; mesh geometry and collision are
unchanged. There are no new physical obstacles or roof lips.

Images were created with the built-in image generator; full prompts are saved
in `skin_prompts.md`. Original generated pixels are preserved. The final GPU
review in `Builds/Validation/LadderSkin/` checked front and roof appearance,
successful ladder exit and supported roof walking, with zero failures and no
shader/runtime stderr errors. The editor import emitted the existing safe-save
warning for editor settings; the game imported and rendered both textures.
