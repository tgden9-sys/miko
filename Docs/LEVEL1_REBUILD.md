# Level 1 route and verification plan

Scope: Level 1 layout only. Preserve Stage 2/3 layouts and default front-ladder behaviour. Snapshot of affected scripts in `Builds/Rollback/Before_Level1_Ownership_2026-11-07`.

Rejected work reviewed: ground-level bypass beneath the first teaching ladder; solid buildings trapping failed jumps; tiny repair ladders and miniature building façades used as hurdles; detached cooling duct with its dedicated building disabled; scenery holes, drifting scenery edges and unsupported roof furniture. These are acceptance failures, not polish tasks.

## Route, authored before implementation

| Metres | Purpose | Route | Failure/reverse route |
|---|---|---|---|
| 0–27 | Walk/run, then jump | Open approach, real .8 m cargo at 14 and 22 | Continuous floor on both sides; no wells |
| 30–58 | Required climb, then first roof jumps | Solid service buildings 30–38 (3 m), 40–48 (3 m), 50–58 (3.35 m); maintenance ladders fixed to side walls | Ground in both 2 m gaps; side ladder on BOTH walls of every building permits retry or continuation |
| 64–73 | Crouch introduction | Complete cooling station at 68, transverse duct, 1.38 m headroom | Open approaches; release Down beneath duct keeps crouch; reverse equally valid |
| 78–89 | Jump practice | Separate actual cargo obstacles, room to land between them | Continuous floor |
| 94–124 | Combine climbing and jumping | Buildings 94–103 (3.8 m), 105–114 (3.8 m), 115.8–123.8 (4.15 m) | Full floor in 2 m / 1.8 m service slots, integrated ladders on both faces |
| 129–140 | Longer low passage | Complete cooling station at 134 | Ground exit on each side |
| 146–171 | Landing precision | Five matched tower decks rising to the solid 163–171 terminal | Open ground beneath towers; ladders at tower ends and both terminal walls |
| 175–186 | Crouch after descending | Complete cooling station at 180 | Clear floor |
| 196–224 | Final combination and cell | Roofs 196–204 (4 m), 206.1–214.1 (4.3 m), 216–224 (4.3 m); cell at 221 | Ground in both gaps with full side access; cell reachable after any miss |
| 230–250 | Cell return and transfer | Cooling station at 234, transfer at 245 | Reversible to cell roof with side ladder; no cell granted by script |

Short prompts before the corresponding challenge, any new button dismisses. No tutorial condition substitutes for physical route design. Intended first-play duration 4–6 minutes including reading, learning and retries; measure actual input-driven duration separately rather than calling a target a measurement.

## Ladder contract

Opt-in side mounting rotates the existing authored root-motion frame and the actor together. Geometry, rung contacts, entry and roof landing share that frame. Preserve normal ladders. Side mount must be approached from outside the wall, top descent from a safe inset on the roof. Test both wall orientations, pause/reverse mid-climb, roof landing, descent, and jumping away. No wall teleporting to acquire a ladder.

## Scenery contract

Continuous fixed near elevations over the full 250 m, cropped around dedicated cooling-station plots. The cooling façade, its socket, roof plant and transverse duct form one structure. Mid and far layers retain their approved treatment. Inspect ground and roof views in both directions; scenery meshes must never be culled by the narrow prop budget.

## Required evidence

Normal scene, spawn to real cell pickup to transfer into Level 2, driven by inputs only. Separate failed-jump recovery run, first-climb bypass attempts, both directions of side ladders, each gap floor, reverse traversal, and headroom tests. Capture side-ladder, full-gap and cooling-building views. Record physics time and wall time explicitly, including how prompts were treated. Log any limitation honestly.

## Results and user review

Input-driven rendered completion passed, including actual collection and transition to Level 2. Recorded 179.37 seconds of active physics, 47.81 seconds of prompt pauses (four seconds each), and 234.56 seconds wall time including rendering/capture/loading overhead. This is an automated mixed walk/run route, not a measured novice first play. A faster player can finish sooner than the 4–6 minute design target.

Separate recovery test passed all six building gaps and five tower gaps, standing-blocked duct approaches, first-ladder bypass attempts, and full reverse travel to spawn. Side-ladder diagnostics passed hold, mid-climb reversal, jump-away, remount, roof descent and prevention of remote grabs. Logs and rendered captures are in `Builds/Validation/Level1Rebuild`.

Review changes: amber side rails with pale rungs; recessed backing and dimensional façade returns close scenery seams around the repeated elevations; removed original Level 1 messages 01–05, 07, 08 and 11. Four prompts remain. The recorded completion time predates this prompt reduction. Traversal layout is unchanged. Level 2/3 scene hashes and authored layout functions are unchanged.
