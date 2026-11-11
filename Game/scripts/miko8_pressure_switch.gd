extends Node3D
## Sealed reusable plate: broad approaches, overlapping skirt, no open floor well.
signal pressed_changed(value:bool)
var pressed:=false
var plunger:AnimatableBody3D
var sensor:Area3D
var travel:=0.0
var glow:ShaderMaterial
var glow_strength:=0.0
var indicator_paints:Array[ShaderMaterial]=[]
const BUTTON_TRAVEL:=.020
const BUTTON_TOP:=.075
func _ready()->void:
	name="PressureSwitch";add_to_group("miko8_pressure_switches")
	var model:=get_node_or_null("SwitchModel") as Node3D
	if not model:
		model=preload("res://models/environment/pressure_switch_v2/pressure_switch_v2.glb").instantiate();model.name="SwitchModel";add_child(model)
	plunger=AnimatableBody3D.new();plunger.name="MovingCentre";add_child(plunger)
	var panel:Node3D=model.find_child("SwitchPlunger",true,false);assert(panel,"Switch must include its separate moving panel");panel.reparent(plunger,true)
	var materials:Dictionary={}
	for mesh:MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original:=mesh.get_active_material(surface) as StandardMaterial3D
			if not original:continue
			if not materials.has(original):
				var paint:=ShaderMaterial.new()
				if "ReadySignal" in original.resource_name:
					paint.shader=preload("res://shaders/miko8_switch_indicator.gdshader");indicator_paints.append(paint)
				else:
					paint.shader=preload("res://shaders/miko8_switch_steel.gdshader");paint.set_shader_parameter("base_color",original.albedo_color)
				materials[original]=paint
			mesh.set_surface_override_material(surface,materials[original])
	var frame:=StaticBody3D.new();frame.name="SealedContinuousBase";add_child(frame)
	# A closed backing under the entire centre remains load-bearing at all times.
	var backing:=CollisionShape3D.new();var backing_box:=BoxShape3D.new();backing_box.size=Vector3(1.7,.034,1.28);backing.shape=backing_box;backing.position.y=.017;frame.add_child(backing)
	for axis in [0,2]:
		for side in [-1.,1.]:
			# The inner slope continues underneath the moving panel. Loads can
			# leave a depressed plate without meeting an upright collider face.
			var inner:float=.70 if axis==0 else .49
			var peak:float=.98 if axis==0 else .76
			var outer:float=1.2 if axis==0 else 1.
			var breadth:float=1. if axis==0 else .85
			var shape:=ConvexPolygonShape3D.new();var points:=PackedVector3Array()
			for crosswise in [-breadth,breadth]:
				for point:Vector2 in [Vector2(outer,-.06),Vector2(inner,-.06),Vector2(inner,.034),Vector2(peak,BUTTON_TOP+.020),Vector2(outer,0.)]:
					points.append(Vector3(side*point.x,point.y,crosswise) if axis==0 else Vector3(crosswise,point.y,side*point.x))
			shape.points=points;var ramp:=CollisionShape3D.new();ramp.shape=shape;frame.add_child(ramp)
	var shape:=BoxShape3D.new();shape.size=Vector3(1.7,.045,1.28)
	var contact:=CollisionShape3D.new();contact.shape=shape;contact.position.y=BUTTON_TOP-.0225;plunger.add_child(contact)
	sensor=Area3D.new();sensor.name="WeightSensor";sensor.collision_layer=0;sensor.collision_mask=5;add_child(sensor)
	var volume:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.66,.22,1.24);volume.shape=box;volume.position.y=.17;sensor.add_child(volume)
	var field:=MeshInstance3D.new();field.name="PressedPurpleField";var plane:=PlaneMesh.new();plane.size=Vector2(2.7,2.3);field.mesh=plane;field.position.y=.006;field.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow=ShaderMaterial.new();glow.shader=preload("res://shaders/miko8_pressure_purple.gdshader");field.material_override=glow;add_child(field)
func _physics_process(delta:float)->void:
	var weighted:=false
	for body in sensor.get_overlapping_bodies():
		if body is CharacterBody3D and body.is_in_group("miko8_magnetic_suit"):weighted=true
		elif body is RigidBody3D and body.is_in_group("miko8_charge_targets"):weighted=true
	if weighted!=pressed:pressed=weighted;pressed_changed.emit(pressed)
	travel=move_toward(travel,BUTTON_TRAVEL if pressed else 0.,delta*.16)
	plunger.position.y=-travel
	glow_strength=move_toward(glow_strength,1. if pressed else 0.,delta*5.)
	glow.set_shader_parameter("strength",glow_strength)
	for paint in indicator_paints:paint.set_shader_parameter("strength",glow_strength)
