#Requires -Version 5.1
<#
.SYNOPSIS
  Post-clone project setup: create AGENTS.local.md pointer + gitignore .tkdev-env.
  Run AFTER the repo has been cloned directly into the project's .tkdev-env\ .
  (There is NO separate toolbox copy - the clone IS the environment.)
.PARAMETER Target
  Project root (default: current working directory).
#>
param([string]$Target = ".")
$ErrorActionPreference = "Continue"

if (-not (Test-Path $Target)) { Write-Host "[x] target not found: $Target" -ForegroundColor Red; exit 1 }
$Target = (Resolve-Path $Target).Path
Write-Host "=== setup project: $Target ===" -ForegroundColor Cyan

# ---------- 1. create AGENTS.local.md pointer (local overlay, not the client's AGENTS.md) ----------
$localPointer = Join-Path $Target "AGENTS.local.md"
if (-not (Test-Path $localPointer)) {
  $ptr = "# Local dev workflow pointer (machine-local, do not commit)`n# This project uses the tkdev suite in .tkdev-env\`n# When the user says /tkdev or a dev task, read .tkdev-env\AGENTS.md (routing),`n# then .tkdev-env\skills\<name>\SKILL.md.`n# Code map (AOCI): use /aoci <path> to bind this repo, then aoci_* tools.`n"
  Set-Content -Path $localPointer -Value $ptr -Encoding UTF8
  Write-Host "[ok] AGENTS.local.md created." -ForegroundColor Green
} else {
  Write-Host "[ok] AGENTS.local.md already exists - skip." -ForegroundColor Green
}

# ---------- 2. gitignore .tkdev-env + AGENTS.local.md ----------
$gitignore = Join-Path $Target ".gitignore"
if (-not (Test-Path $gitignore)) { New-Item -ItemType File -Path $gitignore | Out-Null }
$gi = Get-Content $gitignore -Raw -ErrorAction SilentlyContinue
if ($null -eq $gi) { $gi = "" }
$added = @()
if ($gi -notmatch '\.tkdev-env') { Add-Content -Path $gitignore -Value "`n# tkdev suite (tooling, not project code)`n.tkdev-env/`n" -Encoding UTF8; $added += ".tkdev-env/" }
if ($gi -notmatch 'AGENTS\.local\.md') { Add-Content -Path $gitignore -Value "`n# local tkdev pointer`nAGENTS.local.md`n" -Encoding UTF8; $added += "AGENTS.local.md" }
if ($added.Count -gt 0) { Write-Host "[ok] gitignored: $($added -join ', ')" -ForegroundColor Green }
else { Write-Host "[ok] .gitignore already up to date." -ForegroundColor Green }

Write-Host ""
Write-Host "[done] setup complete. Next: run /aoci <project path> to bind the code map, then restart DSH." -ForegroundColor Green
