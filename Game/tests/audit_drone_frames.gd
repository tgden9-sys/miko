extends SceneTree

func _initialize() -> void:
	var bad_frames: Array[int] = []
	for i in range(10):
		var path := "res://sprites/security_drone/turn_%02d.png" % i
		var image := (load(path) as Texture2D).get_image()
		var light_sum := 0.0
		var count := 0
		for y in range(0, image.get_height(), 8):
			for x in range(0, image.get_width(), 8):
				var pixel := image.get_pixel(x, y)
				if pixel.a > 0.3:
					light_sum += (pixel.r + pixel.g + pixel.b) / 3.0
					count += 1
		var brightness := light_sum / maxf(1.0, float(count))
		print("TURN FRAME ", i, " brightness=", brightness, " samples=", count)
		if brightness < 0.08 or count < 250:
			bad_frames.append(i)
	if not bad_frames.is_empty():
		push_error("Turn frames too dark or empty: " + str(bad_frames))
		quit(1)
		return
	quit()
