@echo off
setlocal
set "MIKO_GODOT=%~dp0..\Godot_v4.7.2-stable_win64.exe"
if not exist "%MIKO_GODOT%" (
    echo Could not find Godot beside the MIKO folder.
    pause
    exit /b 1
)
start "MIKO7" "%MIKO_GODOT%" --path "%~dp0Game" --windowed --resolution 1920x1080
