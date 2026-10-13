@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
gh auth status >nul 2>&1
if errorlevel 1 (
  echo GitHub 로그인이 아직 안 되어 있어서 로그인부터 합니다.
  echo 8자리 코드를 확인하고 Enter, 브라우저에 코드를 넣고 Authorize github 클릭
  echo.
  gh auth login --hostname github.com --git-protocol https --web
  gh auth status >nul 2>&1
  if errorlevel 1 (
    echo.
    echo 로그인이 끝나지 않았어요. 창을 닫고 deploy.bat 을 다시 실행해 주세요.
    pause
    exit /b 1
  )
)
echo GitHub 로그인 확인됨. 배포를 시작합니다.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0scripts\deploy.ps1' *>&1 | Tee-Object -FilePath '%~dp0logs\deploy.txt'"
echo.
echo Press any key to close this window.
pause >nul
