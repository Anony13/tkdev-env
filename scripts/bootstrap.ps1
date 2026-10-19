#Requires -Version 5.1
<#
.SYNOPSIS
  Machine-level bootstrap (run ONCE per machine): install aoci.exe + install the
  dsh-aoci plugin. Idempotent.
.DESCRIPTION
  1. scripts/install-aoci.ps1  -> download + verify aoci.exe
  2. dsh plugin add ./dist/dsh-aoci-0.2.6.tgz  -> install the AOCI plugin
#>
param(
  [string]$Aoci = "C:\aoci\bin\aoci.exe",
  [string]$Profile = "desktop"
)
$ErrorActionPreference = "Continue"
$repoRoot = Split-Path $PSScriptRoot -Parent

Write-Host "=== 1/2 install aoci.exe ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "install-aoci.ps1") -Aoci $Aoci

Write-Host ""
Write-Host "=== 2/2 install dsh-aoci plugin ===" -ForegroundColor Cyan
$tgz = Join-Path $repoRoot "dist\dsh-aoci-0.2.6.tgz"
if (-not (Test-Path $tgz)) {
  Write-Host "[x] plugin tarball not found: $tgz (run 'npm install && npm run build && npm pack' in dsh-aoci/ first)" -ForegroundColor Red
  exit 1
}
$dshCmd = Join-Path $env:LOCALAPPDATA "Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd"
if (-not (Test-Path $dshCmd)) {
  Write-Host "[x] dsh CLI not found at: $dshCmd" -ForegroundColor Red
  exit 1
}
Write-Host "[*] dsh plugin --profile $Profile add $tgz" -ForegroundColor DarkGray
& $dshCmd plugin --profile $Profile add $tgz 2>&1
Write-Host "[done] bootstrap finished. Restart DSH, then use /aoci <path> per project." -ForegroundColor Green



