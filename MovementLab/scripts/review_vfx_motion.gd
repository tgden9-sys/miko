extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var lab = load("res://lab.tscn").instantiate()
 root.add_child(lab)
 current_scene=lab
 lab.actor.automation=true
 lab.diagnostics.hide()
 for i in range(20): await physics_frame
 lab.actor.position.x=-.9
 for tick in range(300):
  if tick in [8,20,36]: lab.actor.press("attack")
  if tick==95:
   lab.reset_room()
   lab.actor.position.x=-1.0
   lab.actor.command_held=true
   lab.actor.press("jump")
  if tick in [105,117]: lab.actor.press("attack")
  if tick==158:
   lab.reset_room()
   lab.actor.position.x=1.3
   lab.actor.facing=-1
  if tick in [165,180]: lab.actor.press("attack")
  if tick==220:
   lab.reset_room()
   lab.actor.position.x=-1.2
   lab.actor.command_held=true
   lab.actor.press("jump")
  if tick==239:
   lab.actor.command_vertical=-1
   lab.actor.press("attack")
  await physics_frame
  await process_frame
  await RenderingServer.frame_post_draw
  if tick%2==0:
   root.get_texture().get_image().save_png("C:/Users/tgden/Desktop/MIKO/Builds/Validation/MovementLab/vfx_review/frame_%04d.png"%tick)
 print("VISUAL_MOTION_CAPTURE_COMPLETE")
 quit()
