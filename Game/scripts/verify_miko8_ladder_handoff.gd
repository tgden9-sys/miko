extends SceneTree
func _initialize():call_deferred("run")
func run():
 var level=load("res://scenes/miko8_movement_test.tscn").instantiate()
 root.add_child(level)
 var a=level.actor
 var ladder=get_nodes_in_group("miko8_ladders")[0]
 for strength in [0.0,0.35,0.65,1.0,-0.65]:
  a.reset_actor()
  a.abilities.ladder=ladder
  a.abilities.saved_mask=a.collision_mask
  a.collision_mask=0
  a.position=Vector3(ladder.climb_x,ladder.top_y-0.45,0)
  var action="miko8_left" if strength<0 else "miko8_right"
  if strength!=0:Input.action_press(action,absf(strength))
  a.abilities._exit_ladder(true)
  var previous=a.position.x
  var end_speed=0.0
  for i in range(85):
   await physics_frame
   if a.state!="ClimbTopExit":break
   end_speed=(a.position.x-previous)*60
   previous=a.position.x
  assert(a.state!="ClimbTopExit")
  assert(absf(end_speed-a._speed("Walk"))<0.12)
  assert(a.state!="MoveStart")
  assert(a.collision_mask!=0 and a.abilities.ladder==null)
  if strength>0:assert(a.current_clip==a._gait(strength))
  for i in range(12):await physics_frame
  if strength==0:assert(absf(a.velocity.x)<0.01 and a.current_clip=="Idle")
  if strength>0:assert(a.state=="Locomotion" and a.velocity.x>0)
  Input.action_release(action)
  print("LADDER_EXIT_CASE ",strength," end step=",end_speed)
 print("LADDER_EXIT_HANDOFF_PASS")
 quit()
