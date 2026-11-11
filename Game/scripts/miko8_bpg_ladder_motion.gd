extends Node
## Source-authored entry, alternating steps, idle and exit. No generated limb poses.
var actor:CharacterBody3D
var ladder:Node3D
var active:=false
var label:=""
var elapsed:=0.0
var duration:=0.0
var origin:=Vector3.ZERO
var rate:=1.7
var climb_rate:=2.45
var mode:=""
var alignment:=Vector3.ZERO
var start_yaw:=PI
var travel_log:Array[String]=[]
func cancel()->void:
	if actor and actor.head_offset:actor.head_offset.blend_weight=1.
	active=false;ladder=null
func clip(name:String)->Dictionary:return actor.metadata.bpg_ladder.clips[name]
func point(value:Array)->Vector3:return ladder.motion_point(value) if ladder and ladder.get("side_mount")==true else Vector3(-value[0],value[1],-value[2])
func anchor_at(y:float)->Vector3:
	var base:Vector3=ladder.motion_origin() if ladder.get("side_mount")==true else Vector3(ladder.climb_x,ladder.bottom_y,0)
	base.y=y
	return base
func first(name:String)->Vector3:return point(clip(name).motion[0])
func last(name:String)->Vector3:return point(clip(name).motion[-1])
func play(name:String,kind:String,anchor:Vector3)->void:
	label=name;mode=kind;elapsed=0;duration=clip(name).duration;origin=anchor
	start_yaw=actor.visual.rotation.y
	actor.current_clip="";actor.animation_player.speed_scale=1;actor._play(name,.10,1.0);actor.animation_player.seek(0,true)
	travel_log.append(name)
	actor._state("ClimbTopExit" if kind=="top_out" else "ClimbTopEnter" if kind=="top_in" else "ClimbEnter" if kind=="bottom_in" else "ClimbExit" if kind=="bottom_out" else "ClimbHold")
func mount(value:Node3D,from_top:bool)->void:
	ladder=value;active=true;actor.velocity=Vector3.ZERO;actor.model.position=Vector3.ZERO
	actor.head_offset.blend_weight=0.
	actor.walk_plane_z=actor.position.z
	if from_top:
		var end:=last("BpgUpExitR")
		var anchor:=anchor_at(ladder.top_y+.01-end.y)
		alignment=actor.position-(anchor+first("BpgUpEnter"))
		play("BpgUpEnter","top_in",anchor)
	else:
		var anchor:=anchor_at(ladder.bottom_y+.01)
		alignment=actor.position-anchor
		play("BpgBottomEnter","bottom_in",anchor)
func nearest(options:Array)->String:
	var best:String=options[0];var score:=INF
	for name:String in options:
		var error:=0.0
		for bone:String in ["DEF-thigh.L","DEF-thigh.R","DEF-upper_arm.L","DEF-upper_arm.R"]:
			var a:Array=clip(name).frames[0][bone].q
			var current:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.skeleton.find_bone(bone))
			error+=current.angle_to(Quaternion(a[0],a[1],a[2],a[3]))
		if error<score:score=error;best=name
	return best
func at_top()->bool:
	return actor.position.y>=ladder.top_y+.01-last("BpgUpExitR").y+first("BpgUpExitR").y-.08
func step(vertical:float)->void:
	alignment=Vector3.ZERO
	if vertical>.2 and at_top():
		var name:=nearest(["BpgUpExitL","BpgUpExitR"])
		var anchor:=anchor_at(ladder.top_y+.01-last(name).y)
		alignment=actor.position-(anchor+first(name));play(name,"top_out",anchor)
	elif vertical<-.2 and actor.position.y<=ladder.bottom_y+first("BpgBottomExitR").y+.10:
		var name:=nearest(["BpgBottomExitL","BpgBottomExitR"])
		var anchor:=anchor_at(ladder.bottom_y+.01)
		alignment=actor.position-(anchor+first(name));play(name,"bottom_out",anchor)
	elif absf(vertical)>.2:
		var name:=nearest(["BpgMoveUpL","BpgMoveUpR"] if vertical>0 else ["BpgMoveDownL","BpgMoveDownR"])
		play(name,"up" if vertical>0 else "down",actor.position-first(name))
	else:
		var name:=nearest(["BpgIdleLoopL","BpgIdleLoopR"])
		play(name,"idle",actor.position-first(name))
func finish()->void:
	actor.head_offset.blend_weight=1.
	actor.collision_mask=actor.abilities.saved_mask;actor.abilities.ladder=null
	actor.walk_plane_z=actor.position.z;actor.walk_plane_floor_y=ladder.top_y if mode=="top_out" else 0.
	var axis:float=actor._axis()
	var direction:int=(1 if axis>0 else -1) if absf(axis)>.02 else int(ladder.dismount_side)
	active=false;ladder=null
	actor._begin_ladder_exit_turn(direction)
func tick(delta:float,vertical:float)->void:
	if not active:return
	if mode=="idle" and absf(vertical)>.2:step(vertical)
	# Rung travel has its own faster clock; mounts, dismounts and idle retain
	# their accepted timing. Root travel and the source animation share dt.
	var dt:=delta*(climb_rate if mode in ["up","down"] else rate);elapsed=minf(duration,elapsed+dt)
	var frames:Array=clip(label).motion
	var frame:float=elapsed/duration*(frames.size()-1);var index:=mini(int(frame),frames.size()-2)
	actor.position=origin+point(frames[index]).lerp(point(frames[index+1]),frame-index)+alignment*(1.-smoothstep(0.,.20,elapsed/duration))
	var yaw:float=ladder.climb_yaw() if ladder.get("side_mount")==true else PI
	actor.visual.rotation.y=lerp_angle(start_yaw,yaw,smoothstep(0.,.40 if ladder.get("side_mount")==true else .20,elapsed/duration))
	actor.velocity=Vector3.ZERO;actor.animation_player.speed_scale=1;actor.animation_player.advance(dt)
	if mode=="idle":
		var look:="Center"
		var aim:=Input.get_vector("miko8_aim_left","miko8_aim_right","miko8_aim_up","miko8_aim_down")
		if aim.y<-.3:look="Up"
		elif aim.y>.3:look="Down"
		elif aim.x<-.3:look="Left"
		var pose:Dictionary=clip("BpgIdleLook"+look).frames[0]
		for bone:String in ["DEF-neck","DEF-head"]:
			var q:Array=pose[bone].q;actor.skeleton.set_bone_pose_rotation(actor.skeleton.find_bone(bone),Quaternion(q[0],q[1],q[2],q[3]))
	if elapsed>=duration:
		if mode in ["top_out","bottom_out"]:finish()
		elif mode=="idle":elapsed=0
		else:step(vertical)


