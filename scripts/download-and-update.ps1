# Downloads external images referenced in data/animals.json using Wikimedia Commons API.
# For each animal with an external image URL, try searches by latin name, then english name/id.
# Downloads to assets/animal/<id>.jpg, updates data/animals.json, and appends attribution to ATTRIBUTION.md.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# project root is parent of scripts directory
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$dataPath = Join-Path $projectRoot 'data/animals.json'
$attrPath = Join-Path $projectRoot 'ATTRIBUTION.md'
$assetsDir = Join-Path $projectRoot 'assets/animal'

if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir | Out-Null }

Write-Output "Loading animals from $dataPath"
$raw = Get-Content $dataPath -Raw
$animals = $raw | ConvertFrom-Json

$modified = $false
$counter = 0

function Append-Attr([string]$title, [string]$pageUrl, [string]$fileUrl, [string]$author, [string]$license) {
    $entry = "`n---`n`n$title`n`n- Source page: $pageUrl`n- Direct file URL: $fileUrl`n- Author: $author`n- License: $license`n`nNotes: downloaded and saved locally for the project; please retain attribution when reusing.`n"
    Add-Content -Path $attrPath -Value $entry
}

foreach ($animal in $animals) {
    $id = $animal.id
    $img = $animal.image
    if ($img -and $img -match '^https?://') {
        $counter++
        Write-Output "[$counter] Processing $id (searching for local copy)"
        $searchTerms = @()
        if ($animal.latin) { $searchTerms += $animal.latin }
        if ($animal.name) { $searchTerms += $animal.name }
        $searchTerms += $id

        $found = $false
        foreach ($term in $searchTerms) {
            Start-Sleep -Milliseconds 600
            $enc = [System.Web.HttpUtility]::UrlEncode($term)
            # restrict search to File namespace (6) so we find file pages directly; increase limit
            $api = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$enc&gsrlimit=10&gsrnamespace=6&prop=imageinfo&iiprop=url|extmetadata&formatversion=2"
            try {
                $resp = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 30
            } catch {
                Write-Output "  API request failed for '$term': $_"
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
                        # Attempt download
                        $outPath = Join-Path $assetsDir ($id + '.jpg')
                        try {
                            Write-Output "  Found candidate: $fileUrl (author: $author, license: $license)"
                            Invoke-WebRequest -Uri $fileUrl -OutFile $outPath -UseBasicParsing -TimeoutSec 60
                            if (Test-Path $outPath) {
                                $size = (Get-Item $outPath).Length
                                Write-Output "  Downloaded to $outPath ($size bytes)"
                                # Update JSON field
                                $animal.image = "assets/animal/$id.jpg"
                                $modified = $true
                                # Append attribution
                                Append-Attr("$($animal.name) image (assets/animal/$id.jpg)", $pageUrl, $fileUrl, $author, $license)
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
        if (-not $found) { Write-Output "  No Wikimedia candidate found for $id (tried: $($searchTerms -join ', '))" }
    }
}

if ($modified) {
    Write-Output "Writing updated data/animals.json"
    $animals | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath -Encoding UTF8
    Write-Output "Note: image resizing/variant generation skipped per user request."
} else {
    Write-Output "No changes made; no external images found or downloaded."
}

Write-Output "All done."
