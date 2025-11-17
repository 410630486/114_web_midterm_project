# Install and validate downloaded salamander image
$src = "temp_salamander_MHNT_1.jpg"
$dst = "assets/animal/salamander.jpg"
if (-not (Test-Path $src)) {
    Write-Error "Source file not found: $src"
    exit 2
}
try {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($src)
    $size = (Get-Item $src).Length
    Write-Output "VALID_IMAGE ${($img.Width)}x${($img.Height)} ${size}bytes"
    $img.Dispose()
    # Ensure destination directory exists
    $dir = Split-Path $dst
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    # Move (overwrite)
    Move-Item -Force -Path $src -Destination $dst
    Write-Output "Moved to $dst"
    exit 0
} catch {
    Write-Error "INVALID_IMAGE $_"
    # remove invalid temp
    if (Test-Path $src) { Remove-Item $src -Force }
    exit 3
}