# Downloads images referenced in data/animals.json into assets/animal and updates the JSON to point to the local files.
# Usage: pwsh ./scripts/download_and_update_images.ps1

$ErrorActionPreference = 'Continue'

$dataPath = "data/animals.json"
$outDir = "assets/animal"

if (!(Test-Path $dataPath)) {
    Write-Error "Cannot find $dataPath"
    exit 1
}

# create output dir
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$json = Get-Content $dataPath -Raw | ConvertFrom-Json

$results = @()

function Get-ExtensionFromUrl($url) {
    try {
        $u = [uri]$url
        $seg = $u.Segments[-1]
        $seg = ($seg -split '\\?')[0]
        if ($seg -match '\.(jpg|jpeg|png|gif|svg|webp)$') { return $matches[0] }
    } catch {}
    return $null
}

# fallback extension
$defaultExt = '.jpg'

foreach ($item in $json) {
    $id = $item.id
    $img = $item.image
    if (-not $img) { $results += @{ id=$id; status='no-image'; msg='no image url'; }; continue }
    if ($img -like 'assets/*') { $results += @{ id=$id; status='skip-local'; path=$img }; continue }

    $ext = Get-ExtensionFromUrl $img
    if (-not $ext) { $ext = $defaultExt }

    $fname = "${id}${ext}"
    $outfile = Join-Path $outDir $fname

    # attempt download with retries
    $ok = $false
    $attempt = 0
    while (-not $ok -and $attempt -lt 3) {
        try {
            $attempt++
            Write-Host "Downloading $img -> $outfile (attempt $attempt)"
            Invoke-WebRequest -Uri $img -OutFile $outfile -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0 (compatible; 114_web_midterm_project/1.0)' } -TimeoutSec 30
            $ok = $true
        } catch {
            Write-Warning ("failed attempt {0} for {1}: {2}" -f $attempt, $id, $_.Exception.Message)
            Start-Sleep -Seconds (2 * $attempt)
        }
    }
    if ($ok) {
        # set to forward-slash path
        $localPath = "$outDir/$fname"
        $item.image = $localPath
        $results += @{ id=$id; status='downloaded'; path=$localPath }
    } else {
        $results += @{ id=$id; status='failed'; msg="failed to download after attempts" }
    }
}

# write back JSON (pretty)
try {
    $json | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath -Encoding UTF8
    Write-Host "Updated $dataPath with local image paths."
} catch {
    Write-Error "Failed to write updated JSON: $($_.Exception.Message)"
}

# output summary
$summary = $results | Group-Object -Property status | ForEach-Object { "$($_.Name): $($_.Count)" }
Write-Host "Summary:`n$($summary -join "`n")"

# also write a small CSV of results for review
$csvPath = "scripts/download_results.csv"
$results | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $csvPath -Encoding UTF8
Write-Host "Wrote results to $csvPath"
