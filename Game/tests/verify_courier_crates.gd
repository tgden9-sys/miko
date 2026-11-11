extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node2D = load("res://scenes/industrial_city.tscn").instantiate()
	root.add_child(scene)
	var crates: Node2D = scene.get_node("Crates")
	var base: CharacterBody2D = crates.get_node("CourierStackBase")
	var top: CharacterBody2D = crates.get_node("CourierStackTop")
	var loose: CharacterBody2D = crates.get_node("CourierLoose")
	for crate in crates.get_children():
		if crate.polarity != 0:
			push_error("A crate did not start neutral: " + crate.name)
			quit(1)
			return
		if not crate.get_script().resource_path.ends_with("crate_courier.gd"):
			push_error("Old crate type remains in the level: " + crate.name)
			quit(1)
			return
	for i in range(90):
		await physics_frame
	var vertical_gap: float = base.global_position.y - top.global_position.y
	if absf(vertical_gap - 50.0) > 5.0 or absf(base.global_position.x - top.global_position.x) > 4.0:
		push_error("Courier stack shifted: gap=" + str(vertical_gap))
		quit(1)
		return
	if absf(loose.global_position.y - base.global_position.y) > 4.0:
		push_error("Loose courier crate did not settle beside stack")
		quit(1)
		return
	var sprite: Sprite2D = base.get_node("Sprite2D")
	var neutral: Texture2D = load("res://sprites/crates/courier_side_neutral.png")
	var red: Texture2D = load("res://sprites/crates/courier_side_red.png")
	var blue: Texture2D = load("res://sprites/crates/courier_side_blue.png")
	if sprite.texture != neutral:
		push_error("Courier crate did not show neutral art")
		quit(1)
		return
	base.lock_in_color(Color.RED)
	if sprite.texture != red:
		push_error("Courier crate did not show red art")
		quit(1)
		return
	base.lock_in_color(Color.BLUE)
	if sprite.texture != blue:
		push_error("Courier crate did not show blue art")
		quit(1)
		return
	base.neutralize()
	if sprite.texture != neutral:
		push_error("Courier crate did not return to neutral art")
		quit(1)
		return
	base.lock_in_color(Color.RED)
	loose.lock_in_color(Color.BLUE)
	var separation_before: float = absf(loose.global_position.x - base.global_position.x)
	for i in range(25):
		await physics_frame
	var separation_after: float = absf(loose.global_position.x - base.global_position.x)
	if separation_after >= separation_before - 3.0:
		push_error("Opposite polarity courier crates did not attract")
		quit(1)
		return
	print("COURIER STACK AND POLARITY OK gap=", vertical_gap, " attracted=", separation_before - separation_after)
	quit()
