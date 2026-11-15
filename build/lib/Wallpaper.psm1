# Wallpapers (ADR 0003): what makes a found image fit the backdrop, and how
# readable Hyaline's glass stays over it. Pure math on RGB bytes: loading,
# resizing, and blurring the image is build/wallpaper.ps1's job, so these
# rules can be tested without an image library.

Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Palette.psm1')

# The backdrop must be light, calm, and quiet (ADR 0003). Measured on a small
# copy of the image, before any blur. White Sands, the first wallpaper, reads
# lightness 81, saturation 15, detail 0.2. Busy photos (trees, buildings)
# read 2 to 4.
$FitRules = [ordered]@{
    Lightness  = @{ Min = 70;  Label = 'lightness';  Unit = 'mean L*, 0 to 100'; Hint = 'too dark: the backdrop is light in both variants' }
    Saturation = @{ Max = 25;  Label = 'saturation'; Unit = 'mean HSV saturation, %'; Hint = 'too colorful: color is for signal, not the backdrop' }
    Detail     = @{ Max = 1.5; Label = 'detail';     Unit = 'mean edge strength, %'; Hint = 'too busy: glass over fine detail looks noisy' }
}

# How the glass is measured (ADR 0004): the image scaled to a common screen
# width, blurred like frosted glass, then every spot checked.
$Screen = @{ Width = 1920; Blur = 18 }

# Licenses that allow redistribution, as Wikimedia Commons names them
# (LicenseShortName). Attribution licenses are fine: the credit is recorded
# anyway. NonCommercial and NoDerivatives are not.
$LicensePatterns = @(
    '^CC0( 1\.0)?$'
    '^Public domain$'
    '^PDM( 1\.0)?$'
    '^CC BY(-SA)? [1-4]\.0$'
)

# Relative luminance (WCAG): channel weights, and one sRGB channel (0 to 255,
# not rounded) to linear light.
$Weights = @(0.2126, 0.7152, 0.0722)
function Get-LinearLight([double]$Channel) {
    $s = $Channel / 255
    if ($s -le 0.04045) { return $s / 12.92 }
    return [math]::Pow(($s + 0.055) / 1.055, 2.4)
}
$Linear = [double[]]::new(256)
for ($i = 0; $i -lt 256; $i++) { $Linear[$i] = Get-LinearLight $i }

function Get-WallpaperRules {
    # The thresholds and measuring setup, for reports and the skill.
    return @{ Fit = $FitRules; Screen = $Screen; Licenses = $LicensePatterns }
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
        Lightness, saturation, and detail of an image. Returns
        @{ Lightness; Saturation; Detail; Problems }.
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
    $problems = [System.Collections.Generic.List[string]]::new()
    foreach ($k in $FitRules.Keys) {
        $rule = $FitRules[$k]
        if ($rule.ContainsKey('Min') -and $fit[$k] -lt $rule.Min) { $problems.Add("$($rule.Label) $($fit[$k]) is under $($rule.Min): $($rule.Hint).") }
        if ($rule.ContainsKey('Max') -and $fit[$k] -gt $rule.Max) { $problems.Add("$($rule.Label) $($fit[$k]) is over $($rule.Max): $($rule.Hint).") }
    }
    $fit['Problems'] = $problems
    return $fit
}

function Measure-WallpaperContrast {
    <#
    .SYNOPSIS
        The worst-case contrast of each role on Hyaline's glass over a
        backdrop, in both variants.
    .DESCRIPTION
        Pixels is the backdrop as the glass sees it: already scaled and
        blurred. For every spot, the surface is the role's tint at its alpha
        over that spot. Chrome carries only primary text, on its own and on a
        tab (raised over chrome). Panel carries every text and color role.

        Returns one row per variant, surface, and role:
        @{ Variant; Name; Surface; Role; Floor; Worst; Pass }.
    #>
    param([Parameter(Mandatory)]$Palette, [Parameter(Mandatory)][byte[]]$Pixels)
    if ($Pixels.Length -eq 0 -or $Pixels.Length % 3) { throw 'Pixels must be RGB bytes.' }
    $floors = Get-ContrastFloors
    $rows = [System.Collections.Generic.List[object]]::new()

    foreach ($v in $Palette.Variants.Values) {
        $rgb = { param($Role) ConvertFrom-Hex $v.Roles[$Role].Hex }
        $chrome = & $rgb 'chrome'; $ca = $v.Roles['chrome'].Alpha
        $raised = & $rgb 'raised'; $ra = $v.Roles['raised'].Alpha
        $panel  = & $rgb 'panel';  $pa = $v.Roles['panel'].Alpha

        # Each surface channel is (scale * backdrop + offset): tint at alpha
        # over the backdrop, and for a tab, raised over that again. So each
        # surface gets a lookup from backdrop byte to linear light, per channel.
        $surfaces = [ordered]@{
            chrome = @{ Scale = 1 - $ca; Offset = @(foreach ($i in 0, 1, 2) { $ca * $chrome[$i] }) }
            tab    = @{ Scale = (1 - $ra) * (1 - $ca); Offset = @(foreach ($i in 0, 1, 2) { $ra * $raised[$i] + (1 - $ra) * $ca * $chrome[$i] }) }
            panel  = @{ Scale = 1 - $pa; Offset = @(foreach ($i in 0, 1, 2) { $pa * $panel[$i] }) }
        }
        $range = @{}
        foreach ($name in $surfaces.Keys) {
            $sf = $surfaces[$name]
            $t = foreach ($ch in 0, 1, 2) {
                $w = $Weights[$ch]
                $table = [double[]]::new(256)
                for ($b = 0; $b -lt 256; $b++) { $table[$b] = $w * (Get-LinearLight ($sf.Scale * $b + $sf.Offset[$ch])) }
                , $table
            }
            $tr, $tg, $tb = $t
            # The worst contrast for a role is at whichever end of the
            # surface's luminance range is nearest the role's luminance.
            $lo = [double]::MaxValue; $hi = [double]::MinValue
            for ($p = 0; $p -lt $Pixels.Length; $p += 3) {
                $l = $tr[$Pixels[$p]] + $tg[$Pixels[$p + 1]] + $tb[$Pixels[$p + 2]]
                if ($l -lt $lo) { $lo = $l }
                if ($l -gt $hi) { $hi = $l }
            }
            $range[$name] = @($lo, $hi)
        }

        $checks = [System.Collections.Generic.List[object]]::new()
        $checks.Add(@('chrome', 'text', $floors.Text))
        $checks.Add(@('tab', 'text', $floors.Text))
        foreach ($role in $floors.TextRoles) { $checks.Add(@('panel', $role, $floors.Text)) }
        $checks.Add(@('panel', 'text_muted', $floors.Muted))

        foreach ($c in $checks) {
            $surface, $role, $floor = $c
            $fg = & $rgb $role
            $lf = 0.0
            foreach ($ch in 0, 1, 2) { $lf += $Weights[$ch] * (Get-LinearLight $fg[$ch]) }
            $lo, $hi = $range[$surface]
            $worst = if ($lf -ge $lo -and $lf -le $hi) { 1.0 }
                     elseif ($lf -lt $lo) { ($lo + 0.05) / ($lf + 0.05) }
                     else { ($lf + 0.05) / ($hi + 0.05) }
            $rows.Add([pscustomobject]@{
                Variant = $v.Key; Name = $v.Name; Surface = $surface; Role = $role
                Floor = $floor; Worst = $worst; Pass = $worst -ge $floor
            })
        }
    }
    return $rows
}

function Test-WallpaperFolder {
    <#
    .SYNOPSIS
        Every wallpaper has a thumbnail and a credit in the folder's README.
        Returns a list of problems. Needs no image library, so CI runs it.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $problems = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $Path)) { return }
    $readmePath = Join-Path $Path 'README.md'
    $readme = if (Test-Path $readmePath) { [System.IO.File]::ReadAllText($readmePath) } else { $problems.Add('wallpapers/README.md does not exist.'); '' }
    $sections = @{}
    foreach ($s in [regex]::Split($readme, '(?m)^(?=## )')) {
        $m = [regex]::Match($s, '\[`([^`]+\.jpg)`\]')
        if ($m.Success) { $sections[$m.Groups[1].Value] = $s }
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

Export-ModuleMember -Function Test-WallpaperFolder, Get-WallpaperRules, Test-WallpaperLicense, Measure-WallpaperFit, Measure-WallpaperContrast
