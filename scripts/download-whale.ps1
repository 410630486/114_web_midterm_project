# Download a whale image from Wikimedia Commons and update data/animals.json + ATTRIBUTION.md
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$dataPath = Join-Path $projectRoot 'data/animals.json'
$attrPath = Join-Path $projectRoot 'ATTRIBUTION.md'
$assetsDir = Join-Path $projectRoot 'assets/animal'
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }

Write-Output "Loading animals from $dataPath"
$raw = Get-Content $dataPath -Raw
$animals = $raw | ConvertFrom-Json

$targetId = 'whale'
$animal = $animals | Where-Object { $_.id -eq $targetId }
if (-not $animal) { Write-Error "No animal with id '$targetId' found in data." ; exit 1 }

$searchTerms = @()
if ($animal.latin) { $searchTerms += $animal.latin }
if ($animal.name) { $searchTerms += $animal.name }
$searchTerms += $targetId

$found = $false
foreach ($term in $searchTerms) {
    Write-Output "Searching Wikimedia for: $term"
    Start-Sleep -Milliseconds 600
    $enc = [System.Web.HttpUtility]::UrlEncode($term)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$enc&gsrlimit=15&gsrnamespace=6&prop=imageinfo&iiprop=url|extmetadata&formatversion=2"
    try {
        $resp = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 30
    } catch {
        Write-Output "API request failed for '$term': $_"
        continue
    }
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
                $outPath = Join-Path $assetsDir ($targetId + '.jpg')
                try {
                    Write-Output "  Candidate: $fileUrl (author: $author, license: $license)"
                    Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing -TimeoutSec 60
                    if (Test-Path $outPath) {
                        $size = (Get-Item $outPath).Length
                        Write-Output "  Downloaded to $outPath ($size bytes)"
                        # update data
                        $animal.image = "assets/animal/$($targetId).jpg"
                        $animals | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath -Encoding UTF8
                        # append attribution
                        $entry = "`n---`n`n$($animal.name) image (assets/animal/$targetId.jpg)`n`n- Source page: $pageUrl`n- Direct file URL: $fileUrl`n- Author: $author`n- License: $license`n`nNotes: downloaded and saved locally for the project; please retain attribution when reusing.`n"
                        Add-Content -Path $attrPath -Value $entry
                        Write-Output "Updated data and ATTRIBUTION.md"
                        $found = $true
                        break
                    }
                } catch {
                    Write-Output "  Download failed: $_"
                    if (Test-Path $outPath) { Remove-Item $outPath -ErrorAction SilentlyContinue }
                }
            }
        }
    }
    if ($found) { break }
}
if (-not $found) { Write-Output "No suitable Wikimedia file found for whale." }
else { Write-Output "Done." }
