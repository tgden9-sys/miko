extends "res://scripts/miko8_charge_box.gd"

signal docking_changed(at_dock: bool)

var stop_x: float
var at_stop := false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)
	var pose := state.transform
	var low := minf(home_position.x, stop_x)
	var high := maxf(home_position.x, stop_x)
	var limited := clampf(pose.origin.x, low, high)
	if limited != pose.origin.x:
		if state.linear_velocity.x * (pose.origin.x - limited) > 0.0:
			state.linear_velocity.x = 0.0
		pose.origin.x = limited
		state.transform = pose
	var close_to_stop := absf(limited - stop_x) < (.09 if at_stop else .034)
	var seated := close_to_stop and pose.origin.y <= home_position.y - .055
	if seated != at_stop:
		at_stop = seated
		docking_changed.emit.call_deferred(at_stop)

func restore_at_stop(deck_height: float) -> void:
	at_stop = true
	move_through_door(Vector3(stop_x, deck_height + crate_size.y * .5 + .001, home_position.z))
