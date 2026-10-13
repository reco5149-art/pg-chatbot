@echo off
chcp 65001 >nul
echo GitHub CLI 로그인을 시작합니다.
echo 1) 아래에 나오는 8자리 코드(XXXX-XXXX)를 확인하세요.
echo 2) Enter를 누르면 브라우저가 열립니다. 코드를 붙여넣고 Authorize를 누르세요.
echo.
gh auth login --hostname github.com --git-protocol https --web
echo.
gh auth status
echo.
echo Press any key to close this window.
pause >nul
