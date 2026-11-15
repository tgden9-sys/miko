@echo off
setlocal
set "MIKO_GODOT=%~dp0..\Godot_v4.7.2-stable_win64.exe"
if not exist "%MIKO_GODOT%" exit /b 1
start "MIKO Level 2" "%MIKO_GODOT%" --path "%~dp0MovementLab" --windowed --disable-vsync --resolution 1600x900 res://lab_level_2.tscn
