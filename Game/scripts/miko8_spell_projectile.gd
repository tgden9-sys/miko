extends Node3D
var velocity:=Vector3.ZERO
var caster:CharacterBody3D
var power:=1
var mode:="Plasma"
var age:=0.0
var sweep:ShapeCast3D
var trail:Array[MeshInstance3D]=[]
var history:Array[Vector3]=[]
var orb:Node3D
var trail_material:StandardMaterial3D
var wake:MeshInstance3D
var wake_material:ShaderMaterial
var visual_mode := ""
static var green_wake_shader:Shader

func _ready()->void:
	top_level = true
	if mode=="Plasma":add_to_group("miko8_plasma_bolts")
	add_to_group("miko8_energy_bolts")
	sweep=ShapeCast3D.new()
	var volume:=SphereShape3D.new()
	volume.radius=0.10 if mode=="Plasma" else .065
	sweep.shape=volume
	sweep.collision_mask=5
	sweep.collide_with_areas=true
	sweep.margin=0.001
	sweep.enabled=false
	add_child(sweep)
	if is_instance_valid(caster):sweep.add_exception(caster)
	orb=preload("res://scripts/miko8_energy_orb.gd").new()
	orb.mode=mode;orb.radius=.18 if mode=="Plasma" else .095;add_child(orb)
	wake=MeshInstance3D.new()
	var wake_mesh:=QuadMesh.new()
	wake_mesh.size=Vector2(1.3,.5)
	wake.mesh=wake_mesh
	wake_material=ShaderMaterial.new()
	wake_material.shader=preload("res://shaders/miko8_bolt_wake.gdshader")
	if not green_wake_shader:
		green_wake_shader=Shader.new()
		green_wake_shader.code=wake_material.shader.code.replace("depth_draw_never;", "depth_draw_never, depth_test_disabled;")
	wake.material_override=wake_material
	wake.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wake.visible=false
	add_child(wake)
	trail_material=StandardMaterial3D.new()
	trail_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.albedo_color=preload("res://scripts/miko8_energy_orb.gd").color_for(mode).lerp(Color.WHITE,.25)
	for index in range(8):
		var point:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.045;sphere.height=.09
		sphere.radial_segments=8;sphere.rings=4;point.mesh=sphere;point.material_override=trail_material
		point.top_level=true;point.visible=false;point.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(point);trail.append(point)

func configure_bolt(new_caster: CharacterBody3D, origin: Vector3, new_vel: Vector3, new_mode: String, new_power: int) -> void:
	caster = new_caster
	velocity = new_vel
	mode = new_mode
	power = new_power
	age = 0.0
	history.clear()
	global_position = origin
	if new_mode == "Plasma":
		if not is_in_group("miko8_plasma_bolts"): add_to_group("miko8_plasma_bolts")
	else:
		if is_in_group("miko8_plasma_bolts"): remove_from_group("miko8_plasma_bolts")
	if is_instance_valid(sweep):
		sweep.collision_mask = 1 if mode == "Warden" else 5
		sweep.clear_exceptions()
		if is_instance_valid(caster): sweep.add_exception(caster)
		# Aim rays can leave an Area they start inside. Match that behaviour
		# for the swept bolt so the launcher doesn't absorb shots at the palm.
		for launcher in get_tree().get_nodes_in_group("miko8_launchers"):
			if not launcher is Area3D or not launcher.has_method("muzzle_target_distance") or not launcher.contains_muzzle(origin):continue
			var body_point:=caster.global_position+Vector3.UP*.65 if is_instance_valid(caster) else origin
			if launcher.muzzle_target_distance(body_point,origin,velocity.normalized())<=0.:
				sweep.add_exception(launcher)
		var vol := sweep.shape as SphereShape3D
		if vol: vol.radius = 0.10 if mode == "Plasma" else 0.065
	# Pooled bolts often fire repeatedly in the same mode. Only restyle on
	# a mode change, and leave the hidden orb alone for wake-only bolts.
	if visual_mode != mode:
		visual_mode = mode
		var tint := preload("res://scripts/miko8_energy_orb.gd").color_for(mode)
		orb.visible = mode not in ["Green", "Warden"]
		if orb.visible:
			orb.set_mode(mode)
			orb.scale = Vector3.ONE * ((.18 if mode == "Plasma" else .095) / orb.built_radius)
		wake.visible = mode in ["Plasma", "Green", "Warden"]
		wake_material.shader = green_wake_shader if mode == "Green" else preload("res://shaders/miko8_bolt_wake.gdshader")
		wake_material.render_priority = 28 if mode == "Green" else 0
		wake_material.set_shader_parameter("quick", mode in ["Green", "Warden"])
		wake_material.set_shader_parameter("tint", tint)
		if mode in ["Red", "Blue"]:
			trail_material.albedo_color = tint.lerp(Color.WHITE, .25)
	visible = true
	wake_material.set_shader_parameter("travel_age",0.)
	set_physics_process(true)

func _physics_process(delta:float)->void:
	age+=delta
	if age>2.0:
		if has_meta("pool_ref") and is_instance_valid(get_meta("pool_ref")):
			get_meta("pool_ref").recycle_bolt(self)
		else:
			queue_free()
		return
	var end:=global_position+velocity*delta
	sweep.target_position=velocity*delta
	sweep.force_shapecast_update()
	if sweep.is_colliding():
		var collider=sweep.get_collider(0)
		if is_instance_valid(collider):
			if mode == "Warden":
				if collider.has_method("receive_warden_bolt"):
					if not collider.abilities.combat.block_bolt(velocity): collider.receive_warden_bolt()
			elif collider.has_method("receive_combat_bolt"):
				collider.receive_combat_bolt()
			elif mode in ["Red","Blue"] and collider.has_method("lock_in_color"):
				var charge_color:Color=preload("res://scripts/miko8_energy_orb.gd").color_for(mode)
				if collider.has_method("charge_at"):
					collider.charge_at(charge_color,sweep.get_collision_point(0))
				else:
					collider.lock_in_color(charge_color)
			elif mode=="Green":
				if collider.has_method("receive_blaster"):
					collider.receive_blaster(power,sweep.get_collision_point(0),velocity.normalized())
				elif collider.has_method("receive_spell"):
					collider.receive_spell(power)
			elif mode=="Plasma":
				if collider.has_method("receive_plasma"):collider.receive_plasma(power,sweep.get_collision_point(0),velocity.normalized())
				elif collider.has_method("neutralize"):collider.neutralize()
				elif collider.has_method("receive_spell"):collider.receive_spell(power)
		var hit_pos: Vector3 = sweep.get_collision_point(0)
		var hit_tint: Color = preload("res://scripts/miko8_energy_orb.gd").color_for(mode)
		if has_meta("pool_ref") and is_instance_valid(get_meta("pool_ref")):
			get_meta("pool_ref").spawn_impact(hit_pos, hit_tint)
			get_meta("pool_ref").recycle_bolt(self)
		else:
			var burst:=preload("res://scripts/miko8_energy_impact.gd").new()
			burst.tint=hit_tint
			get_parent().add_child(burst);burst.global_position=hit_pos
			queue_free()
		return
	global_position=end
	if wake.visible:
		var camera:=get_viewport().get_camera_3d()
		if camera:
			var along:=velocity.normalized()
			var across:=camera.global_basis.z.cross(along).normalized()
			var size:=.66 if mode in ["Green", "Warden"] else 1.
			wake.global_basis=Basis(along,across,along.cross(across)).scaled(Vector3.ONE*size)
			wake.global_position=global_position-along*.53*size
		wake_material.set_shader_parameter("travel_age",age)
	if mode in ["Red", "Blue"]:
		history.push_front(global_position)
		if history.size() > trail.size(): history.pop_back()
		for index in range(history.size()):
			trail[index].visible = true
			trail[index].global_position = history[index]
			trail[index].scale = Vector3.ONE * (1. - float(index) / trail.size())
