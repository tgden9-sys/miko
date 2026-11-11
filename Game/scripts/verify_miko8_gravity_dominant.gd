extends SceneTree
class Suit extends Node3D:
	var suit_polarity:=0
	var velocity:=Vector3.ZERO
var failures:=0
var checks:Array[String]=[]
func _initialize()->void:call_deferred("run")
func ticks(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks.append(("PASS " if ok else "FAIL ")+label)
	if not ok:failures+=1;push_error(label)
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var floor_body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(80,.2,6);collision.shape=box;floor_body.position=Vector3(10,-.1,0);floor_body.add_child(collision);world.add_child(floor_body)
	var body=preload("res://scripts/miko8_charge_box.gd").new();body.position=Vector3(0,.4,0);world.add_child(body)
	var anchor=preload("res://scripts/miko8_charge_box.gd").new();anchor.position=Vector3(.2,2.,0);anchor.freeze=true;world.add_child(anchor)
	body.lock_in_color(Color.RED);anchor.lock_in_color(Color.BLUE);await ticks(120)
	check(body.position.y<.46 and body.linear_velocity.y<.1,"Elevated opposite-charge crate does not lift a grounded crate")
	anchor.neutralize();var suit:=Suit.new();world.add_child(suit);suit.add_to_group("miko8_magnetic_suit");suit.suit_polarity=2;suit.position=Vector3(2,6.,0)
	body.position=Vector3(2,2.5,0);body.linear_velocity=Vector3.ZERO;body.sleeping=false;await ticks(60)
	check(body.position.y<1.0,"A charged crate falls despite an attracting suit above it")
	suit.suit_polarity=0;await ticks(60)
	body.position=Vector3(0,.4,0);anchor.position=Vector3(.9,.4,0);body.linear_velocity=Vector3.ZERO;anchor.linear_velocity=Vector3.ZERO
	body.lock_in_color(Color.RED);anchor.lock_in_color(Color.RED)
	body._repulsion_kick(anchor,anchor.position-body.position)
	check(body.linear_velocity.y>2.9 and absf(body.linear_velocity.x)>1.,"Side-by-side repulsion retains its initial upward kick")
	var peak:float=body.position.y
	for i in range(180):await ticks(1);peak=maxf(peak,body.position.y)
	check(peak>.55 and body.position.y<.46,"Side kick rises briefly, then the charged crate lands without suspension")
	body.position=Vector3(0,1.2,0);anchor.position=Vector3(0,.4,0);body.linear_velocity=Vector3(0,-.3,0);anchor.linear_velocity=Vector3.ZERO
	body._repulsion_kick(anchor,anchor.position-body.position)
	check(body.linear_velocity.y>13.4 and absf(body.linear_velocity.x)>1.,"Stack repulsion retains its initial upward/outward kick")
	peak=body.position.y
	for i in range(240):await ticks(1);peak=maxf(peak,body.position.y)
	check(peak>1.5 and body.position.y<.46,"Stack kick follows a rising/falling arc and returns to the floor")
	body.neutralize();anchor.neutralize();body.position=Vector3(8,.4,0);body.linear_velocity=Vector3.ZERO;body.sleeping=false;await ticks(5)
	var pad=preload("res://scripts/miko8_wall_mag_pad.gd").new();pad.mount_mode=1;pad.position=Vector3(8,4,0);pad.rotation.z=PI/2.;world.add_child(pad)
	body.lock_in_color(Color.RED);pad.lock_in_color(Color.BLUE);await ticks(240)
	var lifted:float=body.position.y
	check(lifted>2.8,"A directly aligned ceiling magnet still lifts its opposite-charge crate")
	pad.neutralize();await ticks(50)
	check(body.position.y<lifted-.5 and body.linear_velocity.y<0.,"Removing direct lift restores an immediate gravity-led fall")
	await ticks(100);check(body.position.y<.46,"Released charged crate settles back on the floor")
	body.position=Vector3(8,3,0);body.linear_velocity=Vector3(20,-15,0);body._physics_process(1./60.)
	check(body.linear_velocity.y<=-14.99 and body.linear_velocity.x<=11.5,"Horizontal speed limit never scales away falling velocity")
	var result:={"failures":failures,"checks":checks,"ceiling_lift_y":lifted};FileAccess.open("res://../Builds/Validation/Level2Props/gravity_dominant.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "));print(JSON.stringify(result,"  "));quit(failures)
