extends Node3D
var seed_value:=392
var depth:=-25.0
var haze:=.0
var rng:=RandomNumberGenerator.new()
var warm:Array[Transform3D]=[]
var cool:Array[Transform3D]=[]
func _ready()->void:
	rng.seed=seed_value
	var bodies:Array[StandardMaterial3D]=[]
	for color:Color in [Color("141d29"),Color("1b2633"),Color("1d2939"),Color("263240")]:
		var mat:=StandardMaterial3D.new();mat.albedo_color=color.lerp(Color("435569"),haze);mat.roughness=.96
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;bodies.append(mat)
	var x:=-16.0
	while x<88:
		var width:=rng.randf_range(1.2,3.2);var height:=rng.randf_range(11,23)
		var z:=depth+rng.randf_range(-3,2);var floor_y:=z*tan(deg_to_rad(19.0))-7.7
		var body:=_box(Vector3(x,floor_y+height/2,z),Vector3(width,height,rng.randf_range(1.5,3)),bodies[rng.randi_range(0,3)])
		var front_z:=body.position.z+(body.mesh as BoxMesh).size.z/2+.015
		# Tiny opaque emissive windows become real optical bokeh in the camera.
		var cols:=int(width/.29)
		for col in range(cols):
			for row in range(int(height/.46)):
				if rng.randf()>.20:continue
				var at:=Vector3(x-width/2+.20+col*.29,floor_y+.3+row*.46,front_z)
				var t:=Transform3D(Basis.IDENTITY.scaled(Vector3(rng.randf_range(.06,.105),rng.randf_range(.10,.18),1)),at)
				if rng.randf()<.12:cool.append(t)
				else:warm.append(t)
		if rng.randf()<.75:
			_box(Vector3(x,floor_y+height+.16,z),Vector3(width*.68,.32,.9),bodies[0])
		if rng.randf()<.35:
			_box(Vector3(x+.2,floor_y+height+.8,z),Vector3(.045,1.6,.045),bodies[2])
		x+=width+rng.randf_range(.45,1.4)
	_windows(warm,Color("ffd08c"),3.0)
	_windows(cool,Color("8fc0df"),1.7)
func _box(at:Vector3,size:Vector3,mat:Material)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size
	mesh.mesh=box;mesh.position=at;mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh);mesh.add_to_group("miko8_budget_visual");mesh.set_meta("budget_half_width",size.x/2+.1);return mesh
func _windows(list:Array[Transform3D],color:Color,energy:float)->void:
	# Chunk in world x so off-camera window groups leave the render budget.
	for start in range(-20,100,10):
		var selection:Array[Transform3D]=[]
		for t in list:
			if t.origin.x>=start and t.origin.x<start+10:selection.append(t)
		if selection.is_empty():continue
		var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=energy;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var quad:=QuadMesh.new();quad.size=Vector2.ONE;quad.material=mat
		var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.mesh=quad;multimesh.instance_count=selection.size()
		var node:=MultiMeshInstance3D.new();node.position=Vector3(start+5,0,depth)
		for i in range(selection.size()):
			var t:=selection[i];t.origin-=node.position;multimesh.set_instance_transform(i,t)
		node.multimesh=multimesh;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node);node.add_to_group("miko8_budget_visual");node.set_meta("budget_half_width",5.0)
