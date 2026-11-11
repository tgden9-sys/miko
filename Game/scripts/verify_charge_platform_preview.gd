extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview: Node2D = load("res://scenes/charge_platform_preview.tscn").instantiate()
	root.add_child(preview)
	var seen := {}
	for i in range(360):
		await physics_frame
		seen[preview.phase] = true
	assert(seen.has(0) and seen.has(1) and seen.has(2) and seen.has(3), "The charge platform preview did not complete its full cycle")
	print("CHARGE_PLATFORM_PREVIEW_OK")
	quit()
