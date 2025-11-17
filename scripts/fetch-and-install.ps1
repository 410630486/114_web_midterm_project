param(
    [Parameter(Mandatory=$true)][string]$Url,
    [Parameter(Mandatory=$true)][string]$Dst,
    [string]$Title = "",
    [string]$PageUrl = "",
    [string]$Author = "(unknown)",
    [string]$License = "(unknown)"
)

$Temp = Join-Path $PWD ("temp_download_{0}{1}" -f ([guid]::NewGuid().ToString()), ([io.path]::GetExtension($Url)))
Write-Output "Downloading $Url -> $Temp"
try {
    Invoke-WebRequest -Uri $Url -OutFile $Temp -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
} catch {
    Write-Error "Download failed: $_"
    exit 2
}

try {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($Temp)
    $w = $img.Width; $h = $img.Height
    $img.Dispose()
} catch {
    if (Test-Path $Temp) { Remove-Item $Temp -Force }
    Write-Error "INVALID_IMAGE: $_"
    exit 3
}

# ensure destination dir
$dir = Split-Path $Dst
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

Move-Item -Force -Path $Temp -Destination $Dst

# append attribution
$block = @()
$block += "---"
if ($Title -ne "") { $block += "$Title image ($Dst)" } else { $block += "Image ($Dst)" }
if ($PageUrl -ne "") { $block += "- Source page: $PageUrl" }
$block += "- Direct file URL: $Url"
$block += "- Author: $Author"
$block += "- License: $License"
$block += "- Notes: downloaded and saved locally for the project; please retain attribution when reusing." 
$block += ""

$attribPath = Join-Path $PWD 'ATTRIBUTION.md'
$block | Out-File -FilePath $attribPath -Encoding utf8 -Append

Write-Output ("INSTALLED {0} ({1}x{2})" -f $Dst, $w, $h)
exit 0
