# The palette: loading and validating palette/palette.json, and every color
# calculation the build and the checks share (filters, wash, contrast).
# One place, so what the checks measure is what the build writes.

Set-StrictMode -Version Latest

$Invariant = [cultureinfo]::InvariantCulture

# Both variants, always (PHILOSOPHY.md: two variants, one theme).
$VariantKeys = @('dark', 'light')

$RequiredRoles = @(
    'backdrop', 'chrome', 'chrome_flat', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line',
    'text', 'text_dim', 'text_muted', 'accent', 'on_accent',
    'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange'
)

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
}

# Terminal ANSI slots (ADR 0001). The six hues and their bright versions
# reuse their namesake role. Black and white map to neutrals by brightness.
$AnsiHues = @('red', 'green', 'yellow', 'blue', 'magenta', 'cyan')
$AnsiNeutrals = @{
    dark  = @{ black = 'raised_flat'; bright_black = 'text_muted'; white = 'text_dim'; bright_white = 'text' }
    light = @{ black = 'text';        bright_black = 'text_muted'; white = 'line';     bright_white = 'raised_flat' }
}

# Contrast floor (PHILOSOPHY.md).
$TextFloor   = 4.5
$MutedFloor  = 3.0
$RaisedFloor = 3.0   # warning only
$TextRoles   = @('text', 'text_dim', 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')

function Read-Palette {
    <#
    .SYNOPSIS
        Loads palette.json. Returns @{ Meta; Variants; Errors }.
    .DESCRIPTION
        Variants is an ordered map of 'dark' and 'light' to
        @{ Key; Name; Mode; Wash; Roles }, where Roles maps a role name to
        @{ Hex (lowercase #rrggbb); Alpha }. Errors lists every problem found.
        When Errors is not empty, Variants may be incomplete: do not build.
    #>
    param([Parameter(Mandatory)][string]$Path)
    $errors = [System.Collections.Generic.List[string]]::new()
    $result = @{ Meta = @{}; Variants = [ordered]@{}; Errors = $errors }

    if (-not (Test-Path $Path)) { $errors.Add('palette/palette.json does not exist.'); return $result }
    try { $raw = Get-Content -Raw -Path $Path | ConvertFrom-Json -AsHashtable }
    catch { $errors.Add("palette/palette.json is not valid JSON: $($_.Exception.Message)"); return $result }

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
        if (-not ($wash -is [double] -or $wash -is [long] -or $wash -is [int]) -or $wash -le 0 -or $wash -ge 1) {
            $errors.Add("variants.$vKey.wash must be a number between 0 and 1.")
            $wash = $null
        }
        $roles = @{}
        if ($v['roles'] -isnot [System.Collections.IDictionary]) { $errors.Add("variants.$vKey.roles is missing.") }
        else {
            foreach ($role in $RequiredRoles) {
                if (-not $v['roles'].Contains($role)) { $errors.Add("$vKey is missing role '$role'.") }
            }
            foreach ($rKey in @($v['roles'].Keys)) {
                $r = $v['roles'][$rKey]
                $hex = $null; $alpha = 1.0
                if ($r -is [string]) { $hex = $r }
                elseif ($r -is [System.Collections.IDictionary]) {
                    $hex = [string]$r['hex']
                    if ($r.Contains('alpha')) {
                        $alpha = $r['alpha']
                        if (-not ($alpha -is [double] -or $alpha -is [long] -or $alpha -is [int]) -or $alpha -lt 0 -or $alpha -gt 1) {
                            $errors.Add("$vKey.$rKey alpha must be between 0 and 1.")
                            continue
                        }
                    }
                }
                if ($null -eq $hex -or $hex -notmatch '^#[0-9a-fA-F]{6}$') {
                    $errors.Add("$vKey.$rKey is not a valid #rrggbb value (or { hex, alpha }).")
                    continue
                }
                $roles[$rKey] = @{ Hex = $hex.ToLowerInvariant(); Alpha = [double]$alpha }
            }
        }
        $result.Variants[$vKey] = @{
            Key = $vKey; Name = [string]$v['name']; Mode = [string]$v['mode']
            Wash = if ($null -ne $wash) { [double]$wash } else { $null }
            Roles = $roles
        }
    }
    return $result
}

function Get-VariantKeys { return $VariantKeys }
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
    }
}

function Test-PaletteContrast {
    <#
    .SYNOPSIS
        Measures the contrast floor in PHILOSOPHY.md on a valid palette.
        Returns @{ Failures; Warnings } as message lists.
    #>
    param($Palette)
    $failures = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    foreach ($v in $Palette.Variants.Values) {
        $k = $v.Key
        $hex = { param($r) $v.Roles[$r].Hex }
        $panel = & $hex 'panel_flat'
        $raised = & $hex 'raised_flat'
        foreach ($role in $TextRoles + 'text_muted') {
            $floor = if ($role -eq 'text_muted') { $MutedFloor } else { $TextFloor }
            $on = Get-Contrast (& $hex $role) $panel
            if ($on -lt $floor) { $failures.Add(('{0}.{1} on panel_flat is {2:0.00}:1, needs {3}:1.' -f $k, $role, $on, $floor)) }
            $on = Get-Contrast (& $hex $role) $raised
            if ($on -lt $RaisedFloor) { $warnings.Add(('{0}.{1} on raised_flat is {2:0.00}:1, under {3}:1.' -f $k, $role, $on, $RaisedFloor)) }
        }
        $on = Get-Contrast (& $hex 'text') (& $hex 'chrome_flat')
        if ($on -lt $TextFloor) { $failures.Add(('{0}.text on chrome_flat is {1:0.00}:1, needs {2}:1.' -f $k, $on, $TextFloor)) }
        foreach ($washRole in $WashRoles) {
            $washed = Get-WashColor $v $washRole
            foreach ($role in $TextRoles + 'text_muted') {
                $floor = if ($role -in 'text', 'text_dim') { $TextFloor } else { $MutedFloor }
                $on = Get-Contrast (& $hex $role) $washed
                if ($on -lt $floor) { $failures.Add(('{0}.{1} on {2} wash is {3:0.00}:1, needs {4}:1.' -f $k, $role, $washRole, $on, $floor)) }
            }
        }
        $on = Get-Contrast (& $hex 'on_accent') (& $hex 'accent')
        if ($on -lt $TextFloor) { $failures.Add(('{0}.on_accent on accent is {1:0.00}:1, needs {2}:1.' -f $k, $on, $TextFloor)) }
    }
    return @{ Failures = $failures; Warnings = $warnings }
}

Export-ModuleMember -Function Read-Palette, Get-VariantKeys, Get-ColorFilters, Get-Blend, Get-Contrast,
    Get-WashColor, Get-AnsiRole, Format-RoleColor, Test-PaletteContrast
