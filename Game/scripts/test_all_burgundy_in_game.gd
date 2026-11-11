extends Node

var stage: int = 0
var timer: float = 0.0
var robot: CharacterBody2D
var camera: Camera2D

const OUT_DIR = "C:/Users/tgden/.gemini/antigravity/brain/1c29dfd7-0e66-4a09-8260-77a4036487b7/in_game_burgundy"

func _ready() -> void:
	DirAccess.make_dir_absolute(OUT_DIR)
	robot = get_tree().current_scene.find_child("RobotPlayer", true, false)
	if not robot:
		push_error("Could not find RobotPlayer node in scene!")
		get_tree().quit(1)
		return
	camera = get_tree().current_scene.find_child("FollowCamera", true, false)
	print("Found RobotPlayer at: ", robot.global_position)

func _physics_process(delta: float) -> void:
	timer += delta
	
	match stage:
		0:
			# Stage 0: Settle on ground in Idle
			if timer > 0.6:
				_capture("ingame_01_idle_ground.png")
				stage = 1
				timer = 0.0
		1:
			# Stage 1: Running / Moving forward
			Input.action_press("move_right")
			if timer > 0.5:
				_capture("ingame_02_running.png")
				Input.action_release("move_right")
				stage = 2
				timer = 0.0
		2:
			# Stage 2: Jumping (apex)
			Input.action_press("jump")
			if timer > 0.25:
				_capture("ingame_03_jump_apex.png")
				Input.action_release("jump")
				stage = 3
				timer = 0.0
		3:
			# Stage 3: Mount ladder at X=1680
			if timer > 0.5:
				robot.global_position = Vector2(1680, 780)
				robot.velocity = Vector2.ZERO
				Input.action_press("ui_up")
				stage = 4
				timer = 0.0
		4:
			# Stage 4: Climbing ladder
			if timer > 0.6:
				_capture("ingame_04_ladder_climb.png")
				Input.action_release("ui_up")
				stage = 5
				timer = 0.0
		5:
			# Completed all captures
			print("All in-game captures successfully saved to: ", OUT_DIR)
			get_tree().quit(0)

func _capture(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	var path = OUT_DIR + "/" + filename
	img.save_png(path)
	print("Saved in-game frame: ", path)
