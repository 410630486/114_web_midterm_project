$files = @('fox','tiger','wolf','hippo','kangaroo')
$srcDir = "assets/animal"

foreach ($id in $files) {
    $src = Join-Path $srcDir ($id + '.jpg')
    if (Test-Path $src) {
        try {
            Write-Output "Processing: $src"
            $img = [System.Drawing.Image]::FromFile($src)
            $sizes = @{ small = 480; medium = 1024; large = 1920 }
            foreach ($k in $sizes.Keys) {
                $nw = $sizes[$k]
                $out = Join-Path $srcDir ($id + '-' + $k + '.jpg')
                if ($img.Width -le $nw) {
                    Copy-Item $src -Destination $out -Force
                    Write-Output "Copied original to $out (source smaller than target width)"
                } else {
                    $ratio = $nw / $img.Width
                    $nh = [int]($img.Height * $ratio)
                    $thumb = New-Object System.Drawing.Bitmap $nw, $nh
                    $g = [System.Drawing.Graphics]::FromImage($thumb)
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $g.DrawImage($img, 0,0, $nw, $nh)
                    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
                    $encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
                    $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, 85L)
                    $thumb.Save($out, $codec, $encParams)
                    $g.Dispose()
                    $thumb.Dispose()
                    Write-Output "Saved resized $out"
                }
            }
            $img.Dispose()
        } catch {
            Write-Output "Failed processing $src : $_"
        }
    } else {
        Write-Output "Source not found: $src"
    }
}
Write-Output "Done"
