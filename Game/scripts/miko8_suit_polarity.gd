extends Node
var actor:CharacterBody3D
var materials:Array[ShaderMaterial]=[]
var original_materials:Array[ShaderMaterial]=[]
var graphic_materials:Array[ShaderMaterial]=[]
var material_slots:Array[Dictionary]=[]
var three_tone_enabled:=false
var initialized:=false
var active_fx:Array[Node3D]=[]
var transfer_outline:ShaderMaterial

func set_transfer(progress:float,charge:float,floor_height:float)->void:
	# Scene outlines are shared with architecture. Give the transferring actor
	# its own outline so the dissolve never affects another object.
	if not transfer_outline:
		for graphic in graphic_materials:
			if graphic.next_pass is ShaderMaterial:
				transfer_outline=graphic.next_pass.duplicate() as ShaderMaterial
				break
		if transfer_outline:
			for graphic in graphic_materials:graphic.next_pass=transfer_outline
	var surfaces:Array[ShaderMaterial]=original_materials+graphic_materials
	if transfer_outline:surfaces.append(transfer_outline)
	for surface in surfaces:
		surface.set_shader_parameter("transfer_progress",progress)
		surface.set_shader_parameter("transfer_charge",charge)
		surface.set_shader_parameter("transfer_floor",floor_height)

func _ready()->void:
	for mesh:MeshInstance3D in actor.model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original:=mesh.get_active_material(surface) as StandardMaterial3D
			if not original:continue
			var replacement:=ShaderMaterial.new()
			replacement.shader=preload("res://shaders/miko8_polarity_preview.gdshader")
			replacement.set_shader_parameter("base_texture",original.albedo_texture)
			replacement.set_shader_parameter("metal_rough_texture",original.metallic_texture)
			replacement.set_shader_parameter("metallic_factor",original.metallic)
			replacement.set_shader_parameter("roughness_factor",original.roughness)
			mesh.set_surface_override_material(surface,replacement)
			materials.append(replacement)
			original_materials.append(replacement)
			var graphic:=ShaderMaterial.new();graphic.shader=preload("res://shaders/miko8_three_tone.gdshader")
			graphic.set_shader_parameter("base_texture",original.albedo_texture)
			graphic.set_shader_parameter("metal_rough_texture",original.metallic_texture)
			graphic.set_shader_parameter("metallic_factor",original.metallic)
			graphic.set_shader_parameter("roughness_factor",original.roughness)
			graphic_materials.append(graphic);material_slots.append({"mesh":mesh,"surface":surface})
	set_polarity(0,true)
	initialized=true

func _process(_delta:float)->void:
	_update_active_fx()

func _physics_process(_delta:float)->void:
	_update_active_fx()

func _update_active_fx()->void:
	if not is_instance_valid(actor):return
	var target_pos:=actor.global_position+Vector3(0,0.85,0.12)
	for i in range(active_fx.size()-1,-1,-1):
		var fx:=active_fx[i]
		if is_instance_valid(fx):
			fx.global_position=target_pos
		else:
			active_fx.remove_at(i)

func set_three_tone(enabled:bool)->void:
	if three_tone_enabled==enabled:return
	var next_materials:Array[ShaderMaterial]=graphic_materials if enabled else original_materials
	for index in range(materials.size()):
		for parameter:String in ["scene_tint","scene_roughness_bias"]:
			next_materials[index].set_shader_parameter(parameter,materials[index].get_shader_parameter(parameter))
		var slot:Dictionary=material_slots[index]
		slot.mesh.set_surface_override_material(slot.surface,next_materials[index])
	materials.assign(next_materials);three_tone_enabled=enabled
	set_polarity(actor.suit_polarity,true)

func set_polarity(pole:int,silent:=false)->void:
	var old_polarity:int=actor.suit_polarity if actor else 0
	var new_polarity:int=clampi(pole,0,2)
	actor.suit_polarity=new_polarity
	for material in materials:material.set_shader_parameter("polarity",actor.suit_polarity)
	if initialized and not silent and old_polarity!=new_polarity and is_inside_tree() and actor and actor.is_inside_tree():
		_play_polarity_shift_juice(new_polarity)

func _play_polarity_shift_juice(pole:int)->void:
	var scene:Node=get_tree().current_scene if get_tree().current_scene else actor.get_parent()
	if not scene:return
	var fx:=Node3D.new()
	scene.add_child(fx)
	var origin:Vector3=actor.global_position+Vector3(0,0.85,0.12)
	fx.global_position=origin
	var cam:=get_viewport().get_camera_3d()
	if cam:fx.global_basis=cam.global_basis
	active_fx.append(fx)
	var tint:Color
	var core_tint:Color
	match pole:
		1:
			tint=Color("ff3b4b")
			core_tint=Color("ffd2a8")
		2:
			tint=Color("1fa2ff")
			core_tint=Color("bfe9ff")
		_:
			tint=Color("10d660")
			core_tint=Color("a3f7bf")
	var light:=OmniLight3D.new()
	light.light_color=tint.lerp(core_tint,0.35)
	light.light_energy=0.9
	light.omni_range=2.6
	light.shadow_enabled=false
	fx.add_child(light)
	var burst_mesh:=MeshInstance3D.new()
	var qmesh:=QuadMesh.new()
	qmesh.size=Vector2(2.6,2.6)
	burst_mesh.mesh=qmesh
	var burst_mat:=ShaderMaterial.new()
	burst_mat.shader=preload("res://shaders/miko8_polarity_burst.gdshader")
	burst_mat.set_shader_parameter("color",tint)
	burst_mat.set_shader_parameter("core_color",core_tint)
	burst_mat.set_shader_parameter("ring_radius",0.06)
	burst_mat.set_shader_parameter("ring_thickness",0.055)
	burst_mat.set_shader_parameter("core_glow_radius",0.22)
	burst_mat.set_shader_parameter("master_opacity",0.38)
	burst_mat.render_priority=12
	burst_mesh.material_override=burst_mat
	burst_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(burst_mesh)
	var sparks:Array[MeshInstance3D]=[]
	var vels:Array[Vector3]=[]
	var rng:=RandomNumberGenerator.new()
	rng.randomize()
	for i in range(10):
		var spark:=MeshInstance3D.new()
		var smesh:=QuadMesh.new()
		var psize:float=rng.randf_range(0.04,0.08)
		smesh.size=Vector2(psize,psize)
		spark.mesh=smesh
		var smat:=ShaderMaterial.new()
		smat.shader=preload("res://shaders/miko8_plasma_mote.gdshader")
		smat.set_shader_parameter("tint",tint)
		smat.set_shader_parameter("core_tint",core_tint)
		smat.set_shader_parameter("master_opacity",0.40)
		smat.render_priority=14
		spark.material_override=smat
		spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.rotation.z=rng.randf_range(0,TAU)
		fx.add_child(spark)
		sparks.append(spark)
		var angle:=rng.randf_range(0,TAU)
		var speed:=rng.randf_range(0.8,2.0)
		var v:=Vector3(cos(angle)*speed,sin(angle)*speed*0.75+rng.randf_range(0.1,0.4),rng.randf_range(-0.03,0.03))
		vels.append(v)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(light,"light_energy",0.0,0.22).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v:float):burst_mat.set_shader_parameter("ring_radius",v),0.06,0.86,0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_method(func(v:float):burst_mat.set_shader_parameter("ring_thickness",v),0.055,0.080,0.30)
	tween.tween_method(func(v:float):burst_mat.set_shader_parameter("core_glow_radius",v),0.22,0.0,0.20).set_ease(Tween.EASE_IN)
	tween.tween_method(func(v:float):burst_mat.set_shader_parameter("master_opacity",v),0.38,0.0,0.30).set_ease(Tween.EASE_IN)
	tween.tween_method(func(c:Color):burst_mat.set_shader_parameter("color",c),tint,Color(tint.r,tint.g,tint.b,0.0),0.30).set_ease(Tween.EASE_IN)
	tween.tween_method(func(c:Color):burst_mat.set_shader_parameter("core_color",c),core_tint,Color(core_tint.r,core_tint.g,core_tint.b,0.0),0.22)
	for i in range(sparks.size()):
		var sp:=sparks[i]
		var v:=vels[i]
		var dur:=rng.randf_range(0.24,0.34)
		var dest:=v*dur
		tween.tween_property(sp,"position",dest,dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sp,"scale",Vector3.ZERO,dur).set_ease(Tween.EASE_IN)
		tween.tween_property(sp,"rotation:z",sp.rotation.z+rng.randf_range(-0.8,0.8),dur)
	for fb in get_tree().get_nodes_in_group("miko8_impact_feedback"):
		if fb.has_method("crate_impact_feedback"):
			fb.crate_impact_feedback()
	get_tree().create_timer(0.36).timeout.connect(fx.queue_free)

func toggle(pole:int)->void:
	set_polarity(0 if actor.suit_polarity==pole else pole)

func _unhandled_input(event:InputEvent)->void:
	if not actor.ready_for_input or not actor.is_physics_processing():return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index==JOY_BUTTON_Y:toggle(1)
		elif event.button_index==JOY_BUTTON_X:toggle(2)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_C:
		set_polarity((actor.suit_polarity+1)%3)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_1:set_polarity(1)
		elif event.physical_keycode==KEY_2:set_polarity(2)
		elif event.physical_keycode==KEY_0:set_polarity(0)
