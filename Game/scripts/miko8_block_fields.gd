extends Node2D
var camera:Camera3D
var clock:=0.
var link_count:=0
func _process(delta:float)->void:clock+=delta;queue_redraw()
func project(p:Vector3)->Vector2:return camera.unproject_position(p)
func _draw()->void:
	if not is_instance_valid(camera):return
	link_count=0
	var blocks:Array=[]
	for target in get_tree().get_nodes_in_group("miko8_charge_targets"):
		var block:bool=target is RigidBody3D or target.is_in_group("miko8_fixed_magnets")
		if block and target.is_locked_on and not camera.is_position_behind(target.global_position):_reticle(target)
		if block and target.polarity!=0 and not camera.is_position_behind(target.global_position):blocks.append(target)
	for block in blocks:
		var center:Vector2=project(block.global_position)
		var radius:float=center.distance_to(project(block.global_position+Vector3.UP*block.FIELD_RANGE))
		var fade:float=clampf(block.charge_remaining/3.,0.,1.)*(.35 if block.breakaway_remaining>0. else 1.)
		var tint:=Color("ff434e") if block.polarity==1 else Color("389cff")
		draw_circle(center,radius,Color(tint,.018*fade))
		for i in range(48):draw_arc(center,radius,i*TAU/48.,(i+.58)*TAU/48.,3,Color(tint,(.18+.02*sin(clock*2.2))*fade),1.2,true)
		for i in range(4):
			var angle:float=i*TAU/4.+clock*.85*(1. if block.polarity==1 else -1.)
			var radial:=Vector2(cos(angle),sin(angle));var tangent:=radial.orthogonal()
			var p:Vector2=center+radial*radius
			draw_polyline(PackedVector2Array([p-tangent*4.+radial*3.,p+tangent*6.,p-tangent*4.-radial*3.]),Color(tint,.3*fade),1.3,true)
		var ripple:float=fmod(clock,2.4)/2.4
		draw_arc(center,radius*ripple,0,TAU,64,Color(tint,.12*(1.-ripple)*fade),1.,true)
		for other in blocks:
			if other.get_instance_id()<=block.get_instance_id() or block.breakaway_remaining>0. or other.breakaway_remaining>0.:continue
			if not preload("res://scripts/miko8_block_connections.gd").connected(block,other):continue
			var distance:float=block.global_position.distance_to(other.global_position)
			if distance>block.INTERACTION_RANGE:continue
			link_count+=1
			var end:Vector2=project(other.global_position);var normal:Vector2=(end-center).normalized().orthogonal()
			if block.polarity!=other.polarity:
				for bow:float in [-1.,0.,1.]:
					var points:=PackedVector2Array()
					for i in range(25):
						var t:float=i/24.;points.append(center.lerp(end,t)+normal*sin(t*PI)*bow*(20.+3.*sin(clock*3.5)))
					draw_polyline(points,Color(tint,.38*fade),1.4,true)
					var t:float=fmod(clock*.6+bow*.27+1.,1.)
					draw_circle(center.lerp(end,t)+normal*sin(t*PI)*bow*20.,2.5,Color(tint,.75*fade))
			else:
				var middle:Vector2=(center+end)*.5;var axis:Vector2=(end-center).normalized()
				for sign_value:float in [-1.,1.]:
					var p:Vector2=middle+axis*sign_value*(6.+sin(clock*8.)*2.)
					draw_polyline(PackedVector2Array([p-normal*20.+axis*sign_value*7.,p,p+normal*20.+axis*sign_value*7.]),Color(tint,.5*fade),1.8,true)
func _reticle(target:Node3D)->void:
	var center:Vector2=project(target.global_position)
	var width:float=target.get_meta("magnetic_half_width",.48);var height:float=target.get_meta("magnetic_half_height",.46)
	var half:=Vector2(center.distance_to(project(target.global_position+Vector3(width,0,0))),center.distance_to(project(target.global_position+Vector3(0,height,0))))
	var tint:Color=target.lock_color;tint.a=.75+.25*sin(clock*9.)
	for x:float in [-1.,1.]:
		for y:float in [-1.,1.]:
			var corner:Vector2=center+half*Vector2(x,y)
			var points:=PackedVector2Array([corner-Vector2(x*9.,0),corner,corner-Vector2(0,y*9.)])
			draw_polyline(points,Color(tint,.25),4.,true);draw_polyline(points,tint,1.5,true)
