import sys
from pathlib import Path

root = Path(r"C:\Users\tgden\Documents\Codex\2026-10-22\referenced-chatgpt-conversation-this-is-an\outputs\godot_robot_demo_body_turn_v25")
scenes = root / "scenes"

scene_text = """[gd_scene load_steps=14 format=3]

[ext_resource type="Script" path="res://scripts/follow_camera.gd" id="1"]
[ext_resource type="Texture2D" path="res://environment/layer1_skyline.jpg" id="2"]
[ext_resource type="Texture2D" path="res://environment/layer2_infrastructure.png" id="3"]
[ext_resource type="Texture2D" path="res://environment/layer3_crane_elevator.png" id="4"]
[ext_resource type="Texture2D" path="res://environment/layer4_cables_railings.png" id="5"]
[ext_resource type="Texture2D" path="res://environment/catwalk_segment.png" id="6"]
[ext_resource type="Texture2D" path="res://environment/catwalk_rail.png" id="7"]
[ext_resource type="Texture2D" path="res://environment/catwalk_column.png" id="8"]
[ext_resource type="Texture2D" path="res://environment/elevator_pad.png" id="9"]
[ext_resource type="Shader" path="res://environment/laser_grid.gdshader" id="10"]
[ext_resource type="Texture2D" path="res://environment/layer6_foreground_blur.png" id="11"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="12"]

[sub_resource type="Environment" id="Environment_cyber"]
background_mode = 3
tonemap_mode = 3
glow_enabled = true
glow_levels/1 = 0.6
glow_levels/2 = 0.5
glow_levels/3 = 0.8
glow_levels/4 = 0.3
glow_levels/5 = 0.4
glow_intensity = 0.75
glow_strength = 0.95
glow_bloom = 0.16
glow_blend_mode = 0

[sub_resource type="ShaderMaterial" id="ShaderMaterial_laser"]
shader = ExtResource("10")
shader_parameter/grid_color = Color(1, 0.16, 0.25, 1)
shader_parameter/glow_color = Color(1, 0.35, 0.45, 0.6)
shader_parameter/grid_size = Vector2(10, 6)
shader_parameter/line_thickness = 0.018
shader_parameter/pulse_speed = 2.4
shader_parameter/pulse_intensity = 0.3
shader_parameter/border_thickness = 0.022

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(4400, 120)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_catwalk_left"]
size = Vector2(800, 24)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_catwalk_mid"]
size = Vector2(640, 24)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_catwalk_right"]
size = Vector2(800, 24)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall"]
size = Vector2(80, 1400)

[sub_resource type="Curve" id="Curve_mist"]
_data = [Vector2(0, 0.1), 0.0, 2.0, 0, 0, Vector2(0.5, 0.7), 0.0, 0.0, 0, 0, Vector2(1, 0), -1.5, 0.0, 0, 0]
point_count = 3

[node name="IndustrialCity" type="Node2D"]

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_cyber")

[node name="AmbientModulate" type="CanvasModulate" parent="."]
color = Color(0.88, 0.92, 0.97, 1)

[node name="ParallaxBackground" type="ParallaxBackground" parent="."]
layer = -100

[node name="Layer1_Skyline" type="ParallaxLayer" parent="ParallaxBackground"]
motion_scale = Vector2(0.12, 0.04)
motion_mirroring = Vector2(1935, 0)

[node name="SkySprite" type="Sprite2D" parent="ParallaxBackground/Layer1_Skyline"]
scale = Vector2(1.40625, 1.40625)
texture = ExtResource("2")
centered = false

[node name="Layer2_Infrastructure" type="ParallaxLayer" parent="ParallaxBackground"]
motion_scale = Vector2(0.28, 0.1)
motion_mirroring = Vector2(1935, 0)

[node name="InfraSprite" type="Sprite2D" parent="ParallaxBackground/Layer2_Infrastructure"]
scale = Vector2(1.40625, 1.40625)
texture = ExtResource("3")
centered = false

[node name="Layer3_CraneElevator" type="ParallaxLayer" parent="ParallaxBackground"]
motion_scale = Vector2(0.52, 0.2)
motion_mirroring = Vector2(1935, 0)

[node name="CraneSprite" type="Sprite2D" parent="ParallaxBackground/Layer3_CraneElevator"]
scale = Vector2(1.40625, 1.40625)
texture = ExtResource("4")
centered = false

[node name="Layer4_CablesRailings" type="ParallaxLayer" parent="ParallaxBackground"]
motion_scale = Vector2(0.76, 0.38)
motion_mirroring = Vector2(1935, 0)

[node name="CableSprite" type="Sprite2D" parent="ParallaxBackground/Layer4_CablesRailings"]
scale = Vector2(1.40625, 1.40625)
texture = ExtResource("5")
centered = false

[node name="WorldEnvironmentGeometry" type="Node2D" parent="."]

[node name="LaserSecurityGrid" type="ColorRect" parent="WorldEnvironmentGeometry"]
material = SubResource("ShaderMaterial_laser")
offset_left = 180.0
offset_top = 110.0
offset_right = 780.0
offset_bottom = 430.0

[node name="LaserGridBorder" type="Line2D" parent="WorldEnvironmentGeometry"]
points = PackedVector2Array(180, 110, 780, 110, 780, 430, 180, 430, 180, 110)
width = 4.0
default_color = Color(1, 0.2, 0.3, 0.8)

[node name="Columns" type="Node2D" parent="WorldEnvironmentGeometry"]

[node name="Col1" type="Sprite2D" parent="WorldEnvironmentGeometry/Columns"]
position = Vector2(300, 680)
texture = ExtResource("8")

[node name="Col2" type="Sprite2D" parent="WorldEnvironmentGeometry/Columns"]
position = Vector2(700, 680)
texture = ExtResource("8")

[node name="ColMidL" type="Sprite2D" parent="WorldEnvironmentGeometry/Columns"]
position = Vector2(1700, 780)
texture = ExtResource("8")

[node name="ColMidR" type="Sprite2D" parent="WorldEnvironmentGeometry/Columns"]
position = Vector2(2140, 780)
texture = ExtResource("8")

[node name="ColRight" type="Sprite2D" parent="WorldEnvironmentGeometry/Columns"]
position = Vector2(3000, 780)
texture = ExtResource("8")

[node name="Platforms" type="Node2D" parent="."]

[node name="GroundPlatform" type="StaticBody2D" parent="Platforms"]
position = Vector2(1920, 938)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/GroundPlatform"]
shape = SubResource("RectangleShape2D_ground")

[node name="GroundVisuals" type="Node2D" parent="Platforms/GroundPlatform"]
position = Vector2(-1920, -60)

[node name="Segment0" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(0, 0)
texture = ExtResource("6")
centered = false

[node name="Segment1" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(512, 0)
texture = ExtResource("6")
centered = false

[node name="Segment2" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(1024, 0)
texture = ExtResource("6")
centered = false

[node name="Segment3" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(1536, 0)
texture = ExtResource("6")
centered = false

[node name="Segment4" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(2048, 0)
texture = ExtResource("6")
centered = false

[node name="Segment5" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(2560, 0)
texture = ExtResource("6")
centered = false

[node name="Segment6" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(3072, 0)
texture = ExtResource("6")
centered = false

[node name="Segment7" type="Sprite2D" parent="Platforms/GroundPlatform/GroundVisuals"]
position = Vector2(3584, 0)
texture = ExtResource("6")
centered = false

[node name="CatwalkUpperLeft" type="StaticBody2D" parent="Platforms"]
position = Vector2(490, 440)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/CatwalkUpperLeft"]
shape = SubResource("RectangleShape2D_catwalk_left")
one_way_collision = true

[node name="RailL" type="Sprite2D" parent="Platforms/CatwalkUpperLeft"]
position = Vector2(-260, -36)
texture = ExtResource("7")

[node name="RailR" type="Sprite2D" parent="Platforms/CatwalkUpperLeft"]
position = Vector2(-4, -36)
texture = ExtResource("7")

[node name="Seg1" type="Sprite2D" parent="Platforms/CatwalkUpperLeft"]
position = Vector2(-384, -12)
texture = ExtResource("6")
centered = false
region_enabled = true
region_rect = Rect2(0, 0, 768, 120)

[node name="CatwalkMiddleElevator" type="StaticBody2D" parent="Platforms"]
position = Vector2(1920, 630)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/CatwalkMiddleElevator"]
shape = SubResource("RectangleShape2D_catwalk_mid")
one_way_collision = true

[node name="SegMid" type="Sprite2D" parent="Platforms/CatwalkMiddleElevator"]
position = Vector2(-320, -12)
texture = ExtResource("6")
centered = false
region_enabled = true
region_rect = Rect2(0, 0, 640, 120)

[node name="ElevatorPad" type="Sprite2D" parent="Platforms/CatwalkMiddleElevator"]
position = Vector2(0, -18)
texture = ExtResource("9")

[node name="CatwalkUpperRight" type="StaticBody2D" parent="Platforms"]
position = Vector2(3000, 610)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/CatwalkUpperRight"]
shape = SubResource("RectangleShape2D_catwalk_right")
one_way_collision = true

[node name="RailRight" type="Sprite2D" parent="Platforms/CatwalkUpperRight"]
position = Vector2(-128, -36)
texture = ExtResource("7")

[node name="RailRight2" type="Sprite2D" parent="Platforms/CatwalkUpperRight"]
position = Vector2(128, -36)
texture = ExtResource("7")

[node name="SegRight" type="Sprite2D" parent="Platforms/CatwalkUpperRight"]
position = Vector2(-384, -12)
texture = ExtResource("6")
centered = false
region_enabled = true
region_rect = Rect2(0, 0, 768, 120)

[node name="LeftBoundary" type="StaticBody2D" parent="Platforms"]
position = Vector2(-20, 540)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/LeftBoundary"]
shape = SubResource("RectangleShape2D_wall")

[node name="RightBoundary" type="StaticBody2D" parent="Platforms"]
position = Vector2(3860, 540)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Platforms/RightBoundary"]
shape = SubResource("RectangleShape2D_wall")

[node name="RainParticlesBack" type="CPUParticles2D" parent="."]
z_index = -1
position = Vector2(1920, -30)
amount = 200
lifetime = 1.3
preprocess = 1.0
emission_shape = 3
emission_rect_extents = Vector2(2100, 20)
direction = Vector2(0.12, 1)
spread = 2.0
gravity = Vector2(0, 400)
initial_velocity_min = 850.0
initial_velocity_max = 1100.0
color = Color(0.68, 0.82, 1, 0.32)

[node name="RainParticlesFront" type="CPUParticles2D" parent="."]
z_index = 8
position = Vector2(1920, -30)
amount = 80
lifetime = 1.3
preprocess = 1.0
emission_shape = 3
emission_rect_extents = Vector2(2100, 20)
direction = Vector2(0.12, 1)
spread = 2.0
gravity = Vector2(0, 400)
initial_velocity_min = 950.0
initial_velocity_max = 1200.0
color = Color(0.75, 0.88, 1, 0.38)

[node name="MistParticles" type="CPUParticles2D" parent="."]
z_index = 1
position = Vector2(1920, 875)
amount = 45
lifetime = 3.5
preprocess = 2.0
emission_shape = 3
emission_rect_extents = Vector2(2000, 10)
direction = Vector2(0.5, -0.2)
spread = 25.0
gravity = Vector2(0, -15)
initial_velocity_min = 25.0
initial_velocity_max = 55.0
scale_amount_min = 12.0
scale_amount_max = 24.0
scale_amount_curve = SubResource("Curve_mist")
color = Color(0.15, 0.28, 0.4, 0.14)

[node name="Robot" parent="." instance=ExtResource("12")]
position = Vector2(450, 840)

[node name="Camera2D" type="Camera2D" parent="." node_paths=PackedStringArray("target")]
position = Vector2(960, 540)
limit_left = 0
limit_top = 0
limit_right = 3840
limit_bottom = 1080
limit_smoothed = true
position_smoothing_enabled = false
process_callback = 0
script = ExtResource("1")
target = NodePath("../Robot")
lookahead_distance = 150.0
lookahead_speed = 3.5
follow_smoothness = 6.0
vertical_offset = -60.0

[node name="ParallaxForeground" type="ParallaxBackground" parent="."]
layer = 10

[node name="Layer6_ForegroundBlur" type="ParallaxLayer" parent="ParallaxForeground"]
motion_scale = Vector2(1.35, 1.15)
motion_mirroring = Vector2(1935, 0)

[node name="ForegroundSprite" type="Sprite2D" parent="ParallaxForeground/Layer6_ForegroundBlur"]
scale = Vector2(1.40625, 1.40625)
texture = ExtResource("11")
centered = false
"""

out_path = scenes / "industrial_city.tscn"
out_path.write_text(scene_text, encoding="utf-8")
print(f"Written upgraded scene to {out_path}")
