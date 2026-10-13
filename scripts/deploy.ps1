# 피지컬그라운드 안내 챗봇 — GitHub에 올리고 GitHub Pages로 배포 (처음 한 번)
# 사용법 (저장소 폴더에서): powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1
# 이후 수정은 git add / commit / push 만 하면 GitHub Actions가 다시 배포합니다.
# 외부 명령(npm, ollama, git)은 진행 표시를 stderr로 쓰므로 Stop 대신 종료 코드로 직접 확인한다
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root  = Split-Path -Parent $PSScriptRoot
$Owner = "reco5149-art"
$Repo  = "pg-chatbot"
function Stop-With($msg) { Write-Host "[중단] $msg" -ForegroundColor Red; exit 1 }
function Step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
Set-Location $Root

Step "1. 확인"
foreach ($cmd in @("git", "gh", "node")) { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Stop-With "$cmd 가 없습니다. gh는 https://cli.github.com 에서 설치하세요." } }
gh auth status 2>$null; if ($LASTEXITCODE -ne 0) { Stop-With "GitHub 로그인이 필요합니다: gh auth login" }
if (-not (Test-Path "app\public\pg-docs.json")) { Stop-With "자료 벡터(app\public\pg-docs.json)가 없습니다. scripts\dev.ps1 → /embed.html 에서 먼저 만드세요." }

Step "2. 배포 전 빌드 시험"
Push-Location app
if (-not (Test-Path "node_modules")) { npm install --no-audit --no-fund }
npm run build; if ($LASTEXITCODE -ne 0) { Pop-Location; Stop-With "빌드 실패 — 오류를 고친 뒤 다시 실행하세요." }
Pop-Location

Step "3. 커밋"
if (-not (Test-Path ".git")) { git init -b main | Out-Null }
git add -A
git diff --cached --quiet; if ($LASTEXITCODE -ne 0) { git commit -m "피지컬그라운드 안내 챗봇 제출" | Out-Null }

Step "4. GitHub 저장소 ($Owner/$Repo)"
gh repo view "$Owner/$Repo" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    gh repo create "$Owner/$Repo" --public --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) { Stop-With "저장소 생성 실패" }
} else {
    if (-not (git remote | Select-String -Quiet "^origin$")) { git remote add origin "https://github.com/$Owner/$Repo.git" }
    git push -u origin main
    if ($LASTEXITCODE -ne 0) { Stop-With "push 실패" }
}

Step "5. Pages 설정 (GitHub Actions로 배포)"
gh api "repos/$Owner/$Repo/pages" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { gh api -X POST "repos/$Owner/$Repo/pages" -f build_type=workflow | Out-Null }
else { gh api -X PUT "repos/$Owner/$Repo/pages" -f build_type=workflow | Out-Null }
gh workflow run deploy.yml 2>$null | Out-Null

Write-Host "`n완료. 배포는 1~3분 걸립니다. 진행 상황: gh run watch" -ForegroundColor Green
Write-Host "배포 주소: https://$Owner.github.io/$Repo/" -ForegroundColor Green
Write-Host "배포 주소에서 쓰려면 사용자 환경 변수 OLLAMA_ORIGINS = https://$Owner.github.io 를 넣고 Ollama를 다시 켜세요." -ForegroundColor Yellow
