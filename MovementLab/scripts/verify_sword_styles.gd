extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab_scene := load("res://lab.tscn") as PackedScene
	var lab := lab_scene.instantiate()
	root.add_child(lab)
	current_scene = lab
	var actor = lab.actor
	actor.automation = true
	
	print("TESTING 10 SWORD STYLES...")
	assert(actor.SWORD_STYLES.size() == 10, "Must have exactly 10 sword styles")
	
	for i in range(10):
		actor.set_sword_style(i)
		assert(actor.sword_style == i, "Style index mismatch")
		var s: Dictionary = actor.SWORD_STYLES[i]
		var shader_mode: int = actor.ribbon_mat.get_shader_parameter("style_mode")
		assert(shader_mode == s.style_mode, "Shader parameter not updated")
		print("STYLE %d: %s (mode=%d, swath=%.2f-%.2f, life=%.2f, spark=%s)" % [
			i + 1, s.name, s.style_mode, s.swath_base, s.swath_tip, s.life, s.spark_type
		])
		# Test a swing with this style
		actor.press("attack")
		for f in range(15):
			await physics_frame
			await process_frame
		assert(actor.state == "attack" or actor.state == "move", "Invalid state during swing")
	
	# Test cycling forward and backward
	actor.set_sword_style(0)
	actor.next_sword_style()
	assert(actor.sword_style == 1, "next_sword_style failed")
	actor.prev_sword_style()
	assert(actor.sword_style == 0, "prev_sword_style failed")
	actor.prev_sword_style()
	assert(actor.sword_style == 9, "prev_sword_style wrap-around failed")
	actor.next_sword_style()
	assert(actor.sword_style == 0, "next_sword_style wrap-around failed")
	
	print("ALL 10 SWORD STYLES VERIFIED SUCCESSFULLY!")
	quit(0)
