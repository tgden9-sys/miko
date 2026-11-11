extends Node3D
## Twin-Column Modular Bridge Gantry Assembly (MOD-02 Stacked + MOD-04 Deck)
@export var gantry_x:=27.0
@export var walk_z:=-0.40
@export var gantry_height:=3.60
@export var pillar_spacing:=2.10

var pillars:Array[Node3D]=[]
var catwalk_model:Node3D
var deck_body:StaticBody3D
var ladder:Node3D

func _ready()->void:
	name="ModularFreestandingGantry"
	_build_pillars()
	_build_catwalk()
	_build_ladder()
	print("MODULAR_GANTRY_PROTOTYPE_READY at X=", gantry_x, " height=", gantry_height, " span=", pillar_spacing)

func _load_glb(path:String)->Node3D:
	var gltf:=GLTFDocument.new()
	var state:=GLTFState.new()
	var err:=gltf.append_from_file(path,state)
	if err!=OK:
		push_error("Failed to load GLB: "+path)
		return null
	return gltf.generate_scene(state)

func _build_pillars()->void:
	var half_span:float=pillar_spacing*0.5
	for side:float in [-1.0, 1.0]:
		var px:float=gantry_x + side * half_span
		# Stack two 1.80m MOD-02 columns to reach 3.60m gantry height
		for tier in range(2):
			var py:float=float(tier) * 1.80
			var col:=_load_glb("res://models/environment/modular_platform/mod02_column_ladder_optimized.glb")
			if col:
				col.name="Pillar_%s_Tier%d" % ["Left" if side < 0 else "Right", tier]
				col.position=Vector3(px, py, walk_z)
				for mesh:MeshInstance3D in col.find_children("*","MeshInstance3D",true,false):
					mesh.layers=4
				add_child(col)
				pillars.append(col)

func _build_catwalk()->void:
	# 1. Visual Catwalk Model spanning across both pillars
	catwalk_model=_load_glb("res://models/environment/modular_platform/mod04_catwalk_deck_optimized.glb")
	if catwalk_model:
		catwalk_model.name="GantryCatwalkMesh"
		catwalk_model.position=Vector3(gantry_x, gantry_height, walk_z)
		for mesh:MeshInstance3D in catwalk_model.find_children("*","MeshInstance3D",true,false):
			mesh.layers=4
		add_child(catwalk_model)

	# 2. Physics Walkable Deck Collider
	deck_body=StaticBody3D.new()
	deck_body.name="ModularGantryDeckBody"
	deck_body.collision_layer=1;deck_body.collision_mask=1
	deck_body.add_to_group("tutorial_solids")
	var col:=CollisionShape3D.new();col.name="WalkableDeckSurface"
	var box:=BoxShape3D.new();box.size=Vector3(2.40, 0.14, 1.00)
	col.shape=box
	col.position=Vector3(gantry_x, gantry_height - 0.07, walk_z)
	deck_body.add_child(col)
	add_child(deck_body)

func _build_ladder()->void:
	var left_px:=gantry_x - pillar_spacing * 0.5
	ladder=preload("res://scripts/miko8_ladder.gd").new()
	ladder.name="ModularGantryLadder"
	ladder.height=gantry_height
	ladder.above_platform=0.85
	ladder.extended_rungs=false
	ladder.curved_top=true
	ladder.rung_spacing=0.2648
	ladder.rung_offset=-0.08
	ladder.rail_half_width=0.215
	ladder.industrial_model=true # Authentic industrial rails with curved walk-off handles
	ladder.set_meta("direct_entry",true)
	ladder.set_meta("bpg_ladder",true)
	ladder.set_meta("top_entry_x",left_px + 0.15)
	ladder.dismount_side=1 # Dismounts to the right onto the catwalk deck!
	ladder.position=Vector3(left_px - 0.28, 0.0, walk_z)
	add_child(ladder)
