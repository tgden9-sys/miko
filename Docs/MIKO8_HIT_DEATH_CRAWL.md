# Hit, death and crawl animations

Eight source clips added from the user ZIPs in AnimationTemplates:
- CrawlEnter, CrawlIdle, CrawlForward, CrawlExit
- Death1 (death01 alternate 2), Death2
- HitKnockback, HitKnockbackRM

The existing character model and accepted movement animations remain in place. The added tracks use the same canonical skeleton conversion, sampled at 30Hz with native source durations. Per-clip source-transform errors are recorded in Builds/Validation/MIKO8/reactions/source_conversion.json (all under .000004). Full sampled animation data is Game/models/miko8/MIKO8_Reactions.json. Animation-only Blender master: Source/Character/MIKO8/MIKO8_Reactions_Rig.blend. Builder: build_reaction_library.py.

Movement-demo controls:
- L3 (left stick click) or Z: crawl / stand. Left stick or A/D moves while crawling.
- H: hit/knockdown test. The source ends down; it holds there instead of snapping to standing.
- Delete: death 1. Shift+Delete: death 2.
- R / Reset: restore control and the standing collider.
- All eight clips are also selectable in the existing animation preview dropdown, including the root-motion knockback variant.

Crawling uses a horizontal capsule and stand-up clearance checks. Enter/exit play at source timing, with blends into moving/idle crawl. Source hand-contact travel gives crawl speed about .441m/s. Death/knockdown use their native head pose rather than the gameplay gaze lift. There is no health/enemy damage system added here: take_hit() and die(variant) are callable actor hooks plus manual demo controls. A get-up animation has not been supplied.

Validation: verify_miko8_reactions.gd samples all eight clips at five phases, checks finite bone transforms, crawl enter/move/idle/exit, knockdown/death holds and Reset. verify_miko8_crawl_safety.gd tests actual L3 input, blocked stand-up under a roof, clear-space stand-up, collider restoration and knockdown final-pose hold. Rendered poses inspected in Builds/Validation/MIKO8/reactions.

Timing update: crawl enter, forward and exit play at 1.5x with matching travel (~.66m/s); idle keeps native breathing timing. User Reset now uses .22s fade-out, .25s black hold and .35s fade-in, with controls disabled until completion. Internal clip selection/reset remains immediate so preview and ladder placement behave correctly. verify_miko8_crawl_reset_timing.gd passed.


Light-hit update: all three new clips are included (11 reaction/crawl/death clips, 45 total demo clips). H now uses HitShoulderLeft as the restrained default; Shift+H uses HitHead, Ctrl+H uses HitStomach, Alt+H keeps the knockdown test. Light hits recover automatically to standing/locomotion; knockdown still holds down. Source durations are .533s shoulder, .433s head and .667s stomach. verify_miko8_light_hits_landing.gd passed all three recovery checks and run/sprint landing carry checks; rendered light-hit poses inspected.
