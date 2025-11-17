# Re-fetch better photos for gorilla, salamander, pangolin
$targets = @(
    @{ id='gorilla'; extraTerms=@('Gorilla gorilla','gorilla male portrait','gorilla photo') },
    @{ id='salamander'; extraTerms=@('salamander','Salamandridae','salamander photo') },
    @{ id='pangolin'; extraTerms=@('pangolin','Manis','pangolin photo') }
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$dataPath = Join-Path $projectRoot 'data/animals.json'
$attrPath = Join-Path $projectRoot 'ATTRIBUTION.md'
$assetsDir = Join-Path $projectRoot 'assets/animal'

$raw = Get-Content $dataPath -Raw
$animals = $raw | ConvertFrom-Json

function Append-Attr([string]$title, [string]$pageUrl, [string]$fileUrl, [string]$author, [string]$license) {
    $entry = "`n---`n`n$title`n`n- Source page: $pageUrl`n- Direct file URL: $fileUrl`n- Author: $author`n- License: $license`n`nNotes: UPDATED — replaced incorrect image; please retain attribution when reusing.`n"
    Add-Content -Path $attrPath -Value $entry
}

function Is-BadCandidate($page, $ii, $fileUrl) {
    $badExt = @('.pdf','.svg','.tif','.tiff','.psd')
    foreach ($ext in $badExt) { if ($fileUrl.ToLower().EndsWith($ext)) { return $true } }
    $lower = ($page.title + ' ' + $fileUrl).ToLower()
    $badKeywords = @('map','range','distribution','diagram','chart','graph','genera','mapa','distribution_map')
    foreach ($kw in $badKeywords) { if ($lower -like "*${kw}*") { return $true } }
    return $false
}

foreach ($t in $targets) {
    $id = $t.id
    $animal = $animals | Where-Object { $_.id -eq $id }
    if (-not $animal) { Write-Output "No animal entry for $id"; continue }
    Write-Output "`n== Re-fetching $id ($($animal.name)) =="
    $found = $false
    $searchTerms = @()
    if ($animal.latin) { $searchTerms += $animal.latin }
    $searchTerms += $t.extraTerms
    $searchTerms += $animal.name

    foreach ($term in $searchTerms) {
        Start-Sleep -Milliseconds 500
        $enc = [System.Web.HttpUtility]::UrlEncode($term)
        $api = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$enc&gsrlimit=30&gsrnamespace=6&prop=imageinfo&iiprop=url|extmetadata&formatversion=2"
        try { $resp = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 30 } catch { Write-Output ("API error for {0}: {1}" -f $term, $_); continue }
        if ($resp.query -and $resp.query.pages) {
            $candidates = @()
            foreach ($page in $resp.query.pages) {
                if ($page.imageinfo -and $page.imageinfo.Count -gt 0) {
                    $ii = $page.imageinfo[0]
                    $url = $ii.url
                    if (Is-BadCandidate $page $ii $url) { continue }
                    $width = 0
                    if ($ii.extmetadata -and $ii.extmetadata.ImageWidth -and $ii.extmetadata.ImageWidth.value) { [int]$width = $ii.extmetadata.ImageWidth.value }
                    $isJpg = $url.ToLower().EndsWith('.jpg') -or $url.ToLower().EndsWith('.jpeg')
                    $candidates += [pscustomobject]@{ page=$page; ii=$ii; url=$url; width=$width; isJpg=$isJpg }
                }
            }
            $ordered = $candidates | Sort-Object @{Expression = { -not $_.isJpg } }, @{Expression = { -($_.width) } }
            foreach ($cand in $ordered) {
                $page = $cand.page; $ii = $cand.ii; $fileUrl = $cand.url
                $pageUrl = "https://commons.wikimedia.org/wiki/File:" + ($page.title -replace ' ', '_')
                $author = '(unknown)'; $license='(unknown)'
                if ($ii.extmetadata) {
                    if ($ii.extmetadata.Artist -and $ii.extmetadata.Artist.value) { $author = $ii.extmetadata.Artist.value -replace '<.*?>','' }
                    if ($ii.extmetadata.LicenseShortName -and $ii.extmetadata.LicenseShortName.value) { $license = $ii.extmetadata.LicenseShortName.value }
                }
                $outPath = Join-Path $assetsDir ($id + '.jpg')
                try {
                    Write-Output " Trying candidate: $fileUrl (author: $author, license: $license)"
                    Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing -TimeoutSec 60
                    if (Test-Path $outPath) {
                        try { $img = [System.Drawing.Image]::FromFile($outPath); $img.Dispose(); Write-Output "  Downloaded & validated: $outPath"; $animal.image = "assets/animal/$id.jpg"; Append-Attr("$($animal.name) image (assets/animal/$id.jpg)", $pageUrl, $fileUrl, $author, $license); $found=$true; break } catch { Write-Output "  Not a valid image, removing: $outPath"; Remove-Item $outPath -ErrorAction SilentlyContinue; continue }
                    }
                } catch { Write-Output ("  Download failed: {0}" -f $_) }
            }
        }
        if ($found) { break }
    }
    if (-not $found) { Write-Output " No usable candidate found for $id" }
}
# write back data.json
$animals | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath -Encoding UTF8
Write-Output "Done."
