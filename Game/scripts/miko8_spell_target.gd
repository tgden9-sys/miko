extends Area3D
var hits:=0
var pulse:=0.0
var display:MeshInstance3D
func _ready()->void:
	add_to_group("miko8_spell_targets")
	collision_layer=4
	collision_mask=0
	var collider:=CollisionShape3D.new()
	var box:=SphereShape3D.new()
	box.radius=0.38
	collider.shape=box
	add_child(collider)
	var solid:=StaticBody3D.new()
	solid.set_script(preload("res://scripts/miko8_target_solid.gd"))
	solid.collision_layer=1
	var solid_shape:=CollisionShape3D.new()
	solid_shape.shape=box
	solid.add_child(solid_shape)
	add_child(solid)
	display=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=0.38
	sphere.height=0.76
	display.mesh=sphere
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("258eaf")
	material.emission_enabled=true
	material.emission=Color("19566d")
	display.material_override=material
	add_child(display)
func receive_spell(_power:int)->void:
	hits+=1
	pulse=0.2
func _process(delta:float)->void:
	pulse=maxf(0,pulse-delta)
	display.scale=Vector3.ONE*(1.0+pulse*2.0)
