$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force extension/icons | Out-Null
Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "..\docs\branding\app_icon_light.png"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source icon not found at $srcPath"
    exit 1
}

$srcImg = [System.Drawing.Bitmap]::FromFile((Resolve-Path $srcPath))
$sizes = @(16, 32, 48, 128)

foreach ($size in $sizes) {
    $dest = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $size, $size)
    $g.Dispose()
    
    $outPath = Join-Path $PSScriptRoot "..\extension\icons\icon$size.png"
    $dest.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dest.Dispose()
    Write-Host "Generated $outPath (${size}x${size})"
}
$srcImg.Dispose()
Write-Host "Icon generation completed successfully."
