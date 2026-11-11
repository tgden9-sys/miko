extends RigidBody3D
@export var crate_size:=Vector3(.8,.8,.8)
## World height of the elevated deck. Leave at zero for crates in the ground lane.
@export var elevated_lane_floor_y:=0.0
var polarity:=0
var charge_remaining:=0.0
var is_locked_on:=false
var lock_color:=Color.WHITE
var material:StandardMaterial3D
var marker:MeshInstance3D
var display_root:Node3D
var base_scale:=Vector3.ONE
var charge_materials:Array[ShaderMaterial]=[]
var charge_meshes:Array[MeshInstance3D]=[]
var charge_tween:Tween
var visual_energy:=Vector2.ZERO
var transition_from:=Vector2.ZERO
var transition_to:=Vector2.ZERO
var camera_active:=true
var budget_suspended:=false
var home_position:=Vector3.ZERO
const FIELD_RANGE:=200.*1.9/96.
const INTERACTION_RANGE:=FIELD_RANGE*2.
var breakaway_remaining:=0.0
var repulsion_count:=0
@export var suit_movable:=true
@export var block_movable:=true
@export var charge_squash:=true
var _suit_actor: Node = null
var _returning_to_ground_lane:=false
var _lane_collision:KinematicCollision3D

func _ready()->void:
	home_position=position
	add_to_group("miko8_charge_targets")
	add_to_group("miko8_budget_actor")
	set_meta("budget_half_width",0.6)
	mass=2.0
	continuous_cd=true
	collision_layer=5
	collision_mask=5
	axis_lock_linear_z=true
	lock_rotation=true
	linear_damp=2.0
	var physics:=PhysicsMaterial.new()
	physics.friction=0.25
	physics_material_override=physics
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=crate_size
	collision.shape=shape
	add_child(collision)
	material=StandardMaterial3D.new()
	material.roughness=0.72
	if ResourceLoader.exists("res://models/props/metal_crate.glb"):
		display_root=load("res://models/props/metal_crate.glb").instantiate()
		add_child(display_root)
		for mesh:MeshInstance3D in display_root.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var original:=mesh.get_active_material(surface) as StandardMaterial3D
				if not original:continue
				var paint:=ShaderMaterial.new()
				paint.shader=preload("res://shaders/miko8_crate.gdshader")
				paint.set_shader_parameter("base_texture",original.albedo_texture)
				paint.set_shader_parameter("base_color",original.albedo_color)
				if original.metallic_texture:paint.set_shader_parameter("metal_rough_texture",original.metallic_texture)
				paint.set_shader_parameter("metallic_factor",original.metallic)
				paint.set_shader_parameter("roughness_factor",maxf(0.75,original.roughness))
				mesh.set_surface_override_material(surface,paint)
				charge_materials.append(paint)
				charge_meshes.append(mesh)
				var bounds:=mesh.mesh.get_aabb()
				paint.set_shader_parameter("bounds_center",bounds.get_center())
				paint.set_shader_parameter("bounds_half",bounds.size*.5)
	else:
		var display:=MeshInstance3D.new()
		var box:=BoxMesh.new()
		box.size=shape.size;display.mesh=box;display.material_override=material
		add_child(display);display_root=display
	if display_root:display_root.scale*=crate_size/Vector3(.8,.8,.8)
	base_scale=display_root.scale if display_root else Vector3.ONE
	marker=MeshInstance3D.new()
	var outline:=BoxMesh.new()
	outline.size=crate_size+Vector3.ONE*.06
	marker.mesh=outline
	var highlight:=StandardMaterial3D.new()
	highlight.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override=highlight
	add_child(marker)
	marker.visible=false
	_update_color()

func _get_suit_actor() -> Node:
	if not is_instance_valid(_suit_actor):
		_suit_actor = get_tree().get_first_node_in_group("miko8_magnetic_suit")
	return _suit_actor

func reset_charge_body()->void:
	_returning_to_ground_lane=false
	neutralize();position=home_position;linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO;sleeping=false
	_suit_actor=null
	if charge_tween:charge_tween.kill()
	transition_from=Vector2.ZERO
	transition_to=Vector2.ZERO
	_render_charge(1.0)

func _render_charge(progress:float)->void:
	visual_energy=transition_from.lerp(transition_to,progress)
	for paint in charge_materials:
		paint.set_shader_parameter("energy_from",transition_from)
		paint.set_shader_parameter("energy_to",transition_to)
		paint.set_shader_parameter("charge_progress",progress)

func _animate_charge()->void:
	if charge_tween:charge_tween.kill()
	transition_from=visual_energy
	transition_to=Vector2(1,0) if polarity==1 else Vector2(0,1) if polarity==2 else Vector2.ZERO
	_render_charge(0.0)
	charge_tween=create_tween()
	charge_tween.tween_method(_render_charge,0.0,1.0,.56 if polarity!=0 else .38)

func charge_at(color:Color,world_point:Vector3)->void:
	for index in range(charge_materials.size()):
		if index<charge_meshes.size() and is_instance_valid(charge_meshes[index]):
			charge_materials[index].set_shader_parameter("charge_origin",charge_meshes[index].to_local(world_point))
	lock_in_color(color)

func _update_color()->void:
	material.albedo_color=Color("b86b72") if polarity==1 else Color("668fb8") if polarity==2 else Color("8f7961")
	material.emission_enabled=polarity!=0
	material.emission=material.albedo_color
	material.emission_energy_multiplier=0.12
	for paint in charge_materials:paint.set_shader_parameter("polarity",polarity)
	if polarity!=0 and budget_suspended:
		set_physics_process(true)
		budget_suspended=false

func set_camera_active(active:bool)->void:
	camera_active=active
	if display_root:display_root.visible=active
	if marker:marker.visible=active and is_locked_on
	if active and budget_suspended:
		set_physics_process(true)
		budget_suspended=false
	elif not active and polarity==0 and sleeping:
		set_physics_process(false)
		budget_suspended=true

func set_locked_on(active:bool,_point:Vector3,color:Color)->void:
	is_locked_on=active
	lock_color=color
	marker.visible=active
	marker.material_override.albedo_color=Color(color.r,color.g,color.b,0.30 if active else 0.0)
	if active:
		marker.scale=Vector3.ONE*1.12
		if not freeze: sleeping=false
	if active and polarity!=0:charge_remaining=15.0

func lock_in_color(color:Color)->void:
	polarity=1 if color.r>color.b else 2
	charge_remaining=15.0
	set_locked_on(false,Vector3.ZERO,color)
	if not freeze: sleeping=false
	_update_color()
	_animate_charge()
	if display_root and not freeze and charge_squash:display_root.scale=base_scale*Vector3(1.10,0.90,1.10)
	var spark=preload("res://scripts/miko8_crate_charge_spark.gd").new()
	spark.tint=color
	add_child(spark);spark.position=Vector3(0,0.4,0)

func neutralize()->void:
	breakaway_remaining=0.
	polarity=0
	charge_remaining=0.0
	set_locked_on(false,Vector3.ZERO,Color.WHITE)
	constant_force=Vector3.ZERO;constant_torque=Vector3.ZERO
	gravity_scale=1.
	if not freeze:sleeping=false
	if display_root:display_root.scale=base_scale
	_update_color()
	_animate_charge()

func _integrate_forces(state:PhysicsDirectBodyState3D)->void:
	if elevated_lane_floor_y<=0.0:return
	var pose:=state.transform
	# Clear the deck with the entire crate before moving toward the ground lane.
	if pose.origin.y+crate_size.y*.5<elevated_lane_floor_y-.12:
		_returning_to_ground_lane=true
	if not _returning_to_ground_lane or is_zero_approx(pose.origin.z):return
	var travel:=Vector3(0,0,move_toward(pose.origin.z,0.0,state.step*2.5)-pose.origin.z)
	# Sweep the solid body so the lane change cannot cut through the platform or another crate.
	if not _lane_collision:_lane_collision=KinematicCollision3D.new()
	if test_move(pose,travel,_lane_collision,.001):
		travel.z=clampf(_lane_collision.get_travel().z,minf(travel.z,0.),maxf(travel.z,0.))
	pose.origin.z+=travel.z
	state.transform=pose

func _physics_process(delta:float)->void:
	breakaway_remaining=maxf(0.,breakaway_remaining-delta)
	if display_root and display_root.scale!=base_scale:
		display_root.scale=display_root.scale.move_toward(base_scale,delta*3.0)
	if marker and marker.visible and marker.scale!=Vector3.ONE:
		marker.scale=marker.scale.move_toward(Vector3.ONE,delta*2.5)
	
	# Strict 2.5D planar and floor boundaries
	if not _returning_to_ground_lane and absf(position.z - home_position.z) > 0.001:
		position.z = home_position.z
	if absf(linear_velocity.z) > 0.001: linear_velocity.z = 0.0
	if position.y < 0.40:
		position.y = 0.40
		if linear_velocity.y < 0.0: linear_velocity.y = 0.0
	
	if polarity==0:
		# Let the solver decide when the body is supported and can sleep. A
		# released ceiling load also has zero velocity on its first falling frame.
		return

	charge_remaining-=delta
	if charge_remaining<=0:neutralize();return
	if not camera_active:return
	var actor = _get_suit_actor()
	if suit_movable and actor and actor.suit_polarity!=0:
		var offset:Vector3=actor.global_position+Vector3(0,.4,0)-global_position;offset.z=0.
		if actor.suit_polarity!=polarity and offset.length()<155.*1.9/96.:
			var desired:float=actor.velocity.x+signf(offset.x)*clampf((offset.length()-88.*1.9/96.)*5.,-5.15,5.15)
			apply_central_force(Vector3(clampf((desired-linear_velocity.x)*mass*12.,-70.,70.),0,0))
		else:_magnetic_force(actor.global_position+Vector3(0,0.4,0),actor.suit_polarity,110.0)
	for other in get_tree().get_nodes_in_group("miko8_charge_targets"):
		if not preload("res://scripts/miko8_block_connections.gd").connected(self,other):continue
		if other.is_in_group("miko8_fixed_magnets") and other.get("mount_mode")==1:
			other.apply_lift(self);continue
		if not block_movable and other is RigidBody3D:continue
		var gap:Vector3=other.global_position-global_position;gap.z=0.
		if other is RigidBody3D and other.has_method("_repulsion_kick"):
			if other.polarity==polarity and gap.length()<2.18 and breakaway_remaining<=0. and other.breakaway_remaining<=0.:
				_repulsion_kick(other,gap)
			if other.polarity!=polarity and (breakaway_remaining>0. or other.breakaway_remaining>0.):continue
		var target_position:Vector3=other.global_position
		# Wall pads draw blocks along the floor, never lift them toward their centre.
		if other.is_in_group("miko8_fixed_magnets"):target_position.y=global_position.y
		_magnetic_force(target_position,other.polarity,70.0)
	# Cap lateral travel without scaling away gravity's falling velocity.
	linear_velocity.x=clampf(linear_velocity.x,-11.5,11.5)

func _repulsion_kick(other:RigidBody3D,gap:Vector3)->void:
	if not block_movable or not other.block_movable:return
	if freeze and other.freeze:return
	breakaway_remaining=2.;other.breakaway_remaining=2.;repulsion_count+=1;other.repulsion_count+=1
	if absf(gap.x)<1.08 and absf(gap.y)>.4:
		var top:RigidBody3D=other if gap.y>0. else self
		var bottom:RigidBody3D=self if gap.y>0. else other
		if not top.freeze:
			top.linear_velocity=Vector3(9.1,13.45,0)
			top.sleeping=false
		if not bottom.freeze:
			bottom.linear_velocity=Vector3(-2.37,bottom.linear_velocity.y,0)
			bottom.sleeping=false
	else:
		var side:float=-signf(gap.x) if absf(gap.x)>.01 else -1.
		if not freeze:
			linear_velocity=Vector3(side*11.08,2.97,0)
			sleeping=false
		if not other.freeze:
			other.linear_velocity=Vector3(-side*11.08,2.97,0)
			other.sleeping=false
	for body in [self,other]:
		var spark=preload("res://scripts/miko8_crate_charge_spark.gd").new();spark.tint=Color("ff434e") if polarity==1 else Color("389cff");body.add_child(spark)

func _magnetic_force(target:Vector3,pole:int,power:float)->void:
	if polarity==0:return
	var offset:=target-global_position
	offset.z=0
	var distance:=offset.length()
	if distance<0.15 or distance>INTERACTION_RANGE:return
	var direction:=offset.normalized()*( -1.0 if pole==polarity else 1.0)
	# Continuous fields never cancel gravity. Repulsion's one-shot kick above
	# is allowed, but it receives no sustained vertical magnetic support.
	# Only a ceiling magnet's explicit apply_lift() path supplies vertical lift.
	direction.y=0.
	apply_central_force(direction*power*pow(1.0-distance/INTERACTION_RANGE,1.5))
