@echo off
chcp 65001 >nul
cd /d "%~dp0"
rem Shows messages here and also saves them to logs\start-HHmmss.txt
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = '%~dp0logs\start-' + (Get-Date -Format HHmmss) + '.txt'; & '%~dp0scripts\dev.ps1' *>&1 | Tee-Object -FilePath $f"
echo.
echo Press any key to close this window.
pause >nul
