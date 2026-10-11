@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Projects\logs\scripts\godot_dev.ps1" player --editor --path "D:\Projects\Game\Project_T"
if errorlevel 1 pause
