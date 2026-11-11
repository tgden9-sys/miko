extends Control
## Diegetic suit projection: clipped metal/glass outline, telemetry and a head link.
var plate:Control
var actor:Node3D
var camera:Camera3D
var stage:=1
var clock:=0.
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float)->void:
	if is_visible_in_tree():clock+=delta;queue_redraw()
func _draw()->void:
	if not is_instance_valid(plate):return
	var r:=plate.get_global_rect().grow(12.)
	var p:=PackedVector2Array([r.position+Vector2(26,0),r.position+Vector2(r.size.x-70,0),r.position+Vector2(r.size.x,32),r.end-Vector2(0,24),r.end-Vector2(24,0),r.position+Vector2(0,r.size.y),r.position+Vector2(0,26)])
	draw_colored_polygon(p,Color(.018,.045,.065,.96))
	var edge:=p.duplicate();edge.append(p[0]);draw_polyline(edge,Color("4f858c"),1.5,true)
	draw_line(r.position+Vector2(28,0),r.position+Vector2(260,0),Color("99e2d4"),3.,true)
	draw_line(r.end-Vector2(185,0),r.end-Vector2(25,0),Color("72999e"),2.,true)
	# Fine scan lines stay behind the content rather than flickering over text.
	for y in range(int(r.position.y)+3,int(r.end.y),5):draw_line(Vector2(r.position.x+2,y),Vector2(r.end.x-2,y),Color(.18,.48,.53,.035),1.)
	for i in range(3):
		var x:=r.end.x-140.+i*33.
		draw_rect(Rect2(x,r.position.y+16.,22.,4.),Color("8be4d0") if i<stage else Color("263e49"))
	var foot:=r.position+Vector2(-16.,r.size.y*.65)
	if is_instance_valid(actor) and is_instance_valid(camera):
		var head:=camera.unproject_position(actor.global_position+Vector3(0,1.95,0))
		if head.x<r.position.x-20. or head.y>r.end.y+20.:
			var joint:=Vector2(foot.x-35.,head.y)
			draw_polyline(PackedVector2Array([head,joint,foot,foot+Vector2(16.,0)]),Color(.4,.78,.78,.65),1.,true)
			draw_arc(head,9.,0.,TAU,32,Color("88cabf"),1.2,true)
			draw_circle(head,2.,Color("b6f2dd"))
	for i in range(9):
		var y:=r.position.y+50.+i*10.
		draw_line(Vector2(r.position.x-9,y),Vector2(r.position.x-4,y),Color("6b9ba3"),1.)
	var pulse:=.35+.15*sin(clock*2.)
	draw_circle(r.end-Vector2(12,12),2.,Color(.5,1.,.8,pulse))
