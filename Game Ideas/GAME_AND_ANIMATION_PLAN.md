# MIKO — proposed game arc and animation plan

Status: design proposal for discussion. Prove the mechanics in one test level before committing to the full campaign.

Prototype update: MIKO's death and non-lethal knockback cycles are rendered from the approved Blender rig. Press B or H in the sandbox to preview them. Repulsion launches still need rigged animation work; hazards and health are not connected yet.

## The player promise

MIKO is a small maintenance robot in a city whose magnetic infrastructure has failed. MIKO restores routes through four districts by placing Red (+) and Blue (-) tags, changing their suit polarity, and using the weight and material of the world to solve traversal and combat problems. Each new room asks the player to predict what will move, then rewards an inventive use of attraction or repulsion.

The story can remain light and visual. A simple motivation is enough: reach the city's central power core and restore its field before the districts shut down. This gives the game a clear destination without requiring dialogue or cutscenes to explain every puzzle.

## Start to finish — proposed campaign

| Stage | Player learns or proves | Example set piece |
| --- | --- | --- |
| Opening: maintenance depot | Move, jump, dash, climb; see a field failure; acquire Red/Blue tagging | Tag two loose metal objects to open the exit |
| District 1: service yards | Opposites attract, matches repel, two-tag limit, anchored versus movable mass | Slide a shipping crate across a gap, then launch MIKO up a shaft |
| District 2: transit and glassworks | Suit polarity, line-of-sight interactions, switches, wood versus metal | Pull a battery onto a plate from outside a glass chamber |
| District 3: foundry and freight | Mini/Normal/Giant sizing and heavy-object movement | Resize cargo to cross a furnace route and clear a blocked lift |
| District 4: tower and core | Combine all rules under pressure; use charged blast on an ultra-heavy target | Redirect shielded drones and move the core's locked counterweight |
| Finale | A short, readable sequence that combines tagging, suit polarity, sizing, and the blast | Restore the central field, then escape through a route MIKO has reopened |

This can fit the target of about 30 compact puzzle rooms in 7–8 connected levels. Use action-platforming corridors between dense puzzles and introduce only one major rule at a time. The final rooms should recombine known rules rather than add a surprise mechanic.

## Rules to settle in the test level

1. What counts toward the two active tags, how tags are replaced, and how long they last. The current crate charge expires after 15 seconds; that may suit action moments but could frustrate slower puzzles.
2. Whether MIKO's suit polarity is separate from the two environmental tags, and how quickly it can switch.
3. Clear mass classes and force limits: anchored, ultra-heavy, heavy, normal, light, and MIKO. Decide what can rotate as well as translate.
4. How Mini/Normal/Giant changes size, collision, weight, and magnetic force. Decide whether resizing can occur while an object is moving.
5. What the charged blast does. The current purple plasma neutralises crates; the proposed heavy-object blast needs its own clear purpose or a defined additional effect.
6. Material feedback: metal responds to tags, wood splinters on impact, and glass blocks passage but allows the intended magnetic interaction.
7. Reset and recovery rules so a puzzle cannot become permanently unsolvable.

The first test room should put one metal crate, one fixed anchor, one wooden crate, a safe vertical shaft, a switch and a reset control within easy reach. Add sizing and the ultra-heavy object only after the basic polarity loop feels predictable.

## MIKO animation inventory

The current character manifest contains idle, move, move start/stop, jump, dash, land, turns, left/right arm aim, plasma, and ladder mount/idle/climb. The runtime also uses procedural exhaust, squash/stretch, particles, and lighting. These cover ordinary travel and weapon presentation. They do not yet communicate all the new forces the game asks the player to understand.

### Build for the mechanics test level

| Priority | Animation or reaction | Why it matters | First implementation |
| --- | --- | --- | --- |
| Essential | Suit polarity switch and active Red/Blue state | The player must see their current polarity instantly | Brief body/eye/light pulse, coloured suit indicator; no new full-body render needed initially |
| Essential | Magnetic pull / dragged through air | Distinguishes forced motion from a normal jump | Braced arms and trailing body tilt, with field particles |
| Essential | Magnetic repulsion / launch | Makes a slingshot feel deliberate and powerful | Rigged brace and push-off pose, then an airborne pose and exhaust burst; no body squash |
| Essential | Fast impact, hard landing, and recovery | Heavy collisions need readable consequence | Rigged impact/recovery poses, flash, hit-stop and debris |
| Essential | Tag application and replacement feedback | Makes the two-tag limit understandable | Existing aim animation plus a distinct muzzle pulse, target flash, and tag number/colour UI |
| Essential | Blast charge, release, and recoil | Separates the ultra-heavy blast from an ordinary tag | Reuse plasma charge poses initially; add a clear recoil and impact effect |
| Essential | Damage/stun and respawn | The test level needs fair failure feedback | Short flinch, disabled/fall pose, rapid reboot effect |

### Add when those mechanics enter the campaign

| Animation or reaction | When it becomes useful |
| --- | --- |
| Size-change reaction and scale transition | When Mini/Normal/Giant objects first appear; most of this should be an object effect rather than a new MIKO pose |
| Shield tug / strain | If enemies can hold magnetically removable shields |
| Wall or ledge contact recovery | Only if magnetic launches frequently hit walls or require controlled landing |
| Heavy object push/brace | Only if MIKO physically pushes objects, separate from magnetic movement |
| Short activation, shutdown, and victory beats | Opening, checkpoints, and finale; keep these small until the story is settled |

Enemies and objects need their own visual states too: a shield detaching, a drone being struck and breaking apart, wood splintering, metal crates scraping/rotating/colliding, anchors activating, batteries seating on switches, and Mini/Normal/Giant transitions. These can rely heavily on physics, particles, sound, camera response, and debris instead of large skeletal animation sets.

## Animation production decision

Keep the current rendered 2D MIKO for the mechanics test level. Prototype each new reaction with pose reuse, layering, transforms, exhaust, and effects. Once the forces and camera behavior are proven, decide whether the proposed live 3D MIKO and rotating 3D crates offer enough benefit to justify the pipeline change. Avoid rendering a large new sprite library for interactions that may change during testing.

## First playable milestone

A successful test level lets a new player learn the controls, tag two objects, switch suit polarity, solve one attraction puzzle and one repulsion launch, recognize a wood/metal difference, move a resized object, use the charged blast, recover from a mistake, and reach an exit. The necessary MIKO reactions above should make each cause and effect clear without an explanation screen.
