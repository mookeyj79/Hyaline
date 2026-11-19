# The palette: loading and validating palette/palette.json, and every color
# calculation the build and the checks share (filters, wash, contrast).
# One place, so what the checks measure is what the build writes.

Set-StrictMode -Version Latest

$Invariant = [cultureinfo]::InvariantCulture

# Both variants, always (PHILOSOPHY.md: two variants, one theme).
$VariantKeys = @('dark', 'light')

$RequiredRoles = @(
    'backdrop', 'chrome', 'chrome_flat', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line',
    'edge', 'edge_flat', 'window_edge', 'window_edge_flat', 'text', 'text_dim', 'text_muted', 'accent', 'on_accent',
    'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange'
)

# Translucent surfaces with a clamp block beside their dense alpha (ADR 0008):
# the CSS recipe of blur, contrast, brightness, saturate, and a thin tint alpha.
$ClampRoles = @('chrome', 'panel')
$ClampKeys = [ordered]@{ blur = 'Blur'; contrast = 'Contrast'; brightness = 'Brightness'; saturate = 'Saturate'; alpha = 'Alpha' }

# Roles that may be used as a wash (ADR 0006). Only these are contrast
# checked on a wash, so only these take |wash and |washflat.
$WashRoles = @('accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')

# Filters for color roles. The CONTRIBUTING.md placeholder table is checked
# against this list.
$Filters = [ordered]@{
    ''         = 'hex'
    'nohash'   = 'hex without #'
    'rgb'      = 'r, g, b'
    'rgba'     = 'rgba(r, g, b, a)'
    'hexa'     = '#rrggbbaa'
    'alpha'    = 'alpha, 0 to 1'
    'percent'  = 'alpha, 0 to 100'
    'wash'     = '#rrggbbaa at the wash alpha'
    'washflat' = 'the wash over panel_flat, #rrggbb'
    'clear'    = '#rrggbb00'
    'clamp'    = 'the clamp as a CSS backdrop-filter value'
    'clamptint' = 'the clamp''s thin tint, rgba(r, g, b, a)'
}

# Terminal ANSI slots (ADR 0001). The six hues and their bright versions
# reuse their namesake role. Black and white map to neutrals by brightness.
$AnsiHues = @('red', 'green', 'yellow', 'blue', 'magenta', 'cyan')
$AnsiNeutrals = @{
    dark  = @{ black = 'raised_flat'; bright_black = 'text_muted'; white = 'text_dim'; bright_white = 'text' }
    light = @{ black = 'text';        bright_black = 'text_muted'; white = 'line';     bright_white = 'raised_flat' }
}

# Contrast floor (PHILOSOPHY.md, ADR 0011 and 0013). line, edge, and window_edge
# carry no meaning and have no floor, so they are never measured.
# One row per surface kind, as in the two tables in PHILOSOPHY.md; "color"
# stands for every role color. Read them through Get-ContrastFloor.
$FloorRows = @{
    panel  = @{ text = 4.5; text_dim = 4.5; text_muted = 3.0; color = 4.5 }
    raised = @{ text = 4.5; text_dim = 4.5; text_muted = 3.0; color = 3.0 }
    chrome = @{ text = 4.5 }
    wash   = @{ text = 4.5; text_dim = 3.0; text_muted = 3.0; color = 3.0 }
    fill   = @{ on_accent = 4.5 }
}
# Opacity-only glass (ADR 0013): the panel at its dense alpha, and washes
# over it, have their own rows. Primary text keeps 4.5; every other
# threshold is two thirds of the full row. Raised and chrome keep theirs.
$OpacityOnlyFloorRows = @{
    panel = @{ text = 4.5; text_dim = 3.0; text_muted = 2.0; color = 3.0 }
    wash  = @{ text = 4.5; text_dim = 2.0; text_muted = 2.0; color = 2.0 }
}
$TextRoles   = @('text', 'text_dim', 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')
# Pure black and pure white bound every backdrop under a tint (ADR 0011).
$Backdrops   = [ordered]@{ black = '#000000'; white = '#ffffff' }

function Test-Number($Value) { return $Value -is [double] -or $Value -is [long] -or $Value -is [int] }

function Read-Clamp {
    # A role's clamp block as @{ Blur; Contrast; Brightness; Saturate; Alpha },
    # or $null after adding every problem to $Errors.
    param($Raw, [string]$Where, $Errors)
    if ($Raw -isnot [System.Collections.IDictionary]) {
        $Errors.Add("$Where clamp must be an object: { blur, contrast, brightness, saturate, alpha }.")
        return $null
    }
    $clamp = @{}
    $ok = $true
    foreach ($k in $ClampKeys.Keys) {
        $n = $Raw[$k]
        if (-not (Test-Number $n)) { $Errors.Add("$Where clamp.$k must be a number."); $ok = $false; continue }
        if ($k -eq 'alpha' -and ($n -le 0 -or $n -gt 1)) { $Errors.Add("$Where clamp.alpha must be between 0 and 1."); $ok = $false; continue }
        if ($n -lt 0) { $Errors.Add("$Where clamp.$k must not be negative."); $ok = $false; continue }
        $clamp[$ClampKeys[$k]] = [double]$n
    }
    if ($ok) { return $clamp }
    return $null
}

function Read-Palette {
    <#
    .SYNOPSIS
        Loads palette.json. Returns @{ Meta; Variants; Errors }.
    .DESCRIPTION
        Variants is an ordered map of 'dark' and 'light' to
        @{ Key; Name; Mode; Wash; Roles }, where Roles maps a role name to
        @{ Hex (lowercase #rrggbb); Alpha; Clamp }. Clamp is $null except on
        chrome and panel: @{ Blur; Contrast; Brightness; Saturate; Alpha }. Errors lists every problem found.
        When Errors is not empty, Variants may be incomplete: do not build.
    .PARAMETER Data
        The parsed JSON instead of a file, as from ConvertFrom-Json -AsHashtable.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')][string]$Path,
        [Parameter(Mandatory, ParameterSetName = 'Data')]$Data
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    $result = @{ Meta = @{}; Variants = [ordered]@{}; Errors = $errors }

    if ($PSCmdlet.ParameterSetName -eq 'Data') { $raw = $Data }
    else {
        if (-not (Test-Path $Path)) { $errors.Add('palette/palette.json does not exist.'); return $result }
        try { $raw = Get-Content -Raw -Path $Path | ConvertFrom-Json -AsHashtable }
        catch { $errors.Add("palette/palette.json is not valid JSON: $($_.Exception.Message)"); return $result }
    }

    if ($raw -isnot [System.Collections.IDictionary]) { $errors.Add('palette/palette.json must be an object.'); return $result }
    if ($raw['meta'] -is [System.Collections.IDictionary]) { $result.Meta = $raw['meta'] }
    foreach ($k in 'name', 'version') {
        if (-not $result.Meta.Contains($k)) { $errors.Add("meta.$k is missing.") }
    }
    if ($raw['variants'] -isnot [System.Collections.IDictionary]) { $errors.Add('variants is missing.'); return $result }

    foreach ($vKey in @($raw['variants'].Keys)) {
        if ($vKey -notin $VariantKeys) { $errors.Add("variants.$vKey is not a known variant. Use: $($VariantKeys -join ', ').") }
    }
    foreach ($vKey in $VariantKeys) {
        $v = $raw['variants'][$vKey]
        if ($v -isnot [System.Collections.IDictionary]) { $errors.Add("variant '$vKey' is missing."); continue }
        if (-not ($v['name'] -is [string] -and $v['name'].Trim())) { $errors.Add("variants.$vKey.name is missing.") }
        if ($v['mode'] -ne $vKey) { $errors.Add("variants.$vKey.mode must be '$vKey'.") }
        $wash = $v['wash']
        if (-not (Test-Number $wash) -or $wash -le 0 -or $wash -ge 1) {
            $errors.Add("variants.$vKey.wash must be a number between 0 and 1.")
            $wash = $null
        }
        # glass_floor: false means the glass values were chosen by eye (ADR 0014).
        # Glass is still measured and listed, but only solid surfaces can fail.
        $glassFloor = $true
        if ($v.Contains('glass_floor')) {
            if ($v['glass_floor'] -is [bool]) { $glassFloor = $v['glass_floor'] }
            else { $errors.Add("variants.$vKey.glass_floor must be true or false.") }
        }
        $roles = @{}
        if ($v['roles'] -isnot [System.Collections.IDictionary]) { $errors.Add("variants.$vKey.roles is missing.") }
        else {
            foreach ($role in $RequiredRoles) {
                if (-not $v['roles'].Contains($role)) { $errors.Add("$vKey is missing role '$role'.") }
            }
            foreach ($rKey in @($v['roles'].Keys)) {
                $r = $v['roles'][$rKey]
                $hex = $null; $alpha = 1.0; $clamp = $null
                if ($r -is [string]) { $hex = $r }
                elseif ($r -is [System.Collections.IDictionary]) {
                    $hex = [string]$r['hex']
                    if ($r.Contains('alpha')) {
                        $alpha = $r['alpha']
                        if (-not (Test-Number $alpha) -or $alpha -lt 0 -or $alpha -gt 1) {
                            $errors.Add("$vKey.$rKey alpha must be between 0 and 1.")
                            continue
                        }
                    }
                    if ($r.Contains('clamp')) {
                        if ($rKey -notin $ClampRoles) { $errors.Add("$vKey.$rKey cannot have a clamp. Only $($ClampRoles -join ' and ') do.") }
                        else { $clamp = Read-Clamp $r['clamp'] "$vKey.$rKey" $errors }
                    }
                }
                if ($rKey -in $ClampRoles -and -not ($r -is [System.Collections.IDictionary] -and $r.Contains('clamp'))) {
                    $errors.Add("$vKey.$rKey needs a clamp block: { blur, contrast, brightness, saturate, alpha }.")
                }
                if ($null -eq $hex -or $hex -notmatch '^#[0-9a-fA-F]{6}$') {
                    $errors.Add("$vKey.$rKey is not a valid #rrggbb value (or { hex, alpha }).")
                    continue
                }
                $roles[$rKey] = @{ Hex = $hex.ToLowerInvariant(); Alpha = [double]$alpha; Clamp = $clamp }
            }
        }
        $result.Variants[$vKey] = @{
            Key = $vKey; Name = [string]$v['name']; Mode = [string]$v['mode']
            Wash = if ($null -ne $wash) { [double]$wash } else { $null }
            GlassFloor = $glassFloor
            Roles = $roles
        }
    }
    return $result
}

function Get-VariantKeys { return $VariantKeys }
function Get-RequiredRoles { return $RequiredRoles }
# The surface and edge roles: everything a port draws that is not text or a color role.
function Get-SurfaceRoles { return @($RequiredRoles | Where-Object { $_ -notin $TextRoles + 'text_muted', 'on_accent' }) }
function Get-ColorFilters { return @($Filters.Keys | Where-Object { $_ }) }

function ConvertFrom-Hex([string]$Hex) {
    return @(foreach ($i in 1, 3, 5) { [Convert]::ToInt32($Hex.Substring($i, 2), 16) })
}

function Get-Blend {
    # The solid color of $Fg at $Alpha over $Bg, as #rrggbb.
    param([string]$Fg, [string]$Bg, [double]$Alpha)
    $f = ConvertFrom-Hex $Fg
    $b = ConvertFrom-Hex $Bg
    $out = foreach ($i in 0, 1, 2) { ([int][math]::Round($f[$i] * $Alpha + $b[$i] * (1 - $Alpha))).ToString('x2') }
    return '#' + ($out -join '')
}

function Get-Contrast {
    # WCAG contrast ratio of two #rrggbb colors.
    param([string]$A, [string]$B)
    $lum = {
        param($Hex)
        $c = foreach ($v in (ConvertFrom-Hex $Hex)) {
            $s = $v / 255
            if ($s -le 0.03928) { $s / 12.92 } else { [math]::Pow(($s + 0.055) / 1.055, 2.4) }
        }
        0.2126 * $c[0] + 0.7152 * $c[1] + 0.0722 * $c[2]
    }
    $la = & $lum $A
    $lb = & $lum $B
    if ($la -lt $lb) { $la, $lb = $lb, $la }
    return ($la + 0.05) / ($lb + 0.05)
}

function Get-WashColor {
    # A role at the variant's wash alpha laid over panel_flat, as #rrggbb.
    # This is what {{role|washflat}} writes and what the wash contrast is measured on.
    param($Variant, [string]$Role)
    return Get-Blend $Variant.Roles[$Role].Hex $Variant.Roles['panel_flat'].Hex $Variant.Wash
}

function Get-AnsiRole {
    # The role for a terminal ANSI slot in a variant, or $null for an unknown slot.
    param([string]$Slot, $Variant)
    $n = $AnsiNeutrals[$Variant.Mode]
    if ($n -and $n.ContainsKey($Slot)) { return $n[$Slot] }
    $hue = $Slot -replace '^bright_', ''
    if ($hue -in $AnsiHues) { return $hue }
    return $null
}

function Format-RoleColor {
    <#
    .SYNOPSIS
        A role's color in a variant, formatted by a filter. Throws on an
        unknown role or filter, or a wash filter on a role that is not a wash role.
    #>
    param($Variant, [string]$Role, [string]$Filter = '')
    if (-not $Variant.Roles.ContainsKey($Role)) { throw "unknown role '$Role'" }
    if (-not $Filters.Contains($Filter)) { throw "unknown filter '$Filter'. Use one of: $((Get-ColorFilters) -join ', ')" }
    if ($Filter -in 'wash', 'washflat' -and $Role -notin $WashRoles) {
        throw "|$Filter only applies to the wash roles ($($WashRoles -join ', ')), not '$Role'"
    }
    $c = $Variant.Roles[$Role]
    if ($Filter -in 'clamp', 'clamptint' -and -not $c.Clamp) {
        throw "|$Filter only applies to the clamped surfaces ($($ClampRoles -join ', ')), not '$Role'"
    }
    $hex = $c.Hex
    $rgb = ConvertFrom-Hex $hex
    $a = $c.Alpha.ToString('0.###', $Invariant)
    switch ($Filter) {
        ''         { return $hex }
        'nohash'   { return $hex.Substring(1) }
        'rgb'      { return $rgb -join ', ' }
        'rgba'     { return "rgba($($rgb -join ', '), $a)" }
        'hexa'     { return $hex + ([int][math]::Round($c.Alpha * 255)).ToString('x2') }
        'alpha'    { return $a }
        'percent'  { return [string][int][math]::Round($c.Alpha * 100) }
        'clear'    { return $hex + '00' }
        'wash'     { return $hex + ([int][math]::Round($Variant.Wash * 255)).ToString('x2') }
        'washflat' { return Get-WashColor $Variant $Role }
        'clamp'    {
            $n = { param($x) $x.ToString('0.###', $Invariant) }
            return 'blur({0}px) contrast({1}) brightness({2}) saturate({3})' -f (& $n $c.Clamp.Blur), (& $n $c.Clamp.Contrast), (& $n $c.Clamp.Brightness), (& $n $c.Clamp.Saturate)
        }
        'clamptint' { return "rgba($($rgb -join ', '), $($c.Clamp.Alpha.ToString('0.###', $Invariant)))" }
    }
}

function Get-GlassColor {
    <#
    .SYNOPSIS
        What a translucent role looks like over a solid backdrop, as #rrggbb.
    .DESCRIPTION
        Without -Clamp: the tint at the role's dense alpha, as an opacity-only
        app draws it. With -Clamp: the backdrop squeezed by the clamp's contrast,
        then its brightness (CSS filter functions, in sRGB, each step capped to
        0..1), then the tint at the clamp's thin alpha. Blur does not change a
        solid backdrop, and saturate does not change black or white, so neither
        is applied (ADR 0011: blur does not count).
    #>
    param($Variant, [string]$Role, [string]$Backdrop, [switch]$Clamp)
    $c = $Variant.Roles[$Role]
    if (-not $Clamp) { return Get-Blend $c.Hex $Backdrop $c.Alpha }
    if (-not $c.Clamp) { throw "'$Role' has no clamp" }
    $k = $c.Clamp
    $squeezed = foreach ($ch in (ConvertFrom-Hex $Backdrop)) {
        $x = [math]::Min(1.0, [math]::Max(0.0, ($ch / 255 - 0.5) * $k.Contrast + 0.5))
        $x = [math]::Min(1.0, [math]::Max(0.0, $x * $k.Brightness))
        ([int][math]::Round($x * 255)).ToString('x2')
    }
    return Get-Blend $c.Hex ('#' + ($squeezed -join '')) $k.Alpha
}

function Get-ContrastFloor {
    # The floor for $Role on a surface of kind $Kind, or on a wash over it.
    # Kinds: panel, opacityOnly (the panel at its dense alpha), raised,
    # chrome, fill. Only panel and opacityOnly carry washes.
    param([ValidateSet('panel', 'opacityOnly', 'raised', 'chrome', 'fill')][string]$Kind, [string]$Role, [switch]$Wash)
    $rows = if ($Kind -eq 'opacityOnly') { $OpacityOnlyFloorRows } else { $FloorRows }
    $row = if ($Wash) { $rows['wash'] } else { $rows[$Kind -replace '^opacityOnly$', 'panel'] }
    if (-not $row) { throw "$Kind has no wash floor." }
    $key = if ($row.ContainsKey($Role)) { $Role } elseif ($Role -in $TextRoles -and $row.ContainsKey('color')) { 'color' } else { throw "$Role has no floor on $Kind." }
    return $row[$key]
}

function Test-PaletteContrast {
    <#
    .SYNOPSIS
        Measures the contrast floor in PHILOSOPHY.md (ADR 0011) on a valid
        palette. Returns @{ Failures; Measurements }: Failures as a message
        list, Measurements as every ratio taken, passing or not, each
        @{ Variant; Role; Surface; Ratio; Floor; Pass }.
    .DESCRIPTION
        A solid surface is measured as drawn. A translucent surface (chrome,
        panel) is measured over pure black and pure white, both at its dense
        alpha and through its clamp; every result must pass, so the lower one
        counts. Translucent raised is only drawn on clamped glass (ADR 0008:
        with opacity only, raised is solid), so it is measured over the clamped
        panel. Washes are measured over every panel surface.

        The panel at its dense alpha is opacity-only glass, and it and the
        washes over it are measured against the opacity-only rows for the
        panel and a wash (ADR 0013). The clamped panel, panel_flat, raised,
        and chrome keep the full rows. PHILOSOPHY.md, "Contrast floor", has
        the numbers. A failure message states the floor that was missed.

        A variant with glass_floor false (ADR 0014) keeps its glass values as
        chosen by eye: glass rows are still measured, with Enforced false, and
        only solid surfaces (the flat values, fills, washes over panel_flat)
        can fail.
    #>
    param($Palette)
    $failures = [System.Collections.Generic.List[string]]::new()
    $measurements = [System.Collections.Generic.List[object]]::new()
    foreach ($v in $Palette.Variants.Values) {
        $k = $v.Key
        $hex = { param($r) $v.Roles[$r].Hex }
        $measure = {
            param([string]$Role, [string]$Surface, [string]$Where, [double]$Floor)
            $on = Get-Contrast (& $hex $Role) $Surface
            # Glass is drawn over a backdrop (black or white); solid surfaces are drawn as they are.
            $enforced = $v.GlassFloor -or $Where -notmatch ' over (black|white)$'
            $measurements.Add([pscustomobject]@{ Variant = $k; Role = $Role; Surface = $Where; Ratio = $on; Floor = $Floor; Pass = $on -ge $Floor; Enforced = $enforced })
            if ($enforced -and $on -lt $Floor) { $failures.Add(('{0}.{1} on {2} is {3:0.00}:1, needs {4}:1.' -f $k, $Role, $Where, $on, $Floor)) }
        }
        # Every way each surface can be drawn: name -> #rrggbb.
        $glass = {
            param([string]$Role)
            $out = [ordered]@{ "${Role}_flat" = & $hex "${Role}_flat" }
            foreach ($b in $Backdrops.Keys) { $out["$Role over $b"] = Get-GlassColor $v $Role $Backdrops[$b] }
            foreach ($b in $Backdrops.Keys) { $out["$Role clamp over $b"] = Get-GlassColor $v $Role $Backdrops[$b] -Clamp }
            $out
        }
        $panels = & $glass 'panel'
        $chromes = & $glass 'chrome'
        $raiseds = [ordered]@{ raised_flat = & $hex 'raised_flat' }
        foreach ($b in $Backdrops.Keys) {
            $raiseds["raised over panel clamp over $b"] = Get-Blend (& $hex 'raised') $panels["panel clamp over $b"] $v.Roles['raised'].Alpha
        }

        # The panel at its dense alpha is opacity-only glass; the clamp and panel_flat are not.
        $opacityOnlySurfaces = @(foreach ($b in $Backdrops.Keys) { "panel over $b" })
        $panelKind = { param([string]$Surface) if ($Surface -in $opacityOnlySurfaces) { 'opacityOnly' } else { 'panel' } }

        foreach ($role in $TextRoles + 'text_muted') {
            foreach ($s in $panels.Keys) { & $measure $role $panels[$s] $s (Get-ContrastFloor (& $panelKind $s) $role) }
            foreach ($s in $raiseds.Keys) { & $measure $role $raiseds[$s] $s (Get-ContrastFloor raised $role) }
        }
        foreach ($s in $chromes.Keys) { & $measure 'text' $chromes[$s] $s (Get-ContrastFloor chrome 'text') }
        foreach ($washRole in $WashRoles) {
            foreach ($s in $panels.Keys) {
                $washed = Get-Blend (& $hex $washRole) $panels[$s] $v.Wash
                foreach ($role in $TextRoles + 'text_muted') {
                    & $measure $role $washed "$washRole wash over $s" (Get-ContrastFloor (& $panelKind $s) $role -Wash)
                }
            }
        }
        # on_accent is drawn on accent, and on solid red where an app fills
        # with it (Cinnamon's destroy buttons and drag highlights).
        foreach ($fill in 'accent', 'red') { & $measure 'on_accent' (& $hex $fill) $fill (Get-ContrastFloor fill 'on_accent') }
    }
    return @{ Failures = $failures; Measurements = $measurements }
}

Export-ModuleMember -Function Read-Palette, Get-VariantKeys, Get-RequiredRoles, Get-SurfaceRoles, Get-ColorFilters, ConvertFrom-Hex, Get-Blend, Get-Contrast,
    Get-WashColor, Get-AnsiRole, Format-RoleColor, Get-GlassColor, Test-PaletteContrast
