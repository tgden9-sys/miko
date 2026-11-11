# Hand lasers and spell aiming

**Current follow-up (4 November 2026):** guide rendering now uses camera-facing ribbons with a stable screen width, replacing the subpixel cylinders. Red/blue single-hand charging and purple projectiles retain their existing controls. Four alternating red/blue charges and free-aim checks passed in the GPU regression. See [pressure switch and aim follow-up](MIKO8_PRESSURE_SWITCH_V2_AND_AIM.md). The notes below retain the earlier iteration history.

Movement demo: right stick aims; I/J/K/L provides keyboard aiming. LT/Q prepares single-hand magic, RT/E prepares both hands, releasing casts. Left hand laser is red; right hand is blue. The beams are visible while preparing and shooting. A cast ray hits the first floor, platform or target within 24 m and excludes the caster. Target damage is applied on release, once per participating hand. This replaces the demo's travelling green/blue spell orbs.

Aim elevation ranges from -45 to +90 degrees on each side. Right-stick horizontal direction selects facing with a small dead band around vertical; aim stays at its last direction when released. Pitch follows smoothly at 8 radians/second. The existing spell poses keep their elbow bend and hand shape, with an additional SkeletonModifier rotating each casting arm. Non-casting motion blends back to the original animation.

Rendered hand positions are cached after the skeleton modifiers update, so firing rays and visible laser origins use the raised/lowered hands rather than the unmodified animation's hands. Game remains on the X/Y movement plane.

Validation: verify_miko8_spell_aim.gd sends right-stick input and checks both casting forearms align with beams through the requested sweep, facing changes, floor clipping, release counts and beam cleanup. Rendered views: Builds/Validation/MIKO8/ladder_candidates/aim_*.png. verify_miko8_abilities.gd checks single/double target hits in both directions, source animation integrity and ladder transitions.

Latest tuning: L1/Q selects red left hand; R1/E selects blue right hand; R2/F selects two purple plasma beams. Aim pitch is capped at 1.8 radians/sec, with a 0.35 stick dead zone and 2.5-degree angular jitter filter. Beam radius reduced from 0.009 m to 0.003 m. Hold and release casting remains the same. Verified by verify_miko8_laser_controls.gd.

Proportional aim update: stick magnitude now controls angular speed with a squared response (maximum 1.8 rad/s), dead zone 0.12. Neutral cancels the previous target immediately. 20% processed stick strength yields about 4.1 deg/s; 80% yields about 66 deg/s. Shoot and exit durations are .14 and .10 seconds, with damage at .025 seconds after release. Early release from preparation also enters this short firing sequence.

Beam visibility update: core radius .002m, alpha .48, subtle additive halo radius .007m at alpha .09. Plasma uses only two short hand beams meeting .32m ahead, with no outgoing trunk. Travelling bolt on release retained. Verified by verify_miko8_plasma_guides.gd.


Latest plasma presentation: a shaded purple energy ball is held midway between the hands. Only one central targeting line is shown; the two hand branches are removed. On release the held ball disappears and one travelling bolt launches. Held ball and guide placement, harmless targeting and projectile collision were verified.


Single-targeting pose: both red and blue now use the approved red hand action and the same left-hand emitter. Beam colour is selected independently of the hand. Two-hand plasma is unchanged.
