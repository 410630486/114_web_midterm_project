# Fix specific animal images by re-downloading Wikimedia candidates and overwriting local files.
$ids = @('crane','armadillo','skunk','anteater','gorilla','salamander','pangolin','platypus')

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$dataPath = Join-Path $projectRoot 'data/animals.json'
$attrPath = Join-Path $projectRoot 'ATTRIBUTION.md'
$assetsDir = Join-Path $projectRoot 'assets/animal'

if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }

Write-Output "Loading animals from $dataPath"
$raw = Get-Content $dataPath -Raw
$animals = $raw | ConvertFrom-Json

function Append-Attr([string]$title, [string]$pageUrl, [string]$fileUrl, [string]$author, [string]$license) {
    $entry = "`n---`n`n$title`n`n- Source page: $pageUrl`n- Direct file URL: $fileUrl`n- Author: $author`n- License: $license`n`nNotes: UPDATED/OVERWRITTEN — downloaded and saved locally for the project; please retain attribution when reusing.`n"
    Add-Content -Path $attrPath -Value $entry
}

foreach ($id in $ids) {
    $animal = $animals | Where-Object { $_.id -eq $id }
    if (-not $animal) { Write-Output "No animal with id '$id' in data.json — skipping"; continue }
    Write-Output "\n=== Processing $id ($($animal.name)) ==="
    $searchTerms = @()
    if ($animal.latin) { $searchTerms += $animal.latin }
    if ($animal.name) { $searchTerms += $animal.name }
    $searchTerms += $id

    $found = $false
    foreach ($term in $searchTerms) {
        Start-Sleep -Milliseconds 500
        $enc = [System.Web.HttpUtility]::UrlEncode($term)
        $api = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$enc&gsrlimit=15&gsrnamespace=6&prop=imageinfo&iiprop=url|extmetadata&formatversion=2"
    try { $resp = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 30 } catch { Write-Output (" API error for {0}: {1}" -f $term, $_); continue }
        if ($resp.query -and $resp.query.pages) {
            foreach ($page in $resp.query.pages) {
                if ($page.imageinfo -and $page.imageinfo.Count -gt 0) {
                    $ii = $page.imageinfo[0]
                    $fileUrl = $ii.url
                    $pageUrl = "https://commons.wikimedia.org/wiki/File:" + ($page.title -replace ' ', '_')
                    $author = '(unknown)'
                    $license = '(unknown)'
                    if ($ii.extmetadata) {
                        if ($ii.extmetadata.Artist -and $ii.extmetadata.Artist.value) { $author = $ii.extmetadata.Artist.value -replace '<.*?>','' }
                        if ($ii.extmetadata.LicenseShortName -and $ii.extmetadata.LicenseShortName.value) { $license = $ii.extmetadata.LicenseShortName.value }
                    }
                    $outPath = Join-Path $assetsDir ($id + '.jpg')
                    try {
                        Write-Output "  Candidate: $fileUrl (author: $author, license: $license)"
                        Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing -TimeoutSec 60
                        if (Test-Path $outPath) {
                                $size = (Get-Item $outPath).Length
                                # validate image by attempting to load
                                try {
                                    $img = [System.Drawing.Image]::FromFile($outPath)
                                    $img.Dispose()
                                    Write-Output "  Downloaded and validated image: $outPath ($size bytes)"
                                    # ensure data.json image points to this local file
                                    $animal.image = "assets/animal/$id.jpg"
                                    $found = $true
                                    Append-Attr("$($animal.name) image (assets/animal/$id.jpg)", $pageUrl, $fileUrl, $author, $license)
                                    break
                                } catch {
                                    Write-Output ("  Downloaded file is not a valid image, removing and continuing: {0}" -f $outPath)
                                    Remove-Item $outPath -ErrorAction SilentlyContinue
                                    continue
                                }
                        }
                    } catch { Write-Output ("  Download failed for {0}: {1}" -f $outPath, $_); if (Test-Path $outPath) { Remove-Item $outPath -ErrorAction SilentlyContinue } }
                }
            }
        }
        if ($found) { break }
    }
    if (-not $found) { Write-Output "  No suitable Wikimedia candidate found for $id" }
}

# Write updated data.json (in case image field changed)
$animals | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath -Encoding UTF8
Write-Output "Fix script finished. Updated data and attribution where replacements occurred."