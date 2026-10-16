@echo off
cd /d "%~dp0"
rem Let Godot import the project (script classes) on the first run and
rem whenever scripts were added, moved or removed, then start the game.
if not exist ".godot" mkdir ".godot"
dir /s /b /on scripts\*.gd > ".godot\scripts_now.txt"
set NEED=0
if not exist ".godot\imported" set NEED=1
if not exist ".godot\scripts_seen.txt" set NEED=1
if %NEED%==0 fc /b ".godot\scripts_now.txt" ".godot\scripts_seen.txt" >NUL 2>&1 || set NEED=1
if %NEED%==1 (
  "C:\Users\ysyki\Godot\Godot_console.exe" --headless --path . --import
  copy /y ".godot\scripts_now.txt" ".godot\scripts_seen.txt" >NUL
)
start "" "C:\Users\ysyki\Godot\Godot.exe" --path .
