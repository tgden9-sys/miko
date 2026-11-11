extends SceneTree
func _initialize():call_deferred("run")
func run():
 var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
 root.add_child(level)
 var a=level.actor
 for group in ["miko8_charge_targets","miko8_spell_targets"]:
  for target in get_nodes_in_group(group):target.queue_free()
 for strength in [0.65,0.80,1.0]:
  for direction in [-1,1]:
   a.reset_actor()
   a.position.x=0
   var action="miko8_left" if direction<0 else "miko8_right"
   Input.action_press(action,strength)
   for i in range(95):await physics_frame
   print("GAIT_CHECK ",direction," input=",a._axis()," clip=",a.current_clip," velocity=",a.velocity.x," rate=",a.animation_player.speed_scale)
   assert(a.current_clip==("Run" if strength<0.78 else "Sprint"))
   assert(signf(a.velocity.x)==direction)
   Input.action_release(action)
   for i in range(30):await physics_frame
 print("DIRECTION_SYMMETRY_PASS")
 quit()
