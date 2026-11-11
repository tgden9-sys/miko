extends SceneTree
func _initialize() -> void: call_deferred("run")
func ticks(count: int) -> void:
	for i in range(count): await physics_frame
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/" + label + ".png")
func capture_combo() -> void:
	var frames: Array[Image] = []
	for frame in range(58):
		if frame == 8: Input.action_press("miko8_quick_blaster")
		if frame == 50: Input.action_release("miko8_quick_blaster")
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var region := Rect2i(Vector2i(picture.get_width() / 4, picture.get_height() / 5), Vector2i(picture.get_width() / 2, picture.get_height() * 3 / 5))
		frames.append(picture.get_region(region))
	var output := FileAccess.open("res://../Builds/sword_motion.frames", FileAccess.WRITE)
	var sheet := Image.create(frames[0].get_width() * 4, frames[0].get_height() * 3, false, frames[0].get_format())
	for i in range(frames.size()):
		var encoded := frames[i].save_webp_to_buffer(false, .88)
		output.store_32(encoded.size())
		output.store_buffer(encoded)
		if i % 4 == 0 and i >= 8 and i < 56:
			var tile := i / 4 - 2
			var size := frames[i].get_size()
			sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, size), Vector2i(tile % 4, tile / 4) * size)
	sheet.save_png("res://../Builds/sword_motion_sheet.png")
	quit()

func run() -> void:
	var level: Node3D = load("res://scenes/miko7_patrol_yard.tscn").instantiate()
	root.add_child(level)
	await ticks(15)
	var actor: CharacterBody3D = level.actor
	actor.reset_actor()
	actor.position = Vector3(17.2, .02, 0)
	actor.facing = 1
	actor.visual.rotation.y = PI * .5
	for enemy in get_nodes_in_group("level4_wardens"): enemy.set_physics_process(false)
	await ticks(15)
	level.fade.color.a = 0.0
	level.set_process(false)
	level.set_physics_process(false)
	level.camera.global_position = Vector3(18, 2.5, 7)
	level.camera.look_at(Vector3(18, 1.1, 0))
	level.camera.size = 5.5
	if "--idle" in OS.get_cmdline_user_args():
		Input.action_press("miko8_quick_blaster")
		await ticks(4)
		Input.action_release("miko8_quick_blaster")
		await ticks(24)
		await capture("sabre_idle")
		var combat: Node = actor.abilities.combat
		while combat.lit > 0.0: await physics_frame
		await ticks(5)
		await capture("sabre_retracting")
		await ticks(18)
		await capture("sabre_retracted")
		quit()
		return
	if "--combo" in OS.get_cmdline_user_args():
		await capture_combo()
		return
	Input.action_press("miko8_quick_blaster")
	await ticks(8)
	await capture("combat_sword_review")
	Input.action_release("miko8_quick_blaster")
	await ticks(30)
	Input.action_press("miko8_spell_double")
	await ticks(12)
	await capture("combat_shield_review")
	Input.action_release("miko8_spell_double")
	quit()
