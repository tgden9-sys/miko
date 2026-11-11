# Miko movement rework — 9 November 2026

Launch **Play Movement Lab.cmd** in the workspace root. Close an already running lab and reopen it to pick up script/animation changes.

This is a separate Godot project in `MovementLab`, containing Miko, a plain floor, one raised platform and one training dummy. It does not load the title screen, tutorial, level art, ability systems, enemies or scenery from `Game`. The existing game and character masters are unchanged.

## Agreed direction

- Reference: **Prince of Persia: The Lost Crown**, side-on 2.5D.
- One sword, controller first.
- A jump/double jump; X sword; B ground/air dash; LB timed parry.
- Up + X: launcher. Down + X while airborne: ground pound.
- Y toggles the dummy's telegraphed attacks for parry practice. View resets the room. R3 switches close/gameplay view.
- Keyboard: A/D or arrows move, Space jump, J sword, Shift dash, K parry, W/S or arrows modify attack, T dummy, R reset, Z view, Escape quit.

The original Gemini discussion supplied ideas, not instructions or verified measurements. Useful principles retained are physics-driven locomotion, buffering/coyote time, variable jump height, recovery cancels, source animation retiming, planar hit detection, contact hitstop and sword trails. Its exact frame-count claims are not treated as measured Lost Crown data, and its promise of finished movement in an afternoon was not a realistic completion criterion.

Ubisoft's own descriptions identify the combination of rapid combos, launchers, airborne juggling, downward slams and transitions between movement and attacks as central to the reference. They also describe wall jumps, slides, timed parries and air dash. This room implements the basic movement/combat subset; it does not claim to reproduce every Lost Crown ability.

- https://news.ubisoft.com/en-us/article/e1SD5gR3TWqk5GPAjWHSz
- https://news.ubisoft.com/en-au/article/7jgsjVcfOTfZVKiT5496sG/prince-of-persia-the-lost-crowns-mount-qaf-is-filled-with-surprises

## Animation editing and timing

Original files and converted source samples are retained unchanged. The controller selects source windows and samples them through separate startup, contact and recovery ranges. Thus a long source wind-up can play quickly without speeding the contact pose and recovery by the same factor. Hitboxes use the same action clock. These are initial tuning choices, not Ubisoft's private timing values.

| Action | Original source | Playable timing | Source contact frames at 30 fps |
|---|---|---|---|
| Ground A | 0.367 s | 75 ms startup + 65 ms active + 150 ms recovery | 7–8 |
| Ground B | 0.433 s | 85 + 75 + 160 ms | 7–10 |
| Ground C | 0.867 s | 115 + 100 + 200 ms | 14–17 |
| Aerial A | 0.400 s | 75 + 70 + 130 ms | 7–9 |
| Aerial B | Combo source 0.400–1.000 s | 90 + 75 + 160 ms | 21–23 |
| Uppercut | 0.700 s | 100 + 75 + 190 ms | 5.5–7.5 |
| Sword parry | 1.233 s | 340 ms total; defence from 25–170 ms | Source block section 0.16–0.56 s |
| Double jump | 0.900 s | 480 ms flip | Full source |
| Sword dash | 1.567 s | 150 ms travel, source 0.02–0.38 s | No attack damage |
| Ground pound | 1.167 s | 110 ms preparation; descent until physical contact; 240 ms recovery | Hold overhead frame 8 in descent, land at frame 10 |

Attack inputs queue a subsequent strike. Ground combos have three strikes; air combos use the supplied aerial A and the second portion of the aerial combo loop. Jump, dash and parry can cancel attack recovery after the active window. Animation blend time advances during manual retiming; it cannot remain frozen at its entry pose.

The new supplied clips now drive aerial idle, both aerial strikes, aerial recovery, double jump, uppercut, ground pound, sword block and sword dash. The same sword dash supplies the ground and air dash silhouette. A dedicated aerial dash and a parry-counter clip remain possible refinements. A block clip provides the current timed parry pose; there is no separate automatic counterattack.

## Air-attack correction

The first controller added upward velocity at every airborne attack. This could produce indefinite climbing, and its temporary grounded attack poses looked wrong in the air. Both were replaced:

- Air attacks use the supplied aerial clips, including their leg poses.
- Starting an attack never increases vertical velocity.
- A total 140 ms reduced-gravity budget is available near the jump apex per airtime; attacks cannot replenish it.
- Landing exits an airborne attack pose.
- Only jumping/double jumping deliberately adds upward velocity. Dash holds vertical position for its fixed 150 ms burst and is limited to one per airtime.

The spam-attack regression test reaches about 1.94 m versus 1.89 m for an ordinary held jump, then lands. The small difference is the bounded apex hang, not repeated upward impulses.

## Character and optimisation

At the user's request, further mesh optimisation is deferred. The lab uses the exact existing **28,546-triangle FastLOD** geometry, UVs, weights, atlas and 53-bone skeleton used by the current tutorial. `MovementLab/models/Miko.glb` exposes only the six required base locomotion clips and is about 7.68 MB. Additional actions are loaded from the two lab JSON libraries. This pass does not claim a new visual-preserving polygon reduction.

More aggressive early reductions were rejected after visual inspection. Their assets and screenshots are validation experiments, not the lab's default model. Original full-resolution and existing gameplay assets remain in `Game` and `Source/Character/MIKO8`.

The three-tone shader is carried over from the existing game. Broad performance optimisation and a representative FPS benchmark are deferred; cold screenshot FPS labels are not performance results.

## Validation and source

`MovementLab/scripts/verify_lab.gd` exercises real physics and verifies launch latency, tap/held height, double-jump limits, no climbing from attack spam, dedicated airborne clips, reversal, dash distance and limits, landing buffers, coyote time, combo damage, cancels, launcher/slam, parry direction, platform collision/landing, plane lock and controller mappings. Results are saved under `Builds/Validation/MovementLab`.

`capture_lab.gd` renders side views of the actual Godot rig in both directions. Final review images use the `final_` prefix. Artist/controller playtesting is still necessary to judge cadence, readability and comfort; numeric tests do not certify those qualities.

Rebuild new clips with `Source/Character/MovementLab/build_assets.py` under Blender 5.2. It applies the existing canonical bone-basis conversion and checks source world matrices at every source sample. `animation_conversion.json` records numerical errors. `asset_report.json` identifies the model and exact clips. The script never saves over a master Blender file.

All supplied animation ZIPs are retained in `AnimationTemplates`, with extracted sources under `Source/Character/MovementLab`. Source README text is treated as provenance. Quaternius animation libraries are CC0: https://quaternius.com/packs/universalanimationlibrary2.html
