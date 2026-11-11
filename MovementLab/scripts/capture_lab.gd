extends SceneTree
var lab: Node3D
var out := "C:/Users/tgden/Desktop/MIKO/Builds/Validation/MovementLab/"
var prefix := ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--prefix="): prefix = argument.trim_prefix("--prefix=")
	call_deferred("run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+prefix+label+".png")
	print("CAPTURE ",label)

func run() -> void:
	lab = (load("res://lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.actor.automation = true
	for i in range(15): await process_frame
	await capture("room")
	lab.actor.set_physics_process(false)
	lab.dummy.set_physics_process(false)
	lab.set_process(false)
	for layer: CanvasLayer in lab.find_children("*","CanvasLayer",true,false): layer.hide()
	lab.dummy.hide()
	lab.actor.position = Vector3(0,0,0)
	lab.camera.position = Vector3(0,1.03,18)
	lab.camera.size = 2.75
	for facing in [1,-1]:
		lab.actor.visual.rotation.y = facing*PI*.5
		for spec: Array in [["SwordIdle",.4],["Sprint",.2],["SwordA",7.0/30],["SwordB",7.0/30],["SwordC",14.0/30],["AirIdle",.5],["GroundPound",10.0/30],["Dash",.2],["AirA",8.0/30],["AirCombo",22.0/30],["Uppercut",6.0/30],["DoubleJump",.4],["SwordBlock",.2]]:
			lab.actor.player.play(lab.actor._clip(spec[0]),0)
			lab.actor.player.seek(spec[1],true)
			lab.actor.player.advance(0)
			var head: int = lab.actor.skeleton.find_bone("DEF-head")
			lab.actor.skeleton.set_bone_pose_rotation(head,lab.actor.skeleton.get_bone_pose_rotation(head)*Quaternion(Vector3.RIGHT,deg_to_rad(-30)))
			await capture("pose_%s_%s" % [spec[0],facing])
	quit()
