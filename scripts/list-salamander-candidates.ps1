# List Wikimedia Commons candidates for salamander (returns up to 10 candidates)
$termCandidates = @('Salamander','Caudata','Salamandridae')
$results = @()
foreach ($term in $termCandidates) {
    Write-Output "Searching for: $term"
    $enc = [System.Web.HttpUtility]::UrlEncode($term)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$enc&gsrlimit=20&gsrnamespace=6&prop=imageinfo&iiprop=url|extmetadata&formatversion=2"
    try { $resp = Invoke-RestMethod -Uri $api -UseBasicParsing -TimeoutSec 30 } catch { Write-Output ("API error for {0}: {1}" -f $term, $_); continue }
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
                $results += [pscustomobject]@{title=$page.title; pageUrl=$pageUrl; fileUrl=$fileUrl; author=$author; license=$license}
            }
        }
    }
    Start-Sleep -Milliseconds 300
}
# Deduplicate by fileUrl and show top 10
$unique = $results | Sort-Object -Property fileUrl -Unique | Select-Object -First 10
$count=0
foreach ($r in $unique) { $count++; Write-Output "[$count] Title: $($r.title)`n    Page: $($r.pageUrl)`n    File: $($r.fileUrl)`n    Author: $($r.author)`n    License: $($r.license)`n" }
Write-Output "Done. To pick a candidate, reply with the index number (e.g. 2) or 'auto' to pick the first photographic jpg."