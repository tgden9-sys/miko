extends SceneTree
func _initialize()->void:
	for c in ClassDB.class_get_integer_constant_list("Environment"):
		if "REFLECT" in c:print(c,"=",ClassDB.class_get_integer_constant("Environment",c))
	quit()
