@tool
extends SceneTree

func _init() -> void:
	_test_timer()

func _test_timer() -> void:
	print("Testing hit-stop timer...")
	var t0 = Time.get_ticks_msec()
	Engine.time_scale = 0.08
	# 4th param ignore_time_scale = true
	var timer = create_timer(0.04, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0
	var elapsed = Time.get_ticks_msec() - t0
	print("Hit-stop finished! Elapsed real wall-clock ms: ", elapsed, " time_scale restored: ", Engine.time_scale)
	assert(elapsed >= 35 and elapsed <= 100)
	print("Hit-stop test PASSED!")
	quit(0)
