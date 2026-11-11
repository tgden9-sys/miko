extends Node
## Render bounds are camera-relative; interactive activity has a wider safety margin.
var camera:Camera3D
var elapsed:=0.0
var hidden_visuals:=0
var inactive_actors:=0
func _ready()->void:refresh()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed>=0.20:
		elapsed=0
		refresh()
func refresh()->void:
	if not is_instance_valid(camera) or camera.get_viewport().get_camera_3d()!=camera:return
	var viewport:=camera.get_viewport().get_visible_rect().size
	var half_width:float=camera.size*viewport.x/maxf(viewport.y,1)*0.5
	var centre:float=camera.get_meta("walkway_focus_x",camera.global_position.x)
	if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:
		half_width/=maxf(.5,absf(camera.global_basis.x.x))
	hidden_visuals=0
	for visual:Node3D in get_tree().get_nodes_in_group("miko8_budget_visual"):
		if visual.get_viewport()!=camera.get_viewport():continue
		var half:float=visual.get_meta("budget_half_width",1.0)
		var margin:=8.0 if visual is GeometryInstance3D and visual.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 2.0
		var projected_half:=half_width
		if camera.projection==Camera3D.PROJECTION_PERSPECTIVE:
			var view_depth:=maxf(1.0,-(camera.global_transform.affine_inverse()*visual.global_position).z)
			projected_half=tan(deg_to_rad(camera.fov)*.5)*view_depth*viewport.x/maxf(viewport.y,1.0)
		var active:bool=absf(visual.global_position.x-centre)<=projected_half+margin+half
		visual.visible=active
		if not active:hidden_visuals+=1
	inactive_actors=0
	for actor:Node3D in get_tree().get_nodes_in_group("miko8_budget_actor"):
		if actor.get_viewport()!=camera.get_viewport():continue
		if actor.is_in_group("miko8_magnetic_suit"):continue
		var active:bool=bool(actor.get_meta("budget_always_simulate",false)) or absf(actor.global_position.x-centre)<=half_width+float(actor.get_meta("budget_activity_margin",5.0))+float(actor.get_meta("budget_half_width",1.0))
		if actor.has_method("set_camera_active"):
			actor.set_camera_active(active)
		else:
			# Future non-player actors opt into this group; their animation/AI inherits it.
			if not actor.has_meta("budget_process_mode"):actor.set_meta("budget_process_mode",actor.process_mode)
			actor.process_mode=int(actor.get_meta("budget_process_mode")) if active else Node.PROCESS_MODE_DISABLED
			actor.visible=active
		if not active:inactive_actors+=1
