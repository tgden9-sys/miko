extends Node3D
## Instanced curved grass and small weeds rooted outside the single walking lane.
var rng:=RandomNumberGenerator.new()
var material:ShaderMaterial
var custom_locations:Array[Vector3]=[]
const PALETTE:=["6e7750","7e8055","545f3c","96905f","626d43"]
func _ready()->void:
	name="YardGrassAndWeeds";rng.seed=640731
	material=ShaderMaterial.new();material.shader=preload("res://shaders/miko8_yard_grass.gdshader")
	var locations:Array[Vector3]=[]
	# Uneven clusters in cracks and along the outer rim, not a repeated lawn.
	for anchor:Vector3 in [Vector3(1.1,0,.95),Vector3(4.3,0,-1.0),Vector3(7.5,0,1.0),Vector3(9.2,0,-1.0),Vector3(14.3,0,.95),Vector3(16.4,0,-.95),Vector3(21.2,0,1.05),Vector3(26.7,0,.95),Vector3(29.7,0,-1.),Vector3(32.6,0,1.05),Vector3(36.8,0,-1.0),Vector3(40.4,0,1.0),Vector3(43.3,0,-1.),Vector3(46.6,0,.95),Vector3(48.5,0,-1.),Vector3(59.7,0,.95),Vector3(62.3,0,-1.)]:
		for index in range(rng.randi_range(2,4)):
			locations.append(anchor+Vector3(rng.randf_range(-.48,.48),.012,rng.randf_range(-.12,.12)))
	# Small colonies tuck against the workshop's front corners and wall base.
	for point:Vector3 in [Vector3(52.83,.012,.88),Vector3(53.05,.012,.84),Vector3(54.2,.012,.83),Vector3(56.7,.012,.87),Vector3(57.85,.012,.82),Vector3(58.1,.012,.86)]:locations.append(point)
	for point:Vector3 in [Vector3(17.3,.012,.9),Vector3(19.5,.012,.97),Vector3(20.8,.012,.97),Vector3(23.8,.012,.9),Vector3(20.3,2.83364,-1.3),Vector3(22.8,2.83364,-1.3)]:locations.append(point)
	if not custom_locations.is_empty():locations=custom_locations.duplicate()
	for variant in range(5):
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
		batch.mesh=_tuft(variant)
		var selected:Array[Vector3]=[]
		for index in range(locations.size()):
			if index%5==variant:selected.append(locations[index])
		batch.instance_count=selected.size()
		var bounds:=AABB()
		var mesh_bounds:=batch.mesh.get_aabb()
		for index in range(selected.size()):
			var scale:=rng.randf_range(.65,1.10)
			var transform:=Transform3D(Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(Vector3.ONE*scale),selected[index])
			batch.set_instance_transform(index,transform);batch.set_instance_color(index,Color.WHITE)
			var instance_bounds:=transform*mesh_bounds
			bounds=instance_bounds if index==0 else bounds.merge(instance_bounds)
		# Include every tuft plus the small vertex displacement from wind.
		if not selected.is_empty():batch.custom_aabb=bounds.grow(.03)
		var visual:=MultiMeshInstance3D.new();visual.name="GrassAndWeeds_"+str(variant);visual.multimesh=batch
		visual.layers=4;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual)
	if custom_locations.is_empty():_groundcover()
	print("YARD_FOLIAGE_READY tufts=",locations.size()," grass_draws=5 collision=false")
func _tuft(variant:int)->ArrayMesh:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(30):
		var angle:=rng.randf_range(-PI,PI)
		var root:=Vector3(cos(angle),0,sin(angle))*sqrt(rng.randf())*.12
		var height:=rng.randf_range(.16,.38)*(1.+variant*.06)
		var lean:=Vector3(rng.randf_range(-.13,.13),0,rng.randf_range(-.13,.13))
		var side:=Vector3(cos(angle),0,sin(angle))
		var width:=rng.randf_range(.006,.015)
		if blade<4:width*=2.3;height*=.70 # broader low weed leaves among finer grass
		var color:=Color(PALETTE[rng.randi()%PALETTE.size()]).srgb_to_linear()
		for segment in range(5):
			var a:=float(segment)/5.;var b:=float(segment+1)/5.
			var ca:=root+Vector3.UP*height*(a-.12*a*a*a)+lean*a*a
			var cb:=root+Vector3.UP*height*(b-.12*b*b*b)+lean*b*b
			var wa:=width*(1.-a)*(.6+.4*sin(a*PI));var wb:=width*(1.-b)*(.6+.4*sin(b*PI))
			var points:=[ca-side*wa,ca+side*wa,cb+side*wb,cb-side*wb]
			var uvs:=[Vector2(0,a),Vector2(1,a),Vector2(1,b),Vector2(0,b)]
			for index:int in [0,1,2,0,2,3]:
				surface.set_color(color.lerp(Color("a19b69").srgb_to_linear(),uvs[index].y*.2))
				surface.set_uv(uvs[index]);surface.add_vertex(points[index])
	surface.generate_normals();surface.set_material(material)
	return surface.commit()
func _groundcover()->void:
	# Existing photographic moss is used sparingly at sheltered joints.
	var paint:=StandardMaterial3D.new();paint.albedo_texture=preload("res://art/tutorial/ortho_materials/moss_short.png")
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;paint.alpha_scissor_threshold=.38
	paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.roughness=.95
	paint.uv1_offset=Vector3(0,.21,0);paint.uv1_scale=Vector3(1,.56,1)
	paint.albedo_color=Color("9eab88");paint.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for at:Vector3 in [Vector3(4.1,.09,-1.04),Vector3(14.4,.08,1.0),Vector3(29.5,.08,-1.),Vector3(40.2,.09,1.),Vector3(52.98,.07,.81),Vector3(57.85,.08,.81),Vector3(62.5,.08,-1.)]:
		var visual:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(rng.randf_range(.50,.78),.19)
		visual.mesh=quad;visual.material_override=paint;visual.position=at;visual.layers=4
		visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(visual)
