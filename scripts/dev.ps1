# 피지컬그라운드 안내 챗봇 — 내 PC에서 개발 서버로 실행 (Windows PowerShell)
# 사용법 (저장소 폴더에서): powershell -ExecutionPolicy Bypass -File .\scripts\dev.ps1
# 외부 명령(npm, ollama, git)은 진행 표시를 stderr로 쓰므로 Stop 대신 종료 코드로 직접 확인한다
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Root = Split-Path -Parent $PSScriptRoot
$Model = "qwen3.5:2b"
function Stop-With($msg) { Write-Host "[중단] $msg" -ForegroundColor Red; exit 1 }
function Step($msg) { Write-Host "`n▶ $msg" -ForegroundColor Cyan }

Step "도구 확인"
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Stop-With "Node.js가 설치되어 있지 않습니다. https://nodejs.org 에서 LTS를 설치하세요." }
# ollama 명령: PATH에 없으면 기본 설치 위치도 찾아본다 (설치 직후에는 PATH가 아직 반영되지 않았을 수 있음)
$OllamaExe = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if (-not $OllamaExe) {
    foreach ($guess in @((Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"), (Join-Path $env:ProgramFiles "Ollama\ollama.exe"))) {
        if (Test-Path $guess) { $OllamaExe = $guess; break }
    }
}
if ($OllamaExe) { Write-Host "  ollama: $OllamaExe" } else { Write-Host "  ollama 실행 파일을 찾지 못했습니다" -ForegroundColor Yellow }
$v = (node -v).TrimStart("v").Split(".") | ForEach-Object { [int]$_ }
if (-not (($v[0] -eq 20 -and $v[1] -ge 19) -or ($v[0] -eq 22 -and $v[1] -ge 12) -or ($v[0] -gt 22))) { Stop-With "Node $(node -v) — Vite 8은 20.19 이상(22는 22.12 이상)이 필요합니다." }

Step "Ollama와 모델 확인"
function Get-OllamaTags { try { Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop } catch { $null } }
$tags = Get-OllamaTags
if (-not $tags) {
    if (-not $OllamaExe) { Stop-With "Ollama가 설치되어 있지 않습니다. https://ollama.com/download 에서 Windows용을 설치한 뒤 다시 실행하세요." }
    # 설치는 되어 있는데 꺼져 있으면 직접 켠다
    Write-Host "  Ollama가 꺼져 있어 켭니다…"
    $app = Join-Path (Split-Path $OllamaExe) "ollama app.exe"
    if (Test-Path $app) { Start-Process $app } else { Start-Process $OllamaExe -ArgumentList "serve" -WindowStyle Hidden }
    for ($i = 0; $i -lt 15 -and -not $tags; $i++) { Start-Sleep 2; $tags = Get-OllamaTags }
    if (-not $tags) { Stop-With "Ollama를 켜지 못했습니다. 시작 메뉴에서 Ollama를 직접 실행한 뒤 다시 시도하세요." }
}
if (-not (@($tags.models | ForEach-Object { $_.name }) -contains $Model)) {
    if (-not $OllamaExe) { Stop-With "$Model 모델이 없습니다. 새 PowerShell 창에서 ollama pull $Model 을 실행하세요." }
    Write-Host "  $Model 모델을 내려받습니다 (처음 한 번, 몇 분 걸릴 수 있음)"
    & $OllamaExe pull $Model
    if ($LASTEXITCODE -ne 0) { Stop-With "ollama pull $Model 실패" }
}
Write-Host "  Ollama 연결됨 · $Model 준비됨"

Set-Location (Join-Path $Root "app")
if (-not (Test-Path "node_modules")) { Step "npm install (처음 한 번)"; npm install --no-audit --no-fund; if ($LASTEXITCODE -ne 0) { Stop-With "npm install 실패" } }

$page = if (Test-Path "public\pg-docs.json") { "http://localhost:5173/" } else { "http://localhost:5173/embed.html" }
if ($page -like "*embed*") { Write-Host "  자료 벡터(public\pg-docs.json)가 아직 없어 벡터 만들기 페이지를 엽니다. '벡터 만들기 시작'을 누르세요." -ForegroundColor Yellow }
Step "개발 서버 실행 — 이 창을 닫으면 꺼집니다 (Ctrl+C)"
Start-Job -ArgumentList $page { param($u) Start-Sleep 4; Start-Process "chrome" $u } | Out-Null
npx vite --port 5173
