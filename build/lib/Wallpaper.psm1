# Wallpapers (ADR 0012): found images chosen by taste. Lightness, saturation,
# and detail are grades that rank candidates and suggest a variant; license
# and format are the only gates. Pure math on RGB bytes: loading and resizing
# the image is build/wallpaper.ps1's job, so these rules can be tested without
# an image library.

Set-StrictMode -Version Latest

# Measured on a small copy of the image. White Sands, the first wallpaper,
# reads lightness 81, saturation 15, detail 0.2. Busy photos (trees,
# buildings) read 2 to 4. Over a limit is a grade, not a failure.
$Grades = [ordered]@{
    Saturation = @{ Max = 25;  Label = 'saturation'; Unit = 'mean HSV saturation, %'; Good = 'calm'; Bad = 'colorful' }
    Detail     = @{ Max = 1.5; Label = 'detail';     Unit = 'mean edge strength, %'; Good = 'calm'; Bad = 'busy' }
}

# The variant an image suggests, from its mean lightness (L*, 0 to 100).
$Variants = @{ Light = 60; Dark = 40 }

# Format gate: a landscape JPEG at least this wide.
$Format = @{ MinWidth = 1920 }

# Licenses that allow redistribution, as Wikimedia Commons names them
# (LicenseShortName). Attribution licenses are fine: the credit is recorded
# anyway. NonCommercial and NoDerivatives are not.
$LicensePatterns = @(
    '^CC0( 1\.0)?$'
    '^Public domain$'
    '^PDM( 1\.0)?$'
    '^CC BY(-SA)? [1-4]\.0$'
)

# One sRGB channel (0 to 255, not rounded) to linear light, as a lookup.
function Get-LinearLight([double]$Channel) {
    $s = $Channel / 255
    if ($s -le 0.04045) { return $s / 12.92 }
    return [math]::Pow(($s + 0.055) / 1.055, 2.4)
}
$Linear = [double[]]::new(256)
for ($i = 0; $i -lt 256; $i++) { $Linear[$i] = Get-LinearLight $i }

function Get-WallpaperRules {
    # The grade limits, variant thresholds, and gates, for reports and the skill.
    return @{ Grades = $Grades; Variants = $Variants; Format = $Format; Licenses = $LicensePatterns }
}

function Get-WallpaperVariant {
    # The suggested variant mark for a mean lightness: light, dark, or both.
    param([Parameter(Mandatory)][double]$Lightness)
    if ($Lightness -ge $Variants.Light) { return 'light' }
    if ($Lightness -le $Variants.Dark) { return 'dark' }
    return 'both'
}

function Test-WallpaperLicense {
    # True when a Commons LicenseShortName allows redistribution.
    param([AllowEmptyString()][string]$License)
    foreach ($p in $LicensePatterns) { if ($License.Trim() -match $p) { return $true } }
    return $false
}

function Measure-WallpaperFit {
    <#
    .SYNOPSIS
        Lightness, saturation, and detail of an image, their grades, and the
        suggested variant. Returns
        @{ Lightness; Saturation; Detail; Grades; Variant }.
    .PARAMETER Pixels
        RGB bytes, row by row, no padding.
    #>
    param([Parameter(Mandatory)][byte[]]$Pixels, [Parameter(Mandatory)][int]$Width, [Parameter(Mandatory)][int]$Height)
    $n = $Width * $Height
    if ($Pixels.Length -ne $n * 3) { throw "expected $($n * 3) bytes for $Width x $Height, got $($Pixels.Length)" }
    $luma = [double[]]::new($n)
    $sumL = 0.0; $sumS = 0.0
    for ($p = 0; $p -lt $n; $p++) {
        $r = $Pixels[3 * $p]; $g = $Pixels[3 * $p + 1]; $b = $Pixels[3 * $p + 2]
        $y = 0.2126 * $Linear[$r] + 0.7152 * $Linear[$g] + 0.0722 * $Linear[$b]
        # CIE L*: perceived lightness, 0 to 100.
        $f = if ($y -gt 216 / 24389) { [math]::Pow($y, 1 / 3) } else { (24389 / 27 * $y + 16) / 116 }
        $sumL += 116 * $f - 16
        $max = [math]::Max($r, [math]::Max($g, $b))
        $min = [math]::Min($r, [math]::Min($g, $b))
        if ($max -gt 0) { $sumS += ($max - $min) / $max }
        $luma[$p] = 0.2126 * $r + 0.7152 * $g + 0.0722 * $b
    }
    # Detail: mean step in brightness to the right and down neighbors.
    $sumD = 0.0; $steps = 0
    for ($row = 0; $row -lt $Height; $row++) {
        $base = $row * $Width
        for ($col = 0; $col -lt $Width; $col++) {
            $p = $base + $col
            if ($col + 1 -lt $Width) { $sumD += [math]::Abs($luma[$p + 1] - $luma[$p]); $steps++ }
            if ($row + 1 -lt $Height) { $sumD += [math]::Abs($luma[$p + $Width] - $luma[$p]); $steps++ }
        }
    }
    $fit = [ordered]@{
        Lightness  = [math]::Round($sumL / $n, 1)
        Saturation = [math]::Round(100 * $sumS / $n, 1)
        Detail     = if ($steps) { [math]::Round(100 * $sumD / $steps / 255, 2) } else { 0.0 }
    }
    $g = [ordered]@{}
    foreach ($k in $Grades.Keys) { $g[$k] = if ($fit[$k] -gt $Grades[$k].Max) { $Grades[$k].Bad } else { $Grades[$k].Good } }
    $fit['Grades'] = $g
    $fit['Variant'] = Get-WallpaperVariant -Lightness $fit.Lightness
    return $fit
}

function Select-WallpaperCandidate {
    <#
    .SYNOPSIS
        Filters and ranks candidates for a variant. Each candidate has a Fit
        from Measure-WallpaperFit.
    .DESCRIPTION
        For dark or light: images suggested for that variant first, then those
        suggested for both. For both: only those. Without -Variant: all. Within
        each group, the calmest first: saturation and detail, each against its
        grade limit.
    #>
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Candidate, [ValidateSet('dark', 'light', 'both')][string]$Variant)
    $calm = { $f = $_.Fit; $f.Saturation / $Grades.Saturation.Max + $f.Detail / $Grades.Detail.Max }
    $kept = if ($Variant) { @($Candidate | Where-Object { $_.Fit.Variant -eq $Variant -or $_.Fit.Variant -eq 'both' }) } else { $Candidate }
    return @($kept | Sort-Object { if ($Variant -and $_.Fit.Variant -ne $Variant) { 1 } else { 0 } }, $calm)
}

function Test-WallpaperFolder {
    <#
    .SYNOPSIS
        Every wallpaper has a thumbnail and a credit with a variant mark in
        the folder's README. A pair is one section with a subsection per
        image: one dark and one light, listed before single images. Returns a
        list of problems. Needs no image library, so CI runs it.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $problems = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $Path)) { return }
    $readmePath = Join-Path $Path 'README.md'
    $readme = if (Test-Path $readmePath) { [System.IO.File]::ReadAllText($readmePath) } else { $problems.Add('wallpapers/README.md does not exist.'); '' }
    $file = { param($Text) $m = [regex]::Match($Text, '\[`([^`]+\.jpg)`\]'); if ($m.Success) { $m.Groups[1].Value } }
    $mark = { param($Text) $m = [regex]::Match($Text, '(?mi)^\| Variant \| (dark|light|both) \|'); if ($m.Success) { $m.Groups[1].Value.ToLowerInvariant() } }
    $sections = @{}
    $seenSingle = $false
    foreach ($s in [regex]::Split($readme, '(?m)^(?=## )')) {
        $title = [regex]::Match($s, '^## (.+)$', 'Multiline').Groups[1].Value.Trim()
        $parts = @([regex]::Split($s, '(?m)^(?=### )') | Select-Object -Skip 1)
        if (-not $parts) { $parts = @($s) }
        $images = @(foreach ($part in $parts) { $n = & $file $part; if ($n) { $sections[$n] = $part; @{ Name = $n; Mark = & $mark $part } } })
        if ($images.Count -eq 1) { $seenSingle = $true }
        if ($images.Count -gt 1) {
            if ($seenSingle) { $problems.Add("wallpapers/README.md: the $title pair comes after a single image. List pairs first.") }
            $marks = @($images | ForEach-Object { $_.Mark }) | Sort-Object
            if ($images.Count -ne 2 -or ($marks -join ',') -ne 'dark,light') { $problems.Add("wallpapers/README.md: the $title pair needs one dark and one light image.") }
        }
    }
    $images = @(Get-ChildItem -Path $Path -File | Where-Object Name -ne 'README.md')
    foreach ($f in $images) {
        $n = $f.Name
        if ($n -notmatch '^[a-z0-9]+(-[a-z0-9]+)*\.jpg$') { $problems.Add("wallpapers/$n is not a <short-name>.jpg file."); continue }
        if (-not (Test-Path (Join-Path $Path 'thumbs' $n))) { $problems.Add("wallpapers/$n has no thumbs/$n.") }
        if (-not $sections.ContainsKey($n)) { $problems.Add("wallpapers/$n has no section in wallpapers/README.md."); continue }
        foreach ($row in 'Author', 'Source', 'License') {
            if ($sections[$n] -notmatch "(?m)^\| $row \| \S") { $problems.Add("wallpapers/README.md: the $n section has no $row.") }
        }
        if (-not (& $mark $sections[$n])) { $problems.Add("wallpapers/README.md: the $n section has no Variant (dark, light, or both).") }
    }
    $thumbDir = Join-Path $Path 'thumbs'
    if (Test-Path $thumbDir) {
        foreach ($t in Get-ChildItem -Path $thumbDir -File) {
            if (-not (Test-Path (Join-Path $Path $t.Name))) { $problems.Add("wallpapers/thumbs/$($t.Name) has no wallpaper.") }
        }
    }
    foreach ($n in $sections.Keys) {
        if (-not (Test-Path (Join-Path $Path $n))) { $problems.Add("wallpapers/README.md credits $n, which does not exist.") }
    }
    return $problems
}

Export-ModuleMember -Function Test-WallpaperFolder, Get-WallpaperRules, Get-WallpaperVariant, Select-WallpaperCandidate, Test-WallpaperLicense, Measure-WallpaperFit
