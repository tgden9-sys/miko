extends Node3D

const Kit := preload("res://scripts/lab_art_kit.gd")
const CENTER := .025
const AXLE_SPAN := .76
const AXLE_HEIGHT := .21
const RADIUS := .185
const TRACK_OFFSET := .365
const TRACK_WIDTH := .196
const LINK_COUNT := 28
const CURVE_LENGTH := PI * RADIUS
const BELT_LENGTH := 2.0 * (AXLE_SPAN + CURVE_LENGTH)
const LINK_SIZE := Vector3(BELT_LENGTH / LINK_COUNT - .009, .045, TRACK_WIDTH)

var belts: MultiMesh
var wheels: Array[Node3D] = []
var travel := 0.0

func _ready() -> void:
	for side: float in [-1.0, 1.0]:
		var carriage := Kit.new(self)
		carriage.box(Vector3(CENTER, AXLE_HEIGHT, side * TRACK_OFFSET), Vector3(AXLE_SPAN, .23, .14), Color("242426"))
		carriage.finish()
	for axle_x: float in [CENTER - AXLE_SPAN * .5, CENTER + AXLE_SPAN * .5]:
		var axle := Node3D.new()
		axle.position = Vector3(axle_x, AXLE_HEIGHT, 0)
		add_child(axle)
		wheels.append(axle)
		var wheel := Kit.new(axle)
		for side: float in [-1.0, 1.0]:
			var rotation := Vector3(PI * .5, 0, 0)
			wheel.cylinder(Vector3(0, 0, side * TRACK_OFFSET), Vector3(.345, .157, .345), Color("343335"), rotation)
			wheel.cylinder(Vector3(0, 0, side * .449), Vector3(.270, .026, .270), Color("64605b"), rotation)
			wheel.cylinder(Vector3(0, 0, side * .469), Vector3(.133, .035, .133), Color("373638"), rotation)
			for pin in range(4):
				var angle := TAU * pin / 4.0
				wheel.cylinder(Vector3(cos(angle) * .094, sin(angle) * .094, side * .467),
					Vector3(.027, .017, .027), Color("9a917d"), rotation)
		wheel.finish()
	belts = MultiMesh.new()
	belts.transform_format = MultiMesh.TRANSFORM_3D
	belts.use_colors = true
	belts.mesh = Kit.cube
	belts.instance_count = LINK_COUNT * 2
	belts.custom_aabb = AABB(Vector3(-.64, -.02, -.48), Vector3(1.34, .46, .96))
	var belt_mesh := MultiMeshInstance3D.new()
	belt_mesh.multimesh = belts
	belt_mesh.material_override = Kit.deck_paint()
	belt_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(belt_mesh)
	for i in range(LINK_COUNT):
		var tone := Color("4e4a47") if i % 3 == 0 else Color("3c3937")
		belts.set_instance_color(i * 2, tone)
		belts.set_instance_color(i * 2 + 1, tone)
	reset()

func reset() -> void:
	travel = 0.0
	for axle in wheels:
		axle.rotation.z = 0.0
	_update_belts()

func roll(distance: float) -> void:
	if absf(distance) < .00001:
		return
	travel = fposmod(travel + distance, BELT_LENGTH)
	for axle in wheels:
		axle.rotation.z = wrapf(axle.rotation.z - distance / RADIUS, -PI, PI)
	_update_belts()

func _update_belts() -> void:
	for i in range(LINK_COUNT):
		var distance := fposmod(travel + i * BELT_LENGTH / LINK_COUNT, BELT_LENGTH)
		var pose := _belt_pose(distance)
		var basis := Basis(Vector3.BACK, pose.z).scaled_local(LINK_SIZE)
		belts.set_instance_transform(i * 2, Transform3D(basis, Vector3(pose.x, pose.y, TRACK_OFFSET)))
		belts.set_instance_transform(i * 2 + 1, Transform3D(basis, Vector3(pose.x, pose.y, -TRACK_OFFSET)))

func _belt_pose(distance: float) -> Vector3:
	var left := CENTER - AXLE_SPAN * .5
	var right := CENTER + AXLE_SPAN * .5
	if distance < AXLE_SPAN:
		return Vector3(left + distance, AXLE_HEIGHT + RADIUS, 0)
	distance -= AXLE_SPAN
	if distance < CURVE_LENGTH:
		var angle := distance / RADIUS
		return Vector3(right + RADIUS * sin(angle), AXLE_HEIGHT + RADIUS * cos(angle), -angle)
	distance -= CURVE_LENGTH
	if distance < AXLE_SPAN:
		return Vector3(right - distance, AXLE_HEIGHT - RADIUS, -PI)
	var angle := (distance - AXLE_SPAN) / RADIUS
	return Vector3(left - RADIUS * sin(angle), AXLE_HEIGHT - RADIUS * cos(angle), -PI - angle)
