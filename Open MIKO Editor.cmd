@echo off
set "MIKO_GODOT=%~dp0..\Godot_v4.7.2-stable_win64.exe"
if not exist "%MIKO_GODOT%" (
  echo Godot was not found beside the MIKO folder. Open Game\project.godot in Godot 4.7.2.
  pause
  exit /b 1
)
start "" "%MIKO_GODOT%" --editor --path "%~dp0Game"
