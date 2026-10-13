@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0scripts\check-deploy.ps1' *>&1 | Tee-Object -FilePath '%~dp0logs\check-deploy.txt'"
echo.
echo Press any key to close this window.
pause >nul
