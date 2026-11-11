@tool
extends SceneTree

func _init() -> void:
	var mockup_scene: PackedScene = load("res://scenes/miko8_side_on_mockup.tscn")
	var mockup = mockup_scene.instantiate()
	root.add_child(mockup)
	for f in range(5): await process_frame

	var actor = mockup.get("actor") as CharacterBody3D
	actor.reset_actor()
	await process_frame

	actor.position = Vector3(23.3, 0.02, 0.0)
	actor.facing = 1
	actor.target_facing = 1
	actor.velocity = Vector3.ZERO
	await process_frame

	Input.action_press("miko8_right")
	for f in range(10): await process_frame
	Input.action_press("miko8_jump")

	for frame in range(90):
		await process_frame
		if actor.state == "Mantle":
			var t = clampf(actor.state_time / actor.mantle_duration, 0.0, 1.0)
			print("f=%02d st_time=%.3f dur=%.3f t=%.3f pos=(%.3f, %.3f)" % [
				frame, actor.state_time, actor.mantle_duration, t, actor.position.x, actor.position.y
			])
		elif actor.position.x > 24.0 and actor.is_on_floor():
			print("Landed! f=", frame, " pos=", actor.position, " state=", actor.state)
			break

	Input.action_release("miko8_right")
	Input.action_release("miko8_jump")
	mockup.free()
	quit(0)
