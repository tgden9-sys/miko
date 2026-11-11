extends Area3D
## A nonblocking target uses the same hold/release controls as charge crates.
var polarity:=0
var charge_remaining:=0.0
var is_locked_on:=false
var paints:Array[ShaderMaterial]=[]
const TARGET_SIZE:=Vector3(2.25,1.65,4.0)
func _ready()->void:
	name="ChargeTarget"
	collision_layer=4;collision_mask=0;monitoring=false
	add_to_group("miko8_charge_targets")
	add_to_group("miko8_launchers")
	var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new()
	shape.size=TARGET_SIZE;collider.shape=shape;add_child(collider)
	for mesh:MeshInstance3D in get_parent().get_child(0).find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source:=mesh.get_active_material(surface) as StandardMaterial3D
			if not source:continue
			var paint:=ShaderMaterial.new();paint.shader=preload("res://shaders/miko8_loader.gdshader")
			paint.set_shader_parameter("base_texture",source.albedo_texture)
			paint.set_shader_parameter("base_color",source.albedo_color)
			if source.metallic_texture:paint.set_shader_parameter("metal_rough_texture",source.metallic_texture)
			if source.normal_texture:paint.set_shader_parameter("normal_texture",source.normal_texture)
			paint.set_shader_parameter("metallic_factor",source.metallic)
			paint.set_shader_parameter("roughness_factor",source.roughness)
			paint.set_shader_parameter("normal_scale",source.normal_scale)
			mesh.set_surface_override_material(surface,paint);paints.append(paint)

func set_locked_on(active:bool,_point:Vector3,color:Color)->void:
	is_locked_on=active
	for paint in paints:
		paint.set_shader_parameter("targeting",1.0 if active else 0.0)
		paint.set_shader_parameter("target_color",color)
	if active and polarity!=0:charge_remaining=15.0

func lock_in_color(color:Color)->void:
	polarity=1 if color.r>color.b else 2;charge_remaining=15.0
	set_locked_on(false,Vector3.ZERO,color);_update_color()

func neutralize()->void:
	polarity=0;charge_remaining=0;_update_color()

func _update_color()->void:
	for paint in paints:paint.set_shader_parameter("polarity",polarity)

func _physics_process(delta:float)->void:
	if polarity==0:return
	var actor=get_tree().get_first_node_in_group("miko8_magnetic_suit")
	if actor and actor.launcher_motion and actor.launcher_motion.launcher==self:charge_remaining=maxf(charge_remaining,15.0)
	charge_remaining-=delta
	if charge_remaining<=0:neutralize()

func launch_center()->Vector3:return get_parent().to_global(Vector3(0,.15,0))
func contains_muzzle(point:Vector3)->bool:
	var offset:=to_local(point).abs()
	var half:=TARGET_SIZE*.5
	return offset.x<half.x and offset.y<half.y and offset.z<half.z

func muzzle_target_distance(body_point:Vector3,muzzle:Vector3,direction:Vector3)->float:
	# A hand can reach into the target before Miko steps onto the launcher.
	# In that case the shot still hits it. From inside, the lane remains open.
	if not contains_muzzle(muzzle) or contains_muzzle(body_point):return 0.
	return maxf(0.,(global_position-muzzle).dot(direction))
func hand_target(side:String)->Vector3:
	# The inner shoulders of the two pillar caps are reachable without scaling MIKO.
	return get_parent().to_global(Vector3(0,1.89,-1.26 if side=="L" else 1.26))

func trigger_launch()->void:
	var effect:=Node3D.new()
	var scene:Node=get_tree().current_scene if get_tree().current_scene else get_parent().get_parent()
	scene.add_child(effect)
	effect.global_position=launch_center()+Vector3(0,.1,0)
	var tint:=Color("ff434e") if polarity==1 else Color("389cff")
	for i in range(2):
		var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.46;mesh.outer_radius=.49;mesh.rings=32;mesh.ring_segments=6;ring.mesh=mesh
		var paint:=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;paint.albedo_color=tint
		ring.material_override=paint;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;effect.add_child(ring)
		var tween:=create_tween().set_parallel(true);tween.tween_property(ring,"scale",Vector3(2.3,1.,2.3),.38).set_delay(i*.055);tween.tween_property(ring,"position:y",.8+i*.2,.38).set_delay(i*.055);tween.tween_property(paint,"albedo_color:a",0.,.38).set_delay(i*.055)
	get_tree().create_timer(.55).timeout.connect(effect.queue_free)
