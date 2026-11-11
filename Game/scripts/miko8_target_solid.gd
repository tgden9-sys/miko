extends StaticBody3D
func receive_spell(power:int)->void:
	get_parent().receive_spell(power)
