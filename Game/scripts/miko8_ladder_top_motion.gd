extends Node
## Plays the baked pose and authored root-motion curve at the same time.
var actor:CharacterBody3D
var active:=false
var descending:=false
var ladder:Node3D
var label:=""
var elapsed:=0.0
var duration:=0.0
var start_offset:=Vector3.ZERO
var start_yaw:=0.0
func cancel()->void:
	active=false;ladder=null;elapsed=0
func begin(value:Node3D,from_top:bool)->void:
	ladder=value;descending=from_top;label="LadderTopIn" if from_top else "LadderTopOut"
	duration=actor.metadata.clips[label].duration;elapsed=0;active=true
	var first:Array=actor.metadata.clips[label].root_motion[0]
	var origin:=Vector3(ladder.climb_x,ladder.top_y,0)
	start_offset=actor.position-origin-Vector3(first[0],first[1],first[2])
	start_yaw=actor.visual.rotation.y
	actor.velocity=Vector3.ZERO;actor.animation_player.speed_scale=1.0;actor.model.position=Vector3.ZERO
	actor._state("ClimbTopEnter" if descending else "ClimbTopExit")
	actor.current_clip="";actor._play(label,.08,1.0);actor.animation_player.seek(0,true)
func tick(delta:float)->void:
	if not active or not is_instance_valid(ladder):return
	elapsed=minf(duration,elapsed+delta)
	var frames:Array=actor.metadata.clips[label].root_motion
	var frame:float=elapsed/duration*(frames.size()-1)
	var index:=mini(int(frame),frames.size()-2);var weight:=frame-index
	var a:Array=frames[index];var b:Array=frames[index+1]
	var root:=Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),weight)
	var yaw:float=lerp_angle(a[3],b[3],weight)
	actor.position=Vector3(ladder.climb_x,ladder.top_y,0)+root+start_offset*(1.-smoothstep(0.,.25,elapsed/duration))
	actor.visual.rotation.y=lerp_angle(start_yaw,yaw,smoothstep(0.,.13,elapsed/duration))
	actor.animation_player.speed_scale=1.0;actor.animation_player.advance(delta)
	if elapsed>=duration:
		active=false
		if descending:
			actor._state("ClimbHold");actor.current_clip="";actor._play("StockLadderDown",.06,actor.abilities.CLIMB_RATE)
		else:
			actor.collision_mask=actor.abilities.saved_mask;actor.abilities.ladder=null
			actor.facing=1;actor.target_facing=1;actor.position.z=0
			actor._resume_locomotion(actor._axis())
		ladder=null
