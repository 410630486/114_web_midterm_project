$ids=@('crane','armadillo','skunk','anteater','gorilla','salamander','pangolin','platypus')
foreach ($id in $ids) {
    $path=Join-Path 'assets/animal' ($id+'.jpg')
    if (-not (Test-Path $path)) { Write-Output "{0}: MISSING" -f $id; continue }
    try {
        $img=[System.Drawing.Image]::FromFile($path)
        $w=$img.Width; $h=$img.Height; $img.Dispose()
        Write-Output "{0}: OK ({1}x{2}) - {3}" -f $id,$w,$h,$path
    } catch {
        Write-Output "{0}: INVALID IMAGE - {1}" -f $id,$path
    }
}
