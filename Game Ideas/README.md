# MIKO — game ideas and current direction

This folder is the home for the game's design ideas. The immediate goal is to prove the core mechanics together in one test level before building the wider game.

## Important visual direction

**MIKO's game should lean toward anime, with cyberpunk as a supporting influence.** Use expressive silhouettes, hand-painted texture, warm and varied surfaces, clear colour scripting, and restrained technology details. The current industrial city demo is useful as a mechanics sandbox, but its dense neon/cyberpunk look is not the target for the wider game. New props, rooms, lighting, and effects should follow this anime-first direction. Keep MIKO's approved 3D rig and use posed animation rather than stretching or squashing his body to sell magnetic forces.

See [the proposed game arc and animation plan](GAME_AND_ANIMATION_PLAN.md) for a start-to-finish outline and the next character reactions to prototype.

## The game idea

MIKO is a magnetic platformer built around Red (+) and Blue (-) polarity tags. Opposite polarities attract; matching polarities repel. The player can keep two tags active on environmental objects and switch MIKO's suit polarity to interact with them. Material, mass, and size determine what moves and what breaks.

The intended mechanics are:

- **Mass-based motion:** anchored walls remain fixed, heavy objects slide, and light objects, including MIKO, can be launched.
- **Size changes:** objects can be Mini, Normal, or Giant, changing their effective magnetic weight.
- **Charge-up blast:** moves objects too heavy for ordinary magnetic interactions.
- **Material rules:** metal objects respond to polarity; wooden crates ignore magnetism and splinter when shot.

Early puzzle ideas include sliding a shipping crate across a hazard to make a bridge, repelling MIKO upward through a shaft, pulling an enemy's shield toward a ceiling anchor, striking drones with accelerated crates, and dragging a battery inside a glass room onto a pressure plate from outside.

## Where the project is now

The active project is the Godot game in `../Game`, based on the approved Powered Climb v30 build. Its main scene is `../Game/scenes/industrial_city.tscn`: a 1920 × 1080 industrial city sandbox with MIKO, catwalks, ladders, and magnetic crates. MIKO can run, jump, dash, climb, aim red and blue beams, and fire charged purple plasma. Beams colour metal crates; charged crates attract or repel one another, and plasma neutralises them. Crate charges currently expire after 15 seconds.

MIKO's suit polarity now cycles neutral → red → blue with C in the industrial city test scene. His eyes, thruster ring, and aura show the state; charged metal crates attract the opposite suit colour and repel a matching one. The suit feature is off by default in the reusable player scene, so introductory levels can enable it only when ready. The force values are initial prototype values to tune in the mechanics test level.

The first anchored suit-launch fixture now uses [freight lock concept 04](Suit%20Launch%20Fixtures/README.md). MIKO can beam-charge it, select the opposite suit polarity to pull down onto its base, then switch to the matching polarity to launch upward. Three separate side-view images show neutral, red, and blue states, with raised rear housings behind MIKO's walking plane. His rigged attachment animation turns him toward the camera, lowers his body and places his hands at the base. The launch animation starts from that pose and blends into the existing jump pose.

This is a promising movement and magnetic interaction prototype, but it does **not yet establish the full game rules** above. In particular, the two-active-tag limit, anchored surfaces, distinct mass classes, Mini/Normal/Giant scaling, material-specific destruction, and an ultra-heavy-object blast still need to be designed and tested together. The existing plasma shot is currently a crate-neutralising action; whether it also becomes the proposed heavy-object blast needs a deliberate decision.

## Next milestone: one mechanics test level

Build a small test level that exercises each core rule in isolation, then combines them in a few short puzzles. Use it to settle controls, readable feedback, force and mass values, edge cases, and whether each interaction feels fun and predictable. Keep ideas for the wider game here, but let results from the test level guide the final rules.

## Wider-game direction

The current target is about 30 single-screen or two-screen puzzle rooms across 7–8 extended levels and four city districts. Action-platforming hallways should separate dense puzzle sequences. Rooms can be individual Godot scenes joined with visually seamless transitions such as elevators or airlocks.

The intended art direction is a 2.5D hybrid: Blender-based 3D MIKO and dynamic metal crates for magnetic rotations, with 2D sprites for static breakable obstacles. Impact effects, hit-stop, camera shake, particles, and debris can convey weight without requiring complex skeletal animation. The active build currently uses rendered 2D character sprites, so this visual pipeline remains a future direction rather than a completed feature.

For the playable build and current controls, see `../Docs/CURRENT_STATE.md` and `../Docs/CONTROLS.md`.
