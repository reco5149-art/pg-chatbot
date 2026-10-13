# 배포 전 점검 (읽기만 함, 아무것도 올리지 않음)
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
function Show($name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if ($c) { Write-Host "[OK] $name : $($c.Source)" } else { Write-Host "[없음] $name" }
  return [bool]$c
}
$hasGit = Show "git"
$hasGh  = Show "gh"
if (-not $hasGh) {
  foreach ($p in @("$env:ProgramFiles\GitHub CLI\gh.exe", "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe")) {
    if (Test-Path $p) { Write-Host "  (PATH에는 없지만 설치됨: $p)" }
  }
}
if ($hasGit) {
  git --version
  Write-Host "git user.name  = $(git config --global user.name)"
  Write-Host "git user.email = $(git config --global user.email)"
}
if ($hasGh) {
  gh --version | Select-Object -First 1
  Write-Host "--- gh auth status ---"
  gh auth status 2>&1
  Write-Host "gh auth exit = $LASTEXITCODE"
}
node -v
Write-Host "pg-docs.json: $(Test-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'app\public\pg-docs.json'))"
Write-Host "점검 끝"
