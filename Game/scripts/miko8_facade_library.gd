extends RefCounted
const IDS:=["01_quiet_start","02_descending_run","03_quiet_lower","04_rising_service","05_bridge_termination","06_twin_origin","07_interwoven_crossing","08_manifold_split","09_quiet_terminal","10_plain_relief"]
const SEQUENCE:=[0,1,2,3,4,-1,5,6,7,8]
const LEFT:=[[],["blue_upper"],["blue_lower"],["blue_lower"],["blue_upper"],[],["blue_upper","copper_lower"],["copper_upper","blue_lower"],["copper_upper"],[]]
const RIGHT:=[["blue_upper"],["blue_lower"],["blue_lower"],["blue_upper"],[],["blue_upper","copper_lower"],["copper_upper","blue_lower"],["copper_upper"],[],[]]
# Centres/half-widths in the original paintings. Values are normalized image Y.
const UPPER:=[Vector2(0.40,0.06),Vector2(0.27,0.055),Vector2(0.36,0.06),Vector2(0.37,0.065),Vector2(0.365,0.065),Vector2(0.38,0.05),Vector2(0.365,0.06),Vector2(0.338,0.06),Vector2(0.34,0.065),Vector2(0.36,0.06)]
const LOWER:=[Vector2(0.66,0.06),Vector2(0.67,0.06),Vector2(0.67,0.07),Vector2(0.685,0.06),Vector2(0.66,0.06),Vector2(0.63,0.055),Vector2(0.654,0.065),Vector2(0.65,0.065),Vector2(0.66,0.06),Vector2(0.66,0.06)]
static var materials:Dictionary={}
static func _marks(value:Vector2)->Vector3:return Vector3(value.x-value.y,value.x,value.x+value.y)
static func material(index:int)->ShaderMaterial:
	if materials.has(index):return materials[index]
	var m:=ShaderMaterial.new();m.shader=preload("res://shaders/painted_facade_library.gdshader")
	m.set_shader_parameter("art",load("res://art/tutorial/facade_library/"+IDS[index]+".png"))
	m.set_shader_parameter("upper_left",_marks(UPPER[index]));m.set_shader_parameter("upper_right",_marks(UPPER[index]))
	m.set_shader_parameter("lower_left",_marks(LOWER[index]));m.set_shader_parameter("lower_right",_marks(LOWER[index]))
	if index==6:
		m.set_shader_parameter("lower_left",_marks(Vector2(0.627,0.065)))
		m.set_shader_parameter("lower_right",_marks(Vector2(0.681,0.065)))
	materials[index]=m;return m
static func validate_sequence()->bool:
	var previous:Array=[]
	for index:int in SEQUENCE:
		if index<0:
			if not previous.is_empty():return false
			previous=[];continue
		if LEFT[index]!=previous:return false
		previous=RIGHT[index]
	return previous.is_empty()
