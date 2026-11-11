# Restored native walkway preview

The active `Preview Substation Yard.cmd` launches a continuous 60m concrete stage. The bridge is temporarily replaced by a tenth concrete module, including its front, floor and rear rail. Bridge grating, braces, trim and service lights are disabled in this mode. MIKO, the floors, railings, posts, crate and collisions are 3D. The full-scene photo experiments remain separate.

The approved Wide camera is now the default. Its playable layer sits approximately 80.5px lower at 1080p, closing the visible strip below the platform above the bottom banner. This is camera framing: collision and actor coordinates are unchanged, and the backdrop compensates to retain its framing. The old `Preview 5 Concrete - Bridge - 4 Concrete.cmd` explicitly requests `--keep-bridge --original-view` and preserves the previous layout for comparison.

## Concrete artwork, 29 October

The user's direction is to replace the painterly foundation fronts with one photographic miniature style front and repeat it initially. The enhanced preview therefore uses `Game/art/tutorial/facade_library/miniature_concrete_repeat_v1.png` on every concrete front: ten in the continuous yard, nine when retaining the bridge. It is 2172 × 724, mapped directly onto each existing 6 × 2 metre face. One shared material and texture are used. There is no UV socket warping or random variation. The retained bridge gets no concrete artwork.

The selected image has smooth poured concrete, restrained rain stains, a dark steel pipe and small ivy details. Its pipe centre is approximately 47.6% down the image; left/right endpoint centres differ by about half a source pixel. The native structural piers hide the joins and the open bridge terminations. Mipmaps reduce shimmer as this high-resolution image is viewed smaller in the game. This is an initial repeated style test; the vent, clamps and ivy intentionally recur.

Generated with the built-in image-generation tool. The full selected prompt is saved in `Source/Environment/RestoredHybrid/miniature_facade_prompt.txt`. The initial edit retained too much of the old painted surface and was discarded; the selected pass used the newer city image only as a material/style reference.

The old ten-image facade library and its pipe graph are preserved. The `--restored-baseline` user argument selects the earlier library and earlier environment for comparison.

## Other restored preview work

- A camera-facing photographic city background supplies the open skyline and bokeh, with 15% relative horizontal parallax. Its width adapts to the camera and covers both ends of the room; the buildings inside this single picture are not separate depth layers.
- The top-right View control, or F6, switches between the default Wide view (MIKO at 75% of his original screen height, placed lower) and the original framing. Both retain the same camera pitch.
- Native bridge materials use restrained dark steel and existing geometry. Thin amber lenses fit the existing lamp heads. There are no bridge-channel photo inserts or added water effects.
- Paving has restrained fixed damp patches and fine grain. A static reflection probe captures local surroundings once; it omits the moving actor and does not render a new cubemap every frame.
- Existing air particles now span the full 60 metre preview rather than ending halfway through it. The existing visibility budget continues to hide distant visual objects.

## Review files

Actual 1920 × 1080 Godot captures are under `Source/Environment/RestoredHybrid/view_*_enhanced.png`. These are runtime captures, not edited concept art. The original accepted view and overview are preserved in `Source/Environment/RestoredHybrid/Reference/`.

Use `Game/scripts/review_miko8_restored.gd` for capture review. Movement and controller code are inherited from the existing tutorial actor.

Validation: `Docs/MIKO8_RESTORED_PREVIEW_VALIDATION.md` records the geometry, movement and camera checks. The earlier `Builds/benchmark_restored_1080_20261029.md` records actual OpenGL 1080p render throughput for the retained bridge version on this laptop: approximately 204 FPS while moving across the bridge in the original view and 216 FPS in the wider view, measured offscreen with VSync disabled. This predates the continuous-yard replacement and lower camera framing. These are renderer measurements, not a promise about visible desktop presentation; the normal launcher retains its presentation settings.
