extends Node3D
## The first ladder leads to the towers and the final jump to the stack.
const FINISH_X:=preload("res://scripts/miko8_level2_props.gd").COURSE_STACK_X
const LAYOUT:=[
	[40.0,0,2.8],[42.9,1,3.55],[45.8,2,4.3],
	[48.7,2,4.3],[51.6,1,3.55],
]
var towers:Array[Node3D]=[]
var actor:CharacterBody3D

func _ready()->void:
	name="PlatformTowerCourse"
	for i in range(LAYOUT.size()):
		var spec:Array=LAYOUT[i]
		var tower:=preload("res://scripts/miko8_platform_tower.gd").new()
		tower.name="Tower%d"%(i+1);tower.position.x=float(spec[0]);tower.variant=int(spec[1]);tower.deck_height=float(spec[2])
		tower.front_ladder=i==0;tower.reverse_face=not tower.front_ladder
		add_child(tower);towers.append(tower)
	actor=get_parent().actor
	print("PLATFORM_TOWER_COURSE_READY count=",towers.size()," finish_x=",FINISH_X)

func _physics_process(_delta:float)->void:
	if not is_instance_valid(actor):return
	# A descending jump towards a lower tower must retain the elevated depth
	# lane until it passes below every deck. Missing the course still falls
	# back to the ordinary ground lane through the actor's existing logic.
	var landing_floor:=preload("res://scripts/miko8_level2_props.gd").STOREY
	if actor.position.x>38.5 and actor.position.x<FINISH_X+2.4 and actor.walk_plane_z<-.3 and actor.position.y>landing_floor-.10:
		actor.walk_plane_floor_y=minf(actor.walk_plane_floor_y,landing_floor)
