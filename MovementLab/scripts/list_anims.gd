extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var lab = (load("res://lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	print("--- ANIMATIONS LIST ---")
	for anim_name in lab.actor.player.get_animation_list():
		var anim: Animation = lab.actor.player.get_animation(anim_name)
		print(anim_name, " | length: ", anim.length, "s | loop: ", anim.loop_mode)
	lab.free()
	quit()
