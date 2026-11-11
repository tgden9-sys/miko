extends SceneTree
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var level=load("res://scenes/miko8_miniature_2d.tscn").instantiate();root.add_child(level)
	await create_timer(3).timeout
	assert(level.camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
	assert(level.has_node("InvisibleGameplayFloor") and not level.has_node("PaintedGroundKit"))
	assert(absf(level.camera.unproject_position(Vector3(level.WIDTH/2,0,0)).y-720.0)<.5)
	assert(absf(11.25/level.camera.size-.75)<.001,"Character projection must be25% smaller")
	var art_top:Vector2=level.camera.unproject_position(level.stage.to_global(Vector3(0,level.SCENE_HEIGHT/2,0)))
	assert(absf(art_top.y+(level.ART_FOOT_ROW*1080)-720)<.5,"Artwork landing line must match the physical floor")
	var image:Image=(load("res://art/tutorial/miniature_2d/bridge_stage.png") as Texture2D).get_image()
	assert(image.get_pixel(image.get_width()/2,image.get_height()/4).a<.01)
	var actor=level.actor
	assert(actor.is_on_floor() and actor.state.begins_with("GroundSit"))
	Input.action_press("miko8_right",.65);await create_timer(actor._duration("GroundSitExit")+.4).timeout;Input.action_release("miko8_right")
	assert(not actor.state.begins_with("GroundSit"))
	actor.reset_actor();actor.position=Vector3(8,.02,0);await ticks(5)
	Input.action_press("miko8_jump");await ticks(1);Input.action_release("miko8_jump")
	var peak:=0.0
	for i in range(130):
		await physics_frame;peak=maxf(peak,actor.position.y)
	assert(peak>.3 and actor.is_on_floor())
	actor.reset_actor();actor.position=Vector3(level.CRATE_X-2.5,.02,0);await ticks(5)
	Input.action_press("miko8_right",1.0);await ticks(100);Input.action_release("miko8_right")
	assert(actor.position.x<level.CRATE_X-.2 and actor.position.x>level.CRATE_X-1.7,"3D crate must block the player")
	var start:=Time.get_ticks_msec();var frames:=0
	while Time.get_ticks_msec()-start<3000:await process_frame;frames+=1
	print("MINIATURE_2D_STEADY_FPS ",frames*1000.0/(Time.get_ticks_msec()-start))
	print("MINIATURE_2D_PASS: orthographic pixel alignment, real transparent near art/city separation, wake, jump/land, solid crate; actor scripts unchanged")
	quit()
