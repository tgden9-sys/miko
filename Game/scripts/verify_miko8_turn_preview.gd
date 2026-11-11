extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var level:Node3D=load("res://scenes/miko8_movement_test.tscn").instantiate()
	root.add_child(level)
	var actor:CharacterBody3D=level.actor
	var menu:OptionButton=level.find_children("*","OptionButton",true,false)[1]
	for label:String in ["Turn180Left","Turn180Right","Turn90Left","Turn90Right"]:
		var index:int=actor.clips.keys().find(label)+1
		menu.select(index)
		menu.item_selected.emit(index)
		actor.animation_player.seek(actor._duration(label)*0.6,true)
		level._process(0.0)
		assert(absf(angle_difference(PI/2,actor.visual.rotation.y))>deg_to_rad(15))
		level._restart_review()
		assert(actor.current_clip==label and absf(actor.visual.rotation.y-PI/2)<0.001)
	menu.select(0)
	menu.item_selected.emit(0)
	assert(actor.is_physics_processing() and not level.reviewing)
	print("TURN_PREVIEW_CHECK_PASSED")
	quit()
