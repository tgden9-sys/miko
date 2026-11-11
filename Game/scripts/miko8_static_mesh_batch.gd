extends RefCounted

## Batch rigid visual parts by material in the owner's local space.
## Call before the scene's material conversion. Gameplay nodes stay in place.
static func bake(parent: Node3D, parts: Array[MeshInstance3D]) -> void:
	var batches: Dictionary = {}
	var to_local := parent.global_transform.affine_inverse()
	for part in parts:
		if not part.mesh or not part.visible: continue
		var transform := to_local * part.global_transform
		for surface in range(part.mesh.get_surface_count()):
			var material := part.get_active_material(surface)
			var key := [material, part.layers]
			if not batches.has(key): batches[key] = SurfaceTool.new()
			var builder: SurfaceTool = batches[key]
			builder.append_from(part.mesh, surface, transform)
		part.mesh = null
	for key: Array in batches:
		var builder: SurfaceTool = batches[key]
		builder.set_material(key[0])
		var visual := MeshInstance3D.new()
		visual.mesh = builder.commit()
		visual.layers = key[1]
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(visual)
