@echo off
setlocal
set "MIKO_GODOT=%~dp0..\Godot_v4.7.2-stable_win64.exe"
if not exist "%MIKO_GODOT%" exit /b 1
start "MIKO - Freight Security" "%MIKO_GODOT%" --path "%~dp0Game" --windowed --resolution 1920x1080 res://scenes/miko7_patrol_yard.tscn
