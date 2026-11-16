#requires -Version 7.0
<#
.SYNOPSIS
    Finds, checks, and adds wallpapers: the found images behind Hyaline's glass.

.DESCRIPTION
    Wallpapers come from Wikimedia Commons, where every file has a structured
    license and author. They are chosen by taste (ADR 0012). Two rules are
    gates:

        Format    a landscape JPEG at least 1920 px wide
        License   allows redistribution (CC0, public domain, CC BY, CC BY-SA)

    Lightness, saturation, and detail are grades. They rank search results
    and suggest a variant from lightness: light at L* 60 or above, dark at 40
    or below, both in between. They never refuse an image.

    -Search lists Commons candidates and grades each from a small preview.
    -Check grades one image from its 1920 px Commons thumbnail (or a local
    file) instead of a preview.
    -Add downloads a Commons file into wallpapers/, unmodified, writes the
    640 px thumbnail, and prints the credit section for wallpapers/README.md,
    with the variant mark given. It refuses an image that fails a gate.

    Images are read with SixLabors.ImageSharp (Apache 2.0 for open source
    projects), downloaded once from NuGet, checked against a pinned hash, and
    cached with every download in a temp folder.

.PARAMETER Search
    Words to look for on Commons, such as "dunes", "fog", or "snow field".

.PARAMETER Limit
    For -Search: how many candidates to show. Default 10.

.PARAMETER All
    For -Search: also show candidates that fail a gate, with the reason.

.PARAMETER Variant
    For -Search: keep images suggested for this variant (dark, light, or
    both), exact suggestions first. For -Add: the variant mark, required.

.PARAMETER Check
    A local image path, or a Commons title such as "File:Example.jpg".

.PARAMETER Add
    A Commons title such as "File:Example.jpg". Needs -Name.

.PARAMETER Name
    For -Add: the short name, such as "white-sands-dunes". Lowercase words
    joined by hyphens.

.EXAMPLE
    pwsh build/wallpaper.ps1 -Search "salt flat"

.EXAMPLE
    pwsh build/wallpaper.ps1 -Search "dunes night" -Variant dark

.EXAMPLE
    pwsh build/wallpaper.ps1 -Check wallpapers/white-sands-dunes.jpg

.EXAMPLE
    pwsh build/wallpaper.ps1 -Add "File:Minimal hike on the dunes (Unsplash).jpg" -Name white-sands-dunes -Variant light
#>
[CmdletBinding(DefaultParameterSetName = 'Search')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Search', Position = 0)]
    [string]$Search,

    [Parameter(ParameterSetName = 'Search')]
    [ValidateRange(1, 50)]
    [int]$Limit = 10,

    [Parameter(ParameterSetName = 'Search')]
    [switch]$All,

    [Parameter(ParameterSetName = 'Search')]
    [Parameter(Mandatory, ParameterSetName = 'Add')]
    [ValidateSet('dark', 'light', 'both')]
    [string]$Variant,

    [Parameter(Mandatory, ParameterSetName = 'Check')]
    [string]$Check,

    [Parameter(Mandatory, ParameterSetName = 'Add')]
    [string]$Add,

    [Parameter(Mandatory, ParameterSetName = 'Add')]
    [string]$Name
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib' 'Wallpaper.psm1') -Force

$RepoRoot      = Split-Path -Parent $PSScriptRoot
$WallpaperDir  = Join-Path $RepoRoot 'wallpapers'
$CacheDir      = Join-Path ([System.IO.Path]::GetTempPath()) 'hyaline-wallpapers'
$CommonsApi    = 'https://commons.wikimedia.org/w/api.php'
$UserAgent     = 'wallpaper-finder/1.0 (PowerShell)'

$ImageSharpVersion = '3.2.0'
$ImageSharpSha256  = '60d345f55451db74bbefb3231950c2524c12fe038173b08dabce4a844f22b179'

$Rules     = Get-WallpaperRules
$MinWidth  = $Rules.Format.MinWidth
$FitWidth  = 480
$CheckWidth = 1920   # a standard Commons thumbnail size; grades are taken from a 480 px copy anyway
$ThumbWidth = 640

# --- Downloads and ImageSharp -------------------------------------------------

function Get-CachePath([string]$Name) {
    if (-not (Test-Path $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir | Out-Null }
    return Join-Path $CacheDir $Name
}

function Wait-RequestSlot {
    # Waits until the last request from any running copy of the finder is at
    # least the minimum gap old, then stamps now. The cache folder is shared,
    # so a lock file there keeps parallel searches from bursting.
    $gap = (Get-WallpaperRules).Polite.MinGapSeconds
    $lock = Get-CachePath 'request.lock'
    $stream = $null
    while (-not $stream) {
        try { $stream = [System.IO.File]::Open($lock, 'OpenOrCreate', 'ReadWrite', 'None') }
        catch [System.IO.IOException] { Start-Sleep -Milliseconds 200 }
    }
    try {
        $buf = [byte[]]::new(32)
        $n = $stream.Read($buf, 0, $buf.Length)
        $last = [long]0
        if ($n -and [long]::TryParse([Text.Encoding]::ASCII.GetString($buf, 0, $n), [ref]$last)) {
            $wait = $gap * 1000 - ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $last)
            if ($wait -gt 0) { Start-Sleep -Milliseconds ([math]::Min($wait, $gap * 1000)) }
        }
        $stamp = [Text.Encoding]::ASCII.GetBytes([string][DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
        $stream.SetLength(0); $stream.Write($stamp, 0, $stamp.Length)
    }
    finally { $stream.Dispose() }
}

function Invoke-Polite([scriptblock]$Request) {
    # Runs a web request in its turn, and retries it when the server says it
    # is busy (429 or 503), waiting as long as it asks.
    for ($attempt = 1; ; $attempt++) {
        Wait-RequestSlot
        try { return & $Request }
        catch {
            $resp = $_.Exception.PSObject.Properties['Response']?.Value
            if (-not $resp -or -not $resp.PSObject.Properties['StatusCode']) { throw }
            $after = if ($resp.Headers.RetryAfter) { $resp.Headers.RetryAfter.ToString() } else { $null }
            $polite = (Get-WallpaperRules).Polite
            $wait = Get-WallpaperRetryDelay -Status ([int]$resp.StatusCode) -Attempt $attempt -RetryAfter $after
            if ($wait -lt 0) { throw }
            if ($wait -gt $polite.MaxSeconds) {
                throw "Commons is rate limiting this machine ($([int]$resp.StatusCode)) and asks for a pause of $([math]::Ceiling($wait / 60)) min. Try again after that; retrying sooner extends the block."
            }
            Write-Host "Commons is busy ($([int]$resp.StatusCode)). Waiting $wait s, then trying again ($($attempt + 1) of $($polite.Attempts))..."
            Start-Sleep -Seconds $wait
        }
    }
}

function Save-Url([string]$Url, [string]$Path) {
    if (Test-Path $Path) { return $Path }
    $part = "$Path.part"
    try { Invoke-Polite { Invoke-WebRequest -Uri $Url -OutFile $part -UserAgent $UserAgent }; Move-Item $part $Path -Force }
    catch { Remove-Item $part -ErrorAction SilentlyContinue; throw "Could not download $Url : $($_.Exception.Message)" }
    return $Path
}

function Import-ImageSharp {
    if ('SixLabors.ImageSharp.Image' -as [type]) { return }
    $dll = Get-CachePath "SixLabors.ImageSharp.$ImageSharpVersion.dll"
    if (-not (Test-Path $dll)) {
        $id = 'sixlabors.imagesharp'
        $pkg = Save-Url "https://api.nuget.org/v3-flatcontainer/$id/$ImageSharpVersion/$id.$ImageSharpVersion.nupkg" (Get-CachePath "$id.$ImageSharpVersion.nupkg")
        $zip = [System.IO.Compression.ZipFile]::OpenRead($pkg)
        try {
            $entry = $zip.GetEntry('lib/net6.0/SixLabors.ImageSharp.dll')
            if (-not $entry) { throw "The ImageSharp package has no lib/net6.0/SixLabors.ImageSharp.dll." }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "$dll.part", $true)
        }
        finally { $zip.Dispose() }
        $hash = (Get-FileHash "$dll.part" -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $ImageSharpSha256) {
            Remove-Item "$dll.part"
            throw "SixLabors.ImageSharp.dll has hash $hash, expected $ImageSharpSha256. Not loading it."
        }
        Move-Item "$dll.part" $dll -Force
    }
    Add-Type -Path $dll
}

function Read-Image([string]$Path) {
    Import-ImageSharp
    return [SixLabors.ImageSharp.Image]::Load[SixLabors.ImageSharp.PixelFormats.Rgb24]($Path)
}

function Copy-Image($Image, [int]$Width) {
    # A resized copy. Height keeps the aspect ratio.
    $ops = [Action[SixLabors.ImageSharp.Processing.IImageProcessingContext]] {
        param($c)
        [void][SixLabors.ImageSharp.Processing.ResizeExtensions]::Resize($c, $Width, 0)
    }.GetNewClosure()
    return [SixLabors.ImageSharp.Processing.ProcessingExtensions]::Clone($Image, $ops)
}

function Get-Pixels($Image) {
    # RGB bytes, row by row, via ImageSharp's binary PPM writer.
    $enc = [SixLabors.ImageSharp.Formats.Pbm.PbmEncoder]::new()
    $enc.ColorType = 'Rgb'; $enc.Encoding = 'Binary'; $enc.ComponentType = 'Byte'
    $ms = [System.IO.MemoryStream]::new()
    $Image.Save($ms, $enc)
    $all = $ms.ToArray()
    $lines = 0; $i = 0
    while ($lines -lt 3) { if ($all[$i] -eq 10) { $lines++ }; $i++ }   # P6, size, max value
    $out = [byte[]]::new($all.Length - $i)
    [Array]::Copy($all, $i, $out, 0, $out.Length)
    return , $out
}

# --- Measuring ----------------------------------------------------------------

function Measure-Image($Image) {
    # Grades from a small copy, so a preview grades like the full size.
    $copy = Copy-Image $Image ([math]::Min($FitWidth, $Image.Width))
    $fit = Measure-WallpaperFit -Pixels (Get-Pixels $copy) -Width $copy.Width -Height $copy.Height
    $copy.Dispose()
    return $fit
}

function Format-Fit($Fit) {
    # One line: the measures, their grades, and the suggested variant.
    return 'lightness {0} (suggests {1}), saturation {2} ({3}), detail {4} ({5})' -f `
        $Fit.Lightness, $Fit.Variant, $Fit.Saturation, $Fit.Grades.Saturation, $Fit.Detail, $Fit.Grades.Detail
}

function Write-Report($Fit, $Problems, [string]$Gates = 'the format and license gates') {
    Write-Host 'Grades'
    Write-Host ('  {0,-11} {1,6}   mean L*, 0 to 100: suggests {2}' -f 'lightness', $Fit.Lightness, $Fit.Variant)
    foreach ($k in $Rules.Grades.Keys) {
        $g = $Rules.Grades[$k]
        Write-Host ('  {0,-11} {1,6}   {2}: {3} (over {4} is {5})' -f $g.Label, $Fit[$k], $g.Unit, $Fit.Grades[$k], $g.Max, $g.Bad)
    }
    Write-Host ''
    if ($Problems.Count) {
        Write-Host 'Fails:'
        foreach ($p in $Problems) { Write-Host "  - $p" }
    }
    else { Write-Host "Passes $Gates." }
}

# --- Commons ------------------------------------------------------------------

function Invoke-Commons([hashtable]$Query) {
    $Query['action'] = 'query'; $Query['format'] = 'json'; $Query['formatversion'] = '2'
    $pairs = foreach ($k in $Query.Keys) { "$k=$([uri]::EscapeDataString([string]$Query[$k]))" }
    $uri = "$CommonsApi`?$($pairs -join '&')"
    return Invoke-Polite { Invoke-RestMethod -Uri $uri -UserAgent $UserAgent }
}

$InfoProps = @{
    prop = 'imageinfo'; iiprop = 'url|size|mime|extmetadata'; iiurlwidth = $FitWidth
    iiextmetadatafilter = 'LicenseShortName|LicenseUrl|Artist|DateTimeOriginal|ImageDescription'
}

function Remove-Html([string]$Text) {
    $t = [regex]::Replace($Text, '<[^>]+>', '')
    return ([System.Net.WebUtility]::HtmlDecode($t) -replace '\s+', ' ').Trim()
}

function Get-ArtistName([string]$Html) {
    # Commons often follows the name with notes. The first link is the name.
    $m = [regex]::Match($Html, '<a\b[^>]*>(.*?)</a>', 'Singleline')
    if ($m.Success) { return Remove-Html $m.Groups[1].Value }
    return Remove-Html $Html
}

function Get-ArtistLink([string]$Html) {
    $m = [regex]::Match($Html, 'href="([^"]+)"')
    if (-not $m.Success) { return $null }
    $u = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
    if ($u.StartsWith('//')) { $u = "https:$u" }
    return $u
}

function ConvertTo-Candidate($Page) {
    $ii = $Page.imageinfo[0]
    $meta = $ii.extmetadata
    $field = { param($k) if ($meta.PSObject.Properties[$k]) { [string]$meta.$k.value } else { '' } }
    $clean = { param($u) ($u -replace '\?utm_[^#]*$', '') }
    return [pscustomobject]@{
        Title       = $Page.title
        Width       = [int]$ii.width
        Height      = [int]$ii.height
        Mime        = $ii.mime
        Url         = & $clean $ii.url
        ThumbUrl    = & $clean $ii.thumburl
        Page        = $ii.descriptionurl
        License     = Remove-Html (& $field 'LicenseShortName')
        LicenseUrl  = & $field 'LicenseUrl'
        Author      = Get-ArtistName (& $field 'Artist')
        AuthorUrl   = Get-ArtistLink (& $field 'Artist')
        Date        = (Remove-Html (& $field 'DateTimeOriginal')) -replace '^(\d{4}-\d{2}-\d{2}).*$', '$1'
        Description = Remove-Html (& $field 'ImageDescription')
    }
}

function Get-RuleProblems($Candidate) {
    # The gates: license and format (JPEG, size, shape).
    $p = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-WallpaperLicense $Candidate.License)) { $p.Add("license '$($Candidate.License)' does not clearly allow redistribution.") }
    if ($Candidate.Mime -ne 'image/jpeg') { $p.Add("$($Candidate.Mime), not a JPEG.") }
    foreach ($f in Test-WallpaperFormat -Width $Candidate.Width -Height $Candidate.Height) { $p.Add($f) }
    return , $p
}

function Get-Candidate([string]$Title, [int]$PreviewWidth = $FitWidth) {
    if ($Title -notmatch '^File:') { $Title = "File:$Title" }
    $q = @{ titles = $Title } + $InfoProps
    $q['iiurlwidth'] = $PreviewWidth
    $page = (Invoke-Commons $q).query.pages[0]
    if ($page.PSObject.Properties['missing'] -or -not $page.PSObject.Properties['imageinfo']) { throw "Commons has no file '$Title'." }
    return ConvertTo-Candidate $page
}

function Get-SafeFileName([string]$Title) { return ($Title -replace '[^A-Za-z0-9._-]', '_') }

# --- Search -------------------------------------------------------------------

if ($PSCmdlet.ParameterSetName -eq 'Search') {
    $q = @{
        generator = 'search'; gsrnamespace = '6'; gsrlimit = '50'
        gsrsearch = "$Search filetype:bitmap filemime:image/jpeg filew:>$($MinWidth - 1)"
    } + $InfoProps
    $res = Invoke-Commons $q
    $pages = if ($res.PSObject.Properties['query']) { @($res.query.pages | Sort-Object index) } else { @() }
    if (-not $pages) { Write-Host 'Nothing found. Try broader words: dunes, fog, snow, sky, beach, mist.'; return }

    Write-Host "Grading up to $($pages.Count) Commons results for '$Search' from previews..."
    $graded = foreach ($pg in $pages) {
        $c = ConvertTo-Candidate $pg
        $problems = Get-RuleProblems $c
        $fit = $null
        if ($problems.Count -eq 0 -or $All) {
            try {
                $img = Read-Image (Save-Url $c.ThumbUrl (Get-CachePath ('thumb-' + (Get-SafeFileName $c.Title))))
                $fit = Measure-Image $img
                $img.Dispose()
            }
            catch { $problems.Add("could not measure: $($_.Exception.Message)") }
        }
        [pscustomobject]@{ Candidate = $c; Fit = $fit; Problems = $problems }
    }
    $measured = @($graded | Where-Object { $_.Problems.Count -eq 0 })
    $want = if ($Variant) { @{ Variant = $Variant } } else { @{} }
    $pass = @(Select-WallpaperCandidate -Candidate $measured @want)
    $other = $measured.Count - $pass.Count
    $fail = @($graded | Where-Object { $_.Problems.Count -gt 0 })

    $show = { param($g)
        $c = $g.Candidate
        Write-Host "  $($c.Title)"
        $by = if (-not $c.Author) { 'unknown' } elseif ($c.Author.Length -gt 50) { $c.Author.Substring(0, 47) + '...' } else { $c.Author }
        Write-Host "    $($c.Width) x $($c.Height), $($c.License), by $by"
        if ($g.Fit) { Write-Host "    $(Format-Fit $g.Fit)" }
        Write-Host "    $($c.Page)"
        foreach ($p in $g.Problems) { Write-Host "    - $p" }
    }

    Write-Host ''
    $for = if ($Variant) { " for $Variant" } else { '' }
    Write-Host "Pass the gates$for ($($pass.Count)), calmest first:"
    if ($pass) { foreach ($g in $pass | Select-Object -First $Limit) { & $show $g } }
    else { Write-Host '  none. Try other words, or -All to see why each failed.' }
    if ($other) { Write-Host ''; Write-Host "$other more pass the gates but suggest another variant." }
    if ($All -and $fail) {
        Write-Host ''
        Write-Host "Fail ($($fail.Count)):"
        foreach ($g in $fail | Select-Object -First $Limit) { & $show $g }
    }
    elseif ($fail) { Write-Host ''; Write-Host "$($fail.Count) failed a gate. Add -All to see why." }
    Write-Host ''
    Write-Host 'Previews only. Look at a candidate, then run -Check "<title>" on the full image.'
    return
}

# --- Check ----------------------------------------------------------------------

if ($PSCmdlet.ParameterSetName -eq 'Check') {
    $candidate = $null
    if (Test-Path -LiteralPath $Check -PathType Leaf) { $path = (Resolve-Path -LiteralPath $Check).Path }
    else {
        # The 1920 px standard thumbnail, not the original: it grades the same
        # and spares Commons a download of many megabytes.
        $candidate = Get-Candidate $Check $CheckWidth
        $path = Save-Url $candidate.ThumbUrl (Get-CachePath ("check$CheckWidth-" + (Get-SafeFileName $candidate.Title)))
    }
    $img = Read-Image $path
    $size = if ($candidate) { "$($candidate.Width) x $($candidate.Height)" } else { "$($img.Width) x $($img.Height)" }
    Write-Host "$Check ($size)"
    if ($candidate) { Write-Host "$($candidate.License), by $($candidate.Author). $($candidate.Page)" }
    Write-Host ''
    # Get-RuleProblems returns its list whole; looping over the call would add
    # that list as one blank problem.
    if ($candidate) { $problems = Get-RuleProblems $candidate }
    else {
        $problems = [System.Collections.Generic.List[string]]::new()
        foreach ($p in Test-WallpaperFormat -Width $img.Width -Height $img.Height) { $problems.Add($p) }
    }
    $fit = Measure-Image $img
    $img.Dispose()
    $gates = if ($candidate) { 'the format and license gates' } else { 'the format gate (license is checked for Commons titles)' }
    Write-Report $fit $problems $gates
    if ($problems.Count) { exit 1 }
    return
}

# --- Add ------------------------------------------------------------------------

if ($Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "-Name must be lowercase words joined by hyphens, such as 'white-sands-dunes'." }
$target = Join-Path $WallpaperDir "$Name.jpg"
$thumb  = Join-Path $WallpaperDir 'thumbs' "$Name.jpg"
if ((Test-Path $target) -or (Test-Path $thumb)) { throw "wallpapers/$Name.jpg or its thumbnail already exists." }

$c = Get-Candidate $Add
$problems = Get-RuleProblems $c
if ($problems.Count) { throw "Not adding $($c.Title): $($problems -join ' ')" }

$cached = Save-Url $c.Url (Get-CachePath ('full-' + (Get-SafeFileName $c.Title)))
$img = Read-Image $cached
$fit = Measure-Image $img
Write-Report $fit @()
Write-Host ''
$agree = if ($fit.Variant -eq $Variant) { 'agrees' } else { 'differs, your call stands' }
Write-Host "Marked $Variant; lightness suggests $($fit.Variant) ($agree)."

# The original goes in byte for byte. Only the thumbnail is re-encoded.
# Both files or neither.
try {
    New-Item -ItemType Directory -Path (Split-Path $thumb) -Force | Out-Null
    $small = Copy-Image $img $ThumbWidth
    $enc = [SixLabors.ImageSharp.Formats.Jpeg.JpegEncoder]::new()
    $enc.Quality = 85
    [SixLabors.ImageSharp.ImageExtensions]::Save($small, $thumb, $enc)
    $small.Dispose()
    Copy-Item -LiteralPath $cached -Destination $target
}
catch {
    Remove-Item -LiteralPath $thumb, $target -ErrorAction SilentlyContinue
    throw
}
finally { $img.Dispose() }

$title = (Get-Culture).TextInfo.ToTitleCase(($Name -replace '-', ' '))
$author = if ($c.AuthorUrl) { "[$($c.Author)]($($c.AuthorUrl))" } elseif ($c.Author) { $c.Author } else { 'Unknown' }
$license = if ($c.LicenseUrl) { "[$($c.License)]($($c.LicenseUrl))" } else { $c.License }
$section = @"
## $title

[![$title](thumbs/$Name.jpg)]($Name.jpg)

| | |
|---|---|
| File | [``$Name.jpg``]($Name.jpg), $($c.Width) × $($c.Height), unmodified original |
| Variant | $((Get-Culture).TextInfo.ToTitleCase($Variant)) |
| Subject | $($c.Description) |
| Author | $author |
| Date | $(if ($c.Date) { $c.Date } else { 'Unknown' }) |
| Source | [Wikimedia Commons]($($c.Page)) |
| License | $license |
"@

Write-Host ''
Write-Host "Wrote wallpapers/$Name.jpg and wallpapers/thumbs/$Name.jpg."
Write-Host 'Add this to wallpapers/README.md, after the last section. For a pair, make it'
Write-Host 'a ### subsection of the pair section instead. Rewrite the Subject in one plain'
Write-Host 'line, and check the author and license against the Commons page:'
Write-Host ''
Write-Host $section
