@echo off
cd /d "%~dp0"
rem First run: let Godot import the project (script classes) before starting the game.
if not exist ".godot\imported" (
  "C:\Users\ysyki\Godot\Godot_console.exe" --headless --path . --import
)
start "" "C:\Users\ysyki\Godot\Godot.exe" --path .
