#Requires -Version 5.1
<#
.SYNOPSIS
  Download + verify aoci.exe from the official release (idempotent).
.PARAMETER Aoci
  Target path (default C:\aoci\bin\aoci.exe).
#>
param([string]$Aoci = "C:\aoci\bin\aoci.exe")
$ErrorActionPreference = "Continue"

$VERSION = "0.1.0-rc21"
$SHA256  = "d7a34e5f419b8f8be56739e9b4e9a772019950aecd159539f6a94c9d6b499665"
$ASSET   = "aoci_0.1.0-rc21_windows_amd64.zip"
$URL     = "https://github.com/aoci-spec/aoci-code/releases/download/v0.1.0-rc21/$ASSET"

if (Test-Path $Aoci) {
  Write-Host "[ok] aoci.exe already at $Aoci" -ForegroundColor Green
  & $Aoci --version
  exit 0
}

$binDir = Split-Path $Aoci
$dlDir  = Join-Path $binDir "download"
New-Item -ItemType Directory -Force $binDir, $dlDir | Out-Null
$zip = Join-Path $dlDir $ASSET

$ok = $false
foreach ($u in @("https://gh-proxy.com/$URL", $URL)) {
  Write-Host "[*] downloading $u" -ForegroundColor DarkGray
  & curl.exe -sSL --ssl-no-revoke --connect-timeout 10 --max-time 180 -o $zip $u 2>$null
  if ($LASTEXITCODE -eq 0 -and (Test-Path $zip)) {
    $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash.ToLower()
    if ($h -eq $SHA256) { $ok = $true; break } else { Write-Host "[!] sha256 mismatch ($h)" -ForegroundColor DarkGray }
  }
}
if (-not $ok) {
  Write-Host "[x] download failed. Install aoci.exe manually to $Aoci (official release v$VERSION)." -ForegroundColor Red
  exit 1
}
Expand-Archive -Path $zip -DestinationPath $binDir -Force
Write-Host "[ok] aoci.exe installed: $Aoci" -ForegroundColor Green
& $Aoci --version
