# Scene 4 — Freight Security

Rebuilt 8 November 2026. Launch `Play Level 4.cmd`, or select **Level 4 — Freight Security** in the game. This replaces the content behind the existing `miko7_patrol_yard.tscn` entry, so arrival from Level 3 still works.

The route is 180 m long. It uses the same 15 m camera framing as Levels 1–3, standard .8 m cargo cases, the established service-building/side-ladder kit, a complete cooling station, and the existing refined shutters. The old stretched loading platforms are removed. Player gravity, jump velocity, air control, collider and ladder motion are unchanged. Level 4 opts into the existing `action_momentum` response: a hit removes health and slows horizontal velocity by 25%, while the jump continues.

## Route

| Metres | Encounter and traversal | Recovery |
|---|---|---|
| 0–24 | Step over standard freight cases into the first warden encounter; defeating him releases the inspection lock | Cases have a step on both sides; continuous floor |
| 25–55 | Climb a 3 m service roof, jump a 1.6 m gap to a 3.6 m roof; proximity shutter reveals the roof warden, then drop into the loading patrol | Full side ladders on both buildings; recharge checkpoint at 55.5 m |
| 59–91 | Three roofs, a single cargo vault, two 1.6 m gaps and a screened warden encounter | Both sides of each building have full service ladders; every gap has a floor |
| 96–124 | Cross the intake roof, drop into a ground encounter, duck under the complete cooling station | Ground approaches and side ladders; second recharge checkpoint at 123.5 m |
| 126–149 | Dispatch roof combat, then a raised gap and a separate screened bridge warden | Paired side ladders and safe gap floor |
| 151–180 | Cargo jump, final roof pair, proximity shutter and relay warden; his defeat opens the cell lock | Paired ladders; collect the cell at 175.4 m, drop to the relay at 178 m |

The completed exit returns to the title/safe network. The experimental Level 5 remains available in the selector; it is not the next destination of this completed introduction.

## Warden behaviour

Scene 4 uses a dedicated subclass of the original warden, retaining his model, 150 health, 25 damage per player hit, blaster pose, shadows, health display and death/dissolve effects. He detects visible targets at 12 m, turns towards an attacker, and can return fire at longer distances. He advances between bursts, respects solid walls, and checks the next foot position before approaching a roof edge. The attack has a .9 s visible wind-up, two shots .42 s apart at a committed aim point, then 1.5 s recovery. Successive player hits cannot restart his wind-up.

Full-size proximity shutters at 36.7, 79.7, 138 and 167 m physically block long firing lines. They open when MIKO approaches within 4.8 m at the appropriate height, before he reaches the shutter, and remain open for reverse traversal. There is no range-based enemy invulnerability. The first and final locks open on their warden's defeat.

Checkpoints restore health and preserve already defeated wardens. Death/reset restores later enemies to their original positions and heights, clears active bolts, resets the cell and closes encounter shutters. Cleared areas before the checkpoint stay cleared.

## Verification

- `Game/tests/verify_level4_route.gd`: drives the actual player through the complete route with movement, jumps, ladder inputs, aimed blaster fire, cell collection and transfer. No teleport, health refill, damage suppression or movement override after initial spawn; refills come from the real checkpoints. `--geometry` separately isolates traversal.
- `Game/tests/verify_level4_safety.gd`: tests every patrol's floor/bounds, ranged fire blocked by a shutter, proximity opening, deliberate falls into all five roof gaps, all twenty ladder accesses in both directions, and both checkpoint resets.
- `Game/tests/capture_level4.gd`: rendered inspection views.
- `Game/tests/benchmark_level4.gd`: compares rendered samples with Level 3 on the same machine.
- `Game/tests/verify_all_levels.gd`: all five scenes load successfully.

Evidence is saved under `Builds/Validation/level4_*.log` and `Builds/Validation/Level4Astra`. The before-change copies of the four replaced/shared files are preserved in `Builds/Rollback/Before_Level4_Astra_2026-11-08`.
