extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/tgden/Desktop/MIKO/Builds/Validation/MovementLab/revised_"+label+".png")
func run() -> void:
 var lab = load("res://lab.tscn").instantiate()
 root.add_child(lab)
 current_scene=lab
 lab.actor.automation=true
 for i in range(10): await physics_frame
 lab.set_process(false)
 lab.actor.set_physics_process(false)
 lab.actor.position=Vector3(-1,0,0)
 lab.camera.position=Vector3(0,1.6,18)
 lab.camera.size=5.3
 for facing in [1,-1]:
  lab.actor.facing=facing
  lab.actor.visual.rotation.y=facing*PI*.5
  lab.actor.trail_edges.clear()
  lab.actor._start_attack("normal",0)
  for i in range(13):
   lab.actor.age=float(i)/60
   lab.actor._animate(1.0/60)
   lab.actor._update_trail()
   if i in [5,8,11]: await shot("sword_%s_%s"%[facing,i])
 lab.actor.trail.clear_surfaces()
 lab.actor.visual.rotation.y=PI*.5
 lab.actor.player.play(lab.actor._clip("GroundPound"),0)
 lab.actor.player.seek(.333,true)
 lab.actor.player.advance(0)
 lab._attack_effect(Vector3(.65,0,0),1,0,true)
 var fx=get_nodes_in_group("attack_effects")[-1]
 fx.set_process(false)
 for t in [.05,.16,.32]:
  fx.age=t
  fx._draw()
  await shot("slam_%s"%int(t*100))
 quit()
