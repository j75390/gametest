@echo off
setlocal
set "GAME_PROJECT=%~1"
if "%GAME_PROJECT%"=="" set "GAME_PROJECT=%~dp0"
"D:\Comfy-Desktop\ComfyUI-Installs\ComfyUI\standalone-env\python.exe" "%GAME_PROJECT%\tools\generate_characters.py"
exit /b %errorlevel%
