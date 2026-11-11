extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var stage:=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("596573")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c5d2e2");env.ambient_light_energy=0.7
	world.environment=env;stage.add_child(world)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=0.9;stage.add_child(light)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.4;camera.position=Vector3(0,1.6,4);stage.add_child(camera);camera.look_at(Vector3(0,0.4,0));camera.current=true
	for i in range(3):
		var crate=load("res://scripts/miko8_charge_box.gd").new()
		crate.position=Vector3((i-1)*1.25,0.4,0);crate.rotation.y=deg_to_rad(12);stage.add_child(crate);crate.freeze=true
		if i==1:crate.lock_in_color(Color.RED)
		if i==2:crate.lock_in_color(Color.BLUE)
		assert(crate.charge_materials.size()>=1)
		var mesh:MeshInstance3D=crate.display_root.find_children("*","MeshInstance3D",true,false)[0]
		var triangles:=0
		for surface in range(mesh.mesh.get_surface_count()):triangles+=mesh.mesh.surface_get_array_index_len(surface)/3
		assert(triangles<6000)
	await create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../Builds/Validation/MIKO8/art_revision/crate_states.png")
	print("CRATE_PASS: source model installed, under 6000 triangles, neutral/red/blue panels")
	quit()
