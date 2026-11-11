extends SceneTree

var lab: Node3D
var out_dir := "C:/Users/tgden/.gemini/antigravity/brain/d0780195-ffa3-4f45-840a-58f36cabe197/"

func _initialize() -> void:
	call_deferred("run")

func shot(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := out_dir + label + ".png"
	img.save_png(path)
	print("SAVED: ", path)

func run() -> void:
	lab = (load("res://lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.actor.automation = true
	
	# Wait for initial scene setup
	for i in range(10):
		await process_frame
	
	lab.set_process(false)
	lab.actor.set_physics_process(false)
	lab.dummy.set_physics_process(false)
	
	# Frame the actor nicely
	lab.actor.position = Vector3(0, 0, 0)
	lab.camera.position = Vector3(0.4, 1.25, 18.0)
	lab.camera.size = 3.6
	
	# ---------------------------------------------------------
	# 1. SWORD A (LIGHT ATTACK 1 - FOREHAND SLASH - CYAN)
	# ---------------------------------------------------------
	lab.actor.facing = 1
	lab.actor.visual.rotation.y = PI * 0.5
	lab.actor.combo = 0
	lab.actor.state = "attack"
	lab.actor.trail_edges.clear()
	lab.actor.trail_ages.clear()
	lab.actor.trail.clear_surfaces()
	lab.actor._start_attack("normal", 0)
	
	for frame_idx in range(16):
		lab.actor.age = float(frame_idx) / 60.0
		lab.actor._animate(1.0 / 60.0)
		lab.actor._update_trail()
		if frame_idx == 7:
			await shot("ozone_wake_sword_a_mid")
		elif frame_idx == 9:
			await shot("ozone_wake_sword_a_peak")

	# ---------------------------------------------------------
	# 2. SWORD B (LIGHT ATTACK 2 - BACKHAND SWEEP - CYAN)
	# ---------------------------------------------------------
	lab.actor.combo = 1
	lab.actor.state = "attack"
	lab.actor.trail_edges.clear()
	lab.actor.trail_ages.clear()
	lab.actor.trail.clear_surfaces()
	lab.actor._start_attack("normal", 1)
	
	for frame_idx in range(16):
		lab.actor.age = float(frame_idx) / 60.0
		lab.actor._animate(1.0 / 60.0)
		lab.actor._update_trail()
		if frame_idx == 7:
			await shot("ozone_wake_sword_b_mid")
		elif frame_idx == 9:
			await shot("ozone_wake_sword_b_peak")
	
	# ---------------------------------------------------------
	# 3. SWORD C (FINISHER - OVERHEAD SOMERSAULT - GOLDEN AMBER)
	# ---------------------------------------------------------
	lab.actor.combo = 2
	lab.actor.state = "attack"
	lab.actor.trail_edges.clear()
	lab.actor.trail_ages.clear()
	lab.actor.trail.clear_surfaces()
	lab.actor._start_attack("normal", 2)
	
	for frame_idx in range(24):
		lab.actor.age = float(frame_idx) / 60.0
		lab.actor._animate(1.0 / 60.0)
		lab.actor._update_trail()
		if frame_idx == 11:
			await shot("ozone_wake_sword_c_mid")
		elif frame_idx == 14:
			await shot("ozone_wake_sword_c_peak")
			
	# ---------------------------------------------------------
	# 4. GROUND STRIKE (CEL OZONE IMPACT SHOCKWAVE & SMOKE PUFFS)
	# ---------------------------------------------------------
	lab.actor.trail.clear_surfaces()
	lab.actor.trail_edges.clear()
	lab.actor.trail_ages.clear()
	lab.actor.position = Vector3(-0.6, 0.0, 0.0)
	lab.camera.position = Vector3(0.0, 1.30, 18.0)
	lab.camera.size = 4.5
	
	# Set Miko in ground landing strike pose
	lab.actor.player.play(lab.actor._clip("GroundPound"), 0)
	lab.actor.player.seek(10.0 / 30.0, true)
	lab.actor.player.advance(0)
	
	# Spawn ground impact effect at the katana contact point
	lab._attack_effect(Vector3(0.0, 0.0, 0.0), 1, 0, true)
	var slam_nodes := lab.get_tree().get_nodes_in_group("attack_effects")
	var slam_fx = slam_nodes[-1]
	slam_fx.set_process(false)
	
	for t_sample in [0.06, 0.16, 0.32]:
		slam_fx.age = t_sample
		slam_fx.slam_material.set_shader_parameter("age", t_sample)
		await shot("ground_strike_age_%d" % int(t_sample * 100))
			
	print("ALL CAPTURES COMPLETED")
	quit()
