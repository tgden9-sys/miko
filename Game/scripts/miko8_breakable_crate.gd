extends StaticBody3D
var broken:=false
var settle_stack:=false
var rest_position:=Vector3.ZERO
var fall_speed:=0.
func _ready()->void:
	add_to_group("miko8_breakable_crates");rest_position=global_position

func _physics_process(delta:float)->void:
	if not settle_stack or broken:return
	# Authored wooden stacks must collapse when the crate underneath breaks.
	var distance:=.08+fall_speed*delta+9.8*delta*delta
	var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.025,global_position+Vector3.DOWN*distance,1,[get_rid()])
	var support:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not support.is_empty():
		global_position.y=support.position.y;fall_speed=0.
	else:
		fall_speed+=9.8*delta;global_position.y=maxf(0.,global_position.y-fall_speed*delta)
func receive_plasma(_power:int,point:Vector3,direction:Vector3)->void:
	_break_crate(point,direction,Color("d5a1ff"),1.0)

func receive_blaster(_power:int,point:Vector3,direction:Vector3)->void:
	_break_crate(point,direction,Color("8aff9b"),.65)

func _break_crate(point:Vector3,direction:Vector3,tint:Color,strength:float)->void:
	if broken:return
	broken=true
	# Deferred layer changes are safe inside a projectile's physics query.
	set_deferred("collision_layer",0)
	for visual:Node3D in get_children():
		if visual is CollisionShape3D:visual.set_deferred("disabled",true)
		elif visual is Node3D:
			visual.hide();visual.remove_from_group("miko8_budget_visual")
	var debris:=preload("res://scripts/miko8_crate_break_effect.gd").new()
	debris.push_direction=direction;debris.hit_point=point-global_position
	debris.energy_tint=tint
	debris.impact_strength=strength
	get_parent().add_child(debris);debris.global_position=global_position
func reset_crate()->void:
	broken=false;collision_layer=1
	global_position=rest_position;fall_speed=0.
	for visual:Node3D in get_children():
		if visual is CollisionShape3D:visual.set_deferred("disabled",false)
		else:visual.show()
	var model:=get_child(0) as Node3D
	model.add_to_group("miko8_budget_visual")
