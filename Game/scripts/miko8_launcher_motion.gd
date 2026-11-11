extends Node
## Local hand-planted interaction only. Stationary objects exert no field on MIKO.
const ATTACH_TIME:=.55
const RELEASE_TIME:=.18
const BOOST_SPEED:=6.0*sqrt(2.80) # 40% higher launch apex (2.8x standard jump height)
var actor:CharacterBody3D
var enabled:=false
var launcher:Node3D
var phase:=""
var elapsed:=0.0
var cooldown:=0.0
var grip_weight:=0.0
var hand_targets:Dictionary={}
var launch_count:=0
var hold_spark_timer:=0.0
var _cached_launchers: Array[Node] = []

func reset()->void:
	launcher=null;phase="";elapsed=0.;cooldown=0.;grip_weight=0.;hand_targets.clear();hold_spark_timer=0.
	_cached_launchers.clear()

func _get_launchers() -> Array[Node]:
	if _cached_launchers.is_empty():
		_cached_launchers = get_tree().get_nodes_in_group("miko8_launchers")
	return _cached_launchers

func _free_state()->bool:
	var free_mask: int = (
		(1 << actor.State.LOCOMOTION) |
		(1 << actor.State.MOVE_START) |
		(1 << actor.State.GROUND_STOP) |
		(1 << actor.State.WALL_BLOCKED) |
		(1 << actor.State.SPRINT_ENTER) |
		(1 << actor.State.SPRINT_EXIT) |
		(1 << actor.State.BRAKE) |
		(1 << actor.State.AIR) |
		(1 << actor.State.LAND)
	)
	return ((1 << actor.state_id) & free_mask) != 0

func _detach(jump:=false)->void:
	launcher=null;phase="";cooldown=1.0
	actor._resume_locomotion(actor._axis())
	if jump:actor._begin_jump()

func _attach(value:Node3D)->void:
	launcher=value;phase="attach";elapsed=0.;hold_spark_timer=0.
	actor.abilities._clear_target();actor.abilities.lasers.hide_beams()
	actor.turn_queue.clear();actor.model.position=Vector3.ZERO
	actor.velocity=Vector3.ZERO;actor.jump_buffer=0.
	actor.visual.rotation.y=actor.facing*PI/2
	actor._state("LauncherAttach");actor._play("Idle",.18)
	# Left/right are anatomical. Walking left reverses which cap each hand uses.
	for side:String in ["L","R"]:
		var cap:String=side if actor.facing==1 else ("R" if side=="L" else "L")
		hand_targets[side]=launcher.hand_target(cap)
		hand_targets[side].x-=actor.facing*.06
	_play_approach_attract_juice()

func _launch()->void:
	launcher.trigger_launch()
	launch_count+=1;launcher=null;phase="";cooldown=1.25
	actor.jump_buffer=0.;actor.coyote=0.;actor.floor_snap_length=0.
	actor.launched=true;actor.landing_contact=false;actor.velocity=Vector3(0,BOOST_SPEED,0)
	actor._state("Air");actor._play("JumpAir",.12)
	actor.move_and_slide()

func tick(delta:float,axis:float)->bool:
	if not enabled:return false
	cooldown=maxf(0.,cooldown-delta)
	if phase!="" and not actor.state.begins_with("Launcher"):
		launcher=null;phase="";cooldown=.8
	if phase=="":
		grip_weight=move_toward(grip_weight,0.,delta*9.)
		if not _free_state() or actor.reactions.crouched:return false
		if cooldown>0. or not actor.is_on_floor() or actor.suit_polarity==0:return false
		for candidate:Node3D in _get_launchers():
			if candidate.polarity==0 or candidate.polarity==actor.suit_polarity:continue
			var center:Vector3=candidate.launch_center()
			if absf(actor.position.x-center.x)<.07 and absf(actor.position.y-center.y)<.16 and absf(actor.position.z-center.z)<.12:
				_attach(candidate);break
		if phase=="":return false
	if not is_instance_valid(launcher) or launcher.polarity==0 or actor.suit_polarity==0:
		_detach();return false
	if actor.jump_buffer>0.:
		_detach(true);return false
	if absf(axis)>.3 and elapsed>ATTACH_TIME+.15:
		_detach();return false
	elapsed+=delta
	actor.velocity=Vector3.ZERO
	actor.move_and_slide()
	grip_weight=smoothstep(0.,ATTACH_TIME,elapsed) if phase=="attach" else 1.0
	if phase=="attach" and elapsed>=ATTACH_TIME:
		phase="hold";actor._state("LauncherHold")
		_play_dock_clamp_juice()
	if phase=="hold":
		_tick_hold_sparks(delta)
	if phase=="hold" and actor.suit_polarity==launcher.polarity:
		phase="release";elapsed=0.;actor._state("LauncherRelease");actor._play("JumpStart",.08)
		_play_precharge_surge_juice()
	if phase=="release" and actor.suit_polarity!=launcher.polarity:
		phase="hold";actor._state("LauncherHold");actor._play("Idle",.12)
	actor.animation_player.advance(delta)
	if phase=="release" and elapsed>=RELEASE_TIME:_launch()
	return true

func _play_approach_attract_juice()->void:
	if not is_instance_valid(launcher) or not actor or not actor.is_inside_tree():return
	var scene:Node=get_tree().current_scene if get_tree().current_scene else actor.get_parent()
	if not scene:return
	var fx:=Node3D.new();scene.add_child(fx)
	var tint:Color=Color("ff434e") if launcher.polarity==1 else Color("389cff")
	var core_tint:Color=Color("ffb880") if launcher.polarity==1 else Color("a6e4ff")
	var tween:=create_tween().set_parallel(true)
	for side:String in ["L","R"]:
		if not hand_targets.has(side):continue
		var target:Vector3=hand_targets[side]
		var spark:=MeshInstance3D.new()
		var qmesh:=QuadMesh.new();qmesh.size=Vector2(0.10,0.10);spark.mesh=qmesh
		var smat:=ShaderMaterial.new();smat.shader=preload("res://shaders/miko8_plasma_mote.gdshader")
		smat.set_shader_parameter("tint",tint);smat.set_shader_parameter("core_tint",core_tint)
		smat.render_priority=12
		spark.material_override=smat
		spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(spark)
		spark.global_position=target+Vector3(0,0.06,0.05)
		tween.tween_property(spark,"scale",Vector3.ZERO,0.22).set_ease(Tween.EASE_IN)
	get_tree().create_timer(0.25).timeout.connect(fx.queue_free)

func _play_dock_clamp_juice()->void:
	if not is_instance_valid(launcher) or not actor or not actor.is_inside_tree():return
	var scene:Node=get_tree().current_scene if get_tree().current_scene else actor.get_parent()
	if not scene:return
	var fx:=Node3D.new();scene.add_child(fx)
	var tint:Color=Color("ff434e") if launcher.polarity==1 else Color("389cff")
	var core_tint:Color=Color("ffb880") if launcher.polarity==1 else Color("a6e4ff")
	var tween:=create_tween().set_parallel(true)
	var rng:=RandomNumberGenerator.new();rng.randomize()
	for side:String in ["L","R"]:
		if not hand_targets.has(side):continue
		var hand_pos:Vector3=hand_targets[side]
		var ring:=MeshInstance3D.new()
		var tmesh:=TorusMesh.new()
		tmesh.inner_radius=0.10;tmesh.outer_radius=0.14;tmesh.rings=24;tmesh.ring_segments=6
		ring.mesh=tmesh
		var rmat:=StandardMaterial3D.new()
		rmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
		rmat.no_depth_test=true
		rmat.render_priority=12
		rmat.albedo_color=tint
		ring.material_override=rmat
		ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(ring)
		ring.global_position=hand_pos+Vector3(0,0.02,0.04)
		tween.tween_property(ring,"scale",Vector3(2.2,1.0,2.2),0.26).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(rmat,"albedo_color:a",0.0,0.26).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		var light:=OmniLight3D.new()
		light.light_color=tint.lerp(core_tint,0.5)
		light.light_energy=2.5;light.omni_range=2.2;light.shadow_enabled=false
		fx.add_child(light)
		light.global_position=hand_pos+Vector3(0,0.08,0.08)
		tween.tween_property(light,"light_energy",0.0,0.22).set_ease(Tween.EASE_OUT)
		for i in range(7):
			var spark:=MeshInstance3D.new()
			var qmesh:=QuadMesh.new();qmesh.size=Vector2(0.10,0.10);spark.mesh=qmesh
			var smat:=ShaderMaterial.new();smat.shader=preload("res://shaders/miko8_plasma_mote.gdshader")
			smat.set_shader_parameter("tint",tint);smat.set_shader_parameter("core_tint",core_tint)
			smat.render_priority=14
			spark.material_override=smat
			spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fx.add_child(spark)
			spark.global_position=hand_pos+Vector3(0,0,0.05)
			var angle:=rng.randf_range(0,TAU)
			var dest:=hand_pos+Vector3(cos(angle)*rng.randf_range(0.2,0.45),rng.randf_range(0.05,0.30),sin(angle)*rng.randf_range(0.10,0.25))
			tween.tween_property(spark,"global_position",dest,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(spark,"scale",Vector3.ZERO,0.25).set_ease(Tween.EASE_IN)
	var center:Vector3=launcher.launch_center()
	var ground_ring:=MeshInstance3D.new()
	var gmesh:=TorusMesh.new()
	gmesh.inner_radius=0.45;gmesh.outer_radius=0.52;gmesh.rings=32;gmesh.ring_segments=6
	ground_ring.mesh=gmesh
	var gmat:=StandardMaterial3D.new()
	gmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	gmat.no_depth_test=true
	gmat.render_priority=10
	gmat.albedo_color=tint
	ground_ring.material_override=gmat
	ground_ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(ground_ring)
	ground_ring.global_position=center+Vector3(0,0.04,0.04)
	tween.tween_property(ground_ring,"scale",Vector3(2.4,1.0,2.4),0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(gmat,"albedo_color:a",0.0,0.34).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var base_light:=OmniLight3D.new()
	base_light.light_color=tint.lerp(core_tint,0.3)
	base_light.light_energy=2.2;base_light.omni_range=3.2;base_light.shadow_enabled=false
	fx.add_child(base_light)
	base_light.global_position=center+Vector3(0,0.25,0.08)
	tween.tween_property(base_light,"light_energy",0.0,0.28).set_ease(Tween.EASE_OUT)
	for fb in get_tree().get_nodes_in_group("miko8_impact_feedback"):
		if fb.has_method("crate_impact_feedback"):
			fb.crate_impact_feedback()
	get_tree().create_timer(0.40).timeout.connect(fx.queue_free)

func _tick_hold_sparks(delta:float)->void:
	if not is_instance_valid(launcher) or not actor or not actor.is_inside_tree():return
	hold_spark_timer-=delta
	if hold_spark_timer<=0:
		hold_spark_timer=randf_range(0.12,0.20)
		var side:String="L" if randf()>0.5 else "R"
		if not hand_targets.has(side):return
		var hand_pos:Vector3=hand_targets[side]
		var scene:Node=get_tree().current_scene if get_tree().current_scene else actor.get_parent()
		if not scene:return
		var spark:=MeshInstance3D.new()
		var qmesh:=QuadMesh.new();qmesh.size=Vector2(0.08,0.08);spark.mesh=qmesh
		var smat:=ShaderMaterial.new();smat.shader=preload("res://shaders/miko8_plasma_mote.gdshader")
		var tint:Color=Color("ff727a") if launcher.polarity==1 else Color("68b4ff")
		smat.set_shader_parameter("tint",tint);smat.set_shader_parameter("core_tint",Color.WHITE)
		smat.render_priority=14
		spark.material_override=smat
		spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		scene.add_child(spark)
		spark.global_position=hand_pos+Vector3(randf_range(-0.06,0.06),randf_range(0.01,0.08),0.06)
		var tween:=create_tween().set_parallel(true)
		tween.tween_property(spark,"position:y",spark.position.y+randf_range(0.06,0.14),0.15)
		tween.tween_property(spark,"scale",Vector3.ZERO,0.15)
		get_tree().create_timer(0.18).timeout.connect(spark.queue_free)

func _play_precharge_surge_juice()->void:
	if not is_instance_valid(launcher) or not actor or not actor.is_inside_tree():return
	var scene:Node=get_tree().current_scene if get_tree().current_scene else actor.get_parent()
	if not scene:return
	var fx:=Node3D.new();scene.add_child(fx)
	var tint:Color=Color("ff434e") if launcher.polarity==1 else Color("389cff")
	var core_tint:Color=Color("ffffff")
	var center:Vector3=launcher.launch_center()
	var light:=OmniLight3D.new()
	light.light_color=tint.lerp(core_tint,0.6);light.light_energy=0.8;light.omni_range=3.5;light.shadow_enabled=false
	fx.add_child(light)
	light.global_position=center+Vector3(0,0.3,0.08)
	var ring:=MeshInstance3D.new()
	var tmesh:=TorusMesh.new()
	tmesh.inner_radius=0.60;tmesh.outer_radius=0.66;tmesh.rings=32;tmesh.ring_segments=6
	ring.mesh=tmesh
	var rmat:=StandardMaterial3D.new()
	rmat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	rmat.no_depth_test=true
	rmat.render_priority=10
	rmat.albedo_color=tint
	ring.material_override=rmat
	ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(ring)
	ring.global_position=center+Vector3(0,0.06,0.04)
	ring.scale=Vector3(1.6,1.0,1.6)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(light,"light_energy",3.6,RELEASE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ring,"scale",Vector3(0.5,1.0,0.5),RELEASE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	get_tree().create_timer(RELEASE_TIME+0.05).timeout.connect(fx.queue_free)
