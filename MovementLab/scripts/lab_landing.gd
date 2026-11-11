@tool
extends AnimatableBody3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const UNDERSIDE := Color("222d35")
const STEEL := Color("4b5355")
const CAP := Color("97938a")

@export_range(1.0, 15.0, 0.1, "or_greater") var width := 2.0:
	set(value):
		width = value
		if is_node_ready():
			_rebuild()
@export var beacon := Color("f8bd70"):
	set(value):
		beacon = value
		if is_node_ready():
			_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var collider := $CollisionShape3D as CollisionShape3D
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, .36, 3.7)
	collider.shape = shape
	collider.position.y = -.18

	var old := get_node_or_null("Skin")
	if old:
		remove_child(old)
		old.queue_free()
	var skin := Node3D.new()
	skin.name = "Skin"
	add_child(skin)
	var kit := Kit.new(skin)
	kit.box(Vector3(0,-.065,0),Vector3(width,.13,3.7),CAP)
	kit.box(Vector3(0,-.245,0),Vector3(width-.06,.23,3.54),UNDERSIDE)
	kit.box(Vector3(0,-.22,1.79),Vector3(width-.24,.19,.13),STEEL)
	kit.box(Vector3(0,-.04,1.86),Vector3(width-.14,.045,.024),Color("bfb8a7"))
	var ribs := maxi(2, ceili(width / .92))
	for rib in range(ribs):
		var x := (float(rib)+.5)/ribs*width-width*.5
		kit.box(Vector3(x,-.28,1.87),Vector3(.11,.15,.045),CAP)
		kit.box(Vector3(x,.005,-.02),Vector3(.018,.01,3.38),UNDERSIDE)
		kit.box(Vector3(x,-.275,1.91),Vector3(.035,.035,.014),UNDERSIDE)
	kit.box(Vector3(0,.009,-1.3),Vector3(width-.13,.017,.052),Color("ae925b"))
	kit.box(Vector3(0,.009,1.30),Vector3(width-.13,.017,.066),STEEL)
	for side in [-1.0,1.0]:
		var edge := float(side)*(width*.5-.22)
		kit.box(Vector3(edge,-.21,1.88),Vector3(.27,.11,.045),UNDERSIDE)
		kit.box(Vector3(edge,-.19,1.913),Vector3(.15,.037,.023),beacon,true)
		kit.glow(Vector3(edge,-.19,1.93),Vector2(.58,.32),beacon,.28)
	kit.finish()

