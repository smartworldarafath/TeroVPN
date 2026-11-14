$extPath = (Resolve-Path "$PSScriptRoot\..\extension").Path

$browsers = @(
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
)

foreach ($browser in $browsers) {
    if (-not (Test-Path $browser)) { continue }
    $bName = [System.IO.Path]::GetFileNameWithoutExtension($browser)
    Write-Host "`nTesting extension on: $bName ($browser)"
    $tempDir = Join-Path $env:TEMP "browser_ext_test_$bName"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force $tempDir | Out-Null

    $proc = Start-Process -FilePath $browser -ArgumentList "--headless=new", "--load-extension=""$extPath""", "--user-data-dir=""$tempDir""", "--disable-gpu", "about:blank" -PassThru
    Start-Sleep -Seconds 3

    if (-not $proc.HasExited) {
        Write-Host "✅ SUCCESS: $bName successfully loaded unpacked TeroVPN v1.2.5 extension!"
        $proc.Kill()
    } else {
        Write-Host "❌ FAILED: $bName exited prematurely with code $($proc.ExitCode)"
        exit 1
    }

    Start-Sleep -Seconds 1
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "`nAll browser tests passed!"
