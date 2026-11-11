extends SceneTree
const LINKS=preload("res://scripts/miko8_block_connections.gd")
var failures:=0
func _initialize()->void:call_deferred("run")
func ticks(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;push_error(label)
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var floor_body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box_shape:=BoxShape3D.new();box_shape.size=Vector3(40,.2,4);shape.shape=box_shape;floor_body.position.y=-.1;floor_body.add_child(shape);world.add_child(floor_body)
	var blocks:Array=[]
	for i in range(3):
		var body=load("res://scripts/miko8_charge_box.gd").new();body.position=Vector3(i*.9,.4,0);body.freeze=true;world.add_child(body);body.lock_in_color(Color.BLUE if i==1 else Color.RED);blocks.append(body)
	await ticks(3)
	check(LINKS.connected(blocks[0],blocks[1]) and LINKS.connected(blocks[1],blocks[2]),"R-B-R must retain both adjacent attraction links")
	check(not LINKS.connected(blocks[0],blocks[2]),"R-B-R reds must not connect through blue")
	if DisplayServer.get_name()!="headless":
		var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.;world.add_child(camera);camera.position=Vector3(.9,.8,10);camera.look_at(Vector3(.9,.8,0));camera.current=true
		var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-20,0);light.light_energy=2.;world.add_child(light)
		var fields=load("res://scripts/miko8_block_fields.gd").new();fields.camera=camera;world.add_child(fields)
		await process_frame;await RenderingServer.frame_post_draw
		check(fields.link_count==2,"R-B-R must draw exactly the two adjacent links")
		root.get_texture().get_image().save_png("res://../Builds/Validation/MagPad/neighbour_RBR.png")
	for b in blocks:b.freeze=false
	await ticks(8)
	check(blocks[0].repulsion_count==0 and blocks[2].repulsion_count==0,"R-B-R must not trigger a red-red kick")
	print("RBR_POSITIONS ",blocks[0].position," ",blocks[1].position," ",blocks[2].position)
	check(blocks[0].position.x>.01 and blocks[2].position.x<1.79,"Both reds must move toward blue")
	for b in blocks:b.freeze=true;b.linear_velocity=Vector3.ZERO
	for i in range(3):blocks[i].position=Vector3(i*.9,.4,0)
	blocks[1].neutralize();await ticks(2)
	check(LINKS.connected(blocks[0],blocks[2]),"Neutral middle block has no magnetic properties; reds become charged neighbours")
	blocks[2].neutralize();blocks[1].lock_in_color(Color.RED)
	check(LINKS.connected(blocks[0],blocks[1]),"Adjacent R-R must connect")
	blocks[0].freeze=false;blocks[1].freeze=false;await ticks(3)
	check(blocks[0].repulsion_count>0 and blocks[1].repulsion_count>0,"Adjacent R-R must still repel")
	check(not LINKS.connected(blocks[0],blocks[1]),"Breakaway must suppress active link")
	for i in range(3):blocks[i].freeze=true;blocks[i].position=Vector3(0,.4+i*.9,0);blocks[i].breakaway_remaining=0.;blocks[i].lock_in_color(Color.BLUE if i==1 else Color.RED)
	await ticks(2)
	check(LINKS.connected(blocks[0],blocks[1]) and LINKS.connected(blocks[1],blocks[2]) and not LINKS.connected(blocks[0],blocks[2]),"Vertical R-B-R stack must obey the same neighbour rule")
	blocks[2].position=Vector3(20,.4,0);await ticks(2);check(not LINKS.connected(blocks[1],blocks[2]),"Range limit must remain")
	print("BLOCK_CONNECTIONS_PASS failures=",failures)
	world.queue_free();await process_frame;await process_frame;quit(failures)
