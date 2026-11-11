extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	var miko: CharacterBody2D = level.get_node("Robot")
	miko.visual_facing = -1
	miko._fire_quick_blaster()
	var bolt: Area2D = level.get_node_or_null("QuickBlasterBolt")
	assert(bolt != null, "L2 blaster did not create a bolt")
	assert(bolt.direction == Vector2.LEFT, "Blaster ignored MIKO's facing")
	assert(absf(bolt.global_position.x - (miko.global_position.x - 34.0)) < 1.0, "Blaster muzzle offset is wrong")
	var drone_bolt: Area2D = load("res://scenes/security_drone_bolt.tscn").instantiate()
	level.add_child(drone_bolt)
	assert(drone_bolt.get_node_or_null("BoltLight") != null, "Drone bolt lacks a red light")
	assert(drone_bolt.get_node_or_null("BoltWake") != null, "Drone bolt lacks an energy wake")
	print("QUICK_BLASTER_AND_DRONE_BOLT_OK")
	quit()
