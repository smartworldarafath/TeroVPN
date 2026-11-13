$ErrorActionPreference = 'Stop'

$extDir = Join-Path $PSScriptRoot "..\extension"
$outDir = Join-Path $PSScriptRoot "..\out"
$distDir = Join-Path $PSScriptRoot "..\dist"

New-Item -ItemType Directory -Force $outDir | Out-Null
New-Item -ItemType Directory -Force $distDir | Out-Null

$zipName = "TeroVPN-Chrome-Extension-v1.2.0.zip"
$outZip = Join-Path $outDir $zipName
$distZip = Join-Path $distDir $zipName

if (Test-Path $outZip) { Remove-Item $outZip -Force }
if (Test-Path $distZip) { Remove-Item $distZip -Force }

Write-Host "Creating extension package from $extDir..."
Compress-Archive -Path "$extDir\*" -DestinationPath $outZip -Force
Copy-Item $outZip $distZip -Force

$zipSize = (Get-Item $outZip).Length
Write-Host "Successfully packaged Chrome Extension:"
Write-Host " - Out: $outZip ($([math]::Round($zipSize / 1KB, 1)) KB)"
Write-Host " - Dist: $distZip ($([math]::Round($zipSize / 1KB, 1)) KB)"

# Verify ZIP structure
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($outZip)
Write-Host "`nVerifying ZIP archive entries ($($zip.Entries.Count) items):"
$manifestFound = $false
foreach ($entry in $zip.Entries) {
    if ($entry.FullName -eq 'manifest.json') {
        $manifestFound = $true
    }
}
$zip.Dispose()

if (-not $manifestFound) {
    Write-Error "manifest.json missing at root of zip!"
    exit 1
}

Write-Host "Verification successful: manifest.json is at root of archive."
