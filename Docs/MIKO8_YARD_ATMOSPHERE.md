# Yard atmosphere

Scenery brightness defaults to **50%**, including the slider and both far-city options. The actual playable buildings and MIKO keep their approved materials.

The atmosphere now includes stronger rolling ground wisps, a quieter rear layer for depth, more lamp dust and warm lamp halos. Five visible exhaust outlets release expanding, drifting steam in staggered bursts. Three roof beacons brighten slowly, and two small electrical units occasionally arc between their contacts and shed brief sparks. The steam uses broad graphic lighting bands and soft edges; the dense plumes are behind the character's lane.

Fixtures are reusable bevelled 3D assets with a painted vertex palette: `Game/models/environment/yard_life/exhaust_outlet.glb`, `service_terminal.glb`, and `beacon_housing.glb`. Their combined file size is under 0.7 MB. Editable source and builder are in `Source/Environment/YardLife`. Fixtures remain visible when atmosphere is disabled and have no gameplay collision.

Vent hisses and electrical crackles use short generated PCM streams with spatial attenuation. An audio listener follows MIKO rather than the distant orthographic camera. The existing **M** key mutes the ambient bed and local environment cues; mute is tracked independently of the looping sound's restart. **F7 / Atmosphere** hides and pauses effects and stops their local audio. Hardware remains in place. The effects use fixed pools (40 steam puffs, 16 sparks) and cull offscreen sources.

`review_miko8_yard_life.gd` passes in `Builds/Validation/Atmosphere/polished.log`, with no runtime/shader errors. Checks cover the 50% default and slider, fixture placement data, no extra collision, unchanged MIKO shading/no trails, steam and beacon animation, electrical arcs and sparks, toggle pause/resume, mute/unmute, adjustable brightness and bridge support. Ground, bridge and disabled-effect GPU captures were inspected.
