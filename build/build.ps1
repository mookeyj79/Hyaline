#requires -Version 7.0
<#
.SYNOPSIS
    Builds theme files for every port from palette/palette.json.

.DESCRIPTION
    For each folder in Ports/ that has a template/ folder, every file in
    template/ is rendered once per palette variant into dist/<variant>/.
    File names and folder structure are kept. Placeholders are allowed in
    file contents and in file names.

    Placeholders:
        {{role}}           #rrggbb
        {{role|nohash}}    rrggbb
        {{role|rgb}}       r, g, b
        {{role|rgba}}      rgba(r, g, b, a)
        {{role|hexa}}      #rrggbbaa
        {{role|alpha}}     a
        {{role|percent}}   alpha as a whole percent, 0 to 100
        {{role|wash}}      #rrggbbaa using the variant's wash alpha, for
                           see-through highlights (selection, diff lines)
        {{role|clear}}     #rrggbb00, fully transparent, for app settings
                           that must be switched off with a color
        {{ansi.<slot>}}    the role for a terminal ANSI slot (ADR 0001):
                           black, red, green, yellow, blue, magenta, cyan,
                           white, and bright_<each>. Takes the same filters.
        {{meta.name}}      {{meta.version}}
        {{variant.name}}   {{variant.mode}}   {{variant.key}}
        {{port.<key>}}     a per-variant app value (not a color) from
                           Ports/<port>/values.json:
                           { "dark": { "<key>": "..." }, "light": { ... } }

.PARAMETER Port
    Build only this port (the folder name under Ports/).

.PARAMETER Destination
    Write output to <Destination>/<port>/<variant>/ instead of
    Ports/<port>/dist/<variant>/. Used by check.ps1 to detect drift.

.PARAMETER Quiet
    Print nothing on success.

.EXAMPLE
    pwsh build/build.ps1

.EXAMPLE
    pwsh build/build.ps1 -Port windows-terminal
#>
[CmdletBinding()]
param(
    [string]$Port,
    [string]$Destination,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot    = Split-Path -Parent $PSScriptRoot
$PalettePath = Join-Path $RepoRoot 'palette' 'palette.json'
$PortsRoot   = Join-Path $RepoRoot 'Ports'
$Placeholder = '\{\{\s*([A-Za-z_][A-Za-z0-9_.]*)\s*(?:\|\s*([A-Za-z0-9]+)\s*)?\}\}'
$Invariant   = [cultureinfo]::InvariantCulture

function Read-Palette {
    if (-not (Test-Path $PalettePath)) { throw "Palette not found: $PalettePath" }
    $p = Get-Content -Raw -Path $PalettePath | ConvertFrom-Json -AsHashtable
    foreach ($key in 'meta', 'variants') {
        if (-not $p.ContainsKey($key)) { throw "palette.json is missing '$key'." }
    }
    foreach ($vKey in @($p.variants.Keys)) {
        $v = $p.variants[$vKey]
        $roles = @{}
        foreach ($rKey in @($v.roles.Keys)) {
            $raw = $v.roles[$rKey]
            if ($raw -is [string]) {
                $hex = $raw; $alpha = 1.0
            }
            elseif ($raw -is [System.Collections.IDictionary]) {
                $hex = [string]$raw['hex']
                $alpha = if ($raw.Contains('alpha')) { [double]$raw['alpha'] } else { 1.0 }
            }
            else {
                throw "Role '$rKey' in variant '$vKey' must be a hex string or { hex, alpha }."
            }
            if ($hex -notmatch '^#[0-9a-fA-F]{6}$') {
                throw "Role '$rKey' in variant '$vKey' has an invalid hex value: '$hex'."
            }
            if ($alpha -lt 0 -or $alpha -gt 1) {
                throw "Role '$rKey' in variant '$vKey' has an alpha outside 0 to 1."
            }
            $roles[$rKey] = @{ hex = $hex.ToLowerInvariant(); alpha = $alpha }
        }
        if ($v.ContainsKey('wash')) {
            $wash = [double]$v['wash']
            if ($wash -le 0 -or $wash -ge 1) { throw "Variant '$vKey' has a wash outside 0 to 1." }
            foreach ($r in @($roles.Values)) { $r['wash'] = $wash }
        }
        $v['_roles'] = $roles
        $v['_key'] = $vKey
    }
    return $p
}

# Terminal ANSI slots, per ADR 0001. The six hues and their bright versions
# reuse their namesake role. Black and white map to neutrals by brightness,
# which differs between dark and light variants.
$AnsiRoles = @{
    red = 'red'; green = 'green'; yellow = 'yellow'; blue = 'blue'
    magenta = 'magenta'; cyan = 'cyan'
}
$AnsiNeutrals = @{
    dark  = @{ black = 'raised_flat'; bright_black = 'text_muted'; white = 'text_dim'; bright_white = 'text' }
    light = @{ black = 'text';        bright_black = 'text_muted'; white = 'line';     bright_white = 'raised_flat' }
}

function Get-AnsiRole {
    param([string]$Slot, [string]$Mode)
    if ($AnsiNeutrals.ContainsKey($Mode) -and $AnsiNeutrals[$Mode].ContainsKey($Slot)) {
        return $AnsiNeutrals[$Mode][$Slot]
    }
    $hue = $Slot -replace '^bright_', ''
    if ($AnsiRoles.ContainsKey($hue)) { return $AnsiRoles[$hue] }
    return $null
}

function Format-Role {
    param($Role, [string]$Filter, [string]$Token)
    $hex = $Role.hex
    $r = [Convert]::ToInt32($hex.Substring(1, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(3, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(5, 2), 16)
    $a = ([double]$Role.alpha).ToString('0.###', $Invariant)
    switch ($Filter) {
        ''       { return $hex }
        'nohash' { return $hex.Substring(1) }
        'rgb'    { return "$r, $g, $b" }
        'rgba'   { return "rgba($r, $g, $b, $a)" }
        'hexa'   { return $hex + ([int][math]::Round($Role.alpha * 255)).ToString('x2') }
        'alpha'  { return $a }
        'percent' { return [string][int][math]::Round($Role.alpha * 100) }
        'clear'  { return $hex + '00' }
        'wash'   {
            if (-not $Role.Contains('wash')) { throw "The palette has no wash for this variant: $Token." }
            return $hex + ([int][math]::Round($Role.wash * 255)).ToString('x2')
        }
        default  { throw "Unknown filter '$Filter' in $Token." }
    }
}

function Resolve-Token {
    param([string]$Name, [string]$Filter, $Palette, $Variant, [string]$Source, $PortValues)
    $token = '{{' + $Name + $(if ($Filter) { "|$Filter" }) + '}}'
    $value = $null
    switch -Regex ($Name) {
        '^meta\.(.+)$' {
            $k = $Matches[1]
            if ($Palette.meta.ContainsKey($k)) { $value = [string]$Palette.meta[$k] }
            break
        }
        '^variant\.(.+)$' {
            $k = $Matches[1]
            if ($k -eq 'key') { $value = $Variant['_key'] }
            elseif ($k -in 'name', 'mode') { $value = [string]$Variant[$k] }
            break
        }
        '^port\.(.+)$' {
            $k = $Matches[1]
            $set = if ($PortValues) { $PortValues[$Variant['_key']] } else { $null }
            if ($set -is [System.Collections.IDictionary] -and $set.Contains($k)) { $value = [string]$set[$k] }
            break
        }
        '^ansi\.(.+)$' {
            $role = Get-AnsiRole -Slot $Matches[1] -Mode ([string]$Variant['mode'])
            if ($role -and $Variant['_roles'].ContainsKey($role)) {
                return Format-Role -Role $Variant['_roles'][$role] -Filter $Filter -Token $token
            }
            break
        }
        default {
            if ($Variant['_roles'].ContainsKey($Name)) {
                return Format-Role -Role $Variant['_roles'][$Name] -Filter $Filter -Token $token
            }
        }
    }
    if ($null -eq $value) { throw "Unknown placeholder $token in $Source." }
    if ($Filter) { throw "Filters only apply to color roles: $token in $Source." }
    return $value
}

function Expand-Text {
    param([string]$Text, $Palette, $Variant, [string]$Source, $PortValues)
    return $Text -creplace $Placeholder, {
        Resolve-Token -Name $_.Groups[1].Value -Filter $_.Groups[2].Value `
            -Palette $Palette -Variant $Variant -Source $Source -PortValues $PortValues
    }
}

function Read-Template {
    # Returns the text and its encoding, or marks the file as binary.
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $enc = $null
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $enc = [System.Text.UTF8Encoding]::new($true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $enc = [System.Text.UnicodeEncoding]::new($false, $true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $enc = [System.Text.UnicodeEncoding]::new($true, $true)
    }
    elseif ([Array]::IndexOf($bytes, [byte]0) -ge 0) {
        return @{ Binary = $true; Bytes = $bytes }
    }
    else {
        $enc = [System.Text.UTF8Encoding]::new($false)
    }
    $skip = $enc.GetPreamble().Length
    return @{
        Binary   = $false
        Encoding = $enc
        Text     = $enc.GetString($bytes, $skip, $bytes.Length - $skip)
    }
}

function Write-Rendered {
    param([string]$Path, [string]$Text, $Encoding)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bytes = [byte[]](@($Encoding.GetPreamble()) + @($Encoding.GetBytes($Text)))
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

# --- Main -------------------------------------------------------------------

$palette = Read-Palette

$portDirs = @()
if (Test-Path $PortsRoot) {
    $portDirs = @(Get-ChildItem -Path $PortsRoot -Directory | Sort-Object Name)
}
if ($Port) {
    $portDirs = @($portDirs | Where-Object { $_.Name -eq $Port })
    if ($portDirs.Count -eq 0) { throw "Port not found: Ports/$Port" }
}

$built = 0
$fileCount = 0
foreach ($dir in $portDirs) {
    $templateDir = Join-Path $dir.FullName 'template'
    if (-not (Test-Path $templateDir)) {
        if (-not $Quiet) { Write-Warning "Skipping $($dir.Name): no template/ folder." }
        continue
    }
    $outRoot = if ($Destination) { Join-Path $Destination $dir.Name } else { Join-Path $dir.FullName 'dist' }
    $files = @(Get-ChildItem -Path $templateDir -Recurse -File -Force)
    $valuesPath = Join-Path $dir.FullName 'values.json'
    $portValues = if (Test-Path $valuesPath) { Get-Content -Raw -Path $valuesPath | ConvertFrom-Json -AsHashtable } else { $null }

    foreach ($vKey in @($palette.variants.Keys)) {
        $variant = $palette.variants[$vKey]
        $outDir = Join-Path $outRoot $vKey
        if (Test-Path $outDir) { Remove-Item -Path $outDir -Recurse -Force }
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null

        foreach ($file in $files) {
            $rel = [System.IO.Path]::GetRelativePath($templateDir, $file.FullName)
            $source = "Ports/$($dir.Name)/template/$($rel -replace '\\', '/')"
            $relOut = Expand-Text -Text $rel -Palette $palette -Variant $variant -Source "$source (file name)" -PortValues $portValues
            $target = Join-Path $outDir $relOut

            $tpl = Read-Template -Path $file.FullName
            if ($tpl.Binary) {
                $targetDir = Split-Path -Parent $target
                if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                [System.IO.File]::WriteAllBytes($target, $tpl.Bytes)
            }
            else {
                $text = Expand-Text -Text $tpl.Text -Palette $palette -Variant $variant -Source $source -PortValues $portValues
                Write-Rendered -Path $target -Text $text -Encoding $tpl.Encoding
            }
            $fileCount++
        }
    }
    $built++
    if (-not $Quiet) { Write-Host "Built $($dir.Name)" }
}

if (-not $Quiet) {
    $name = $palette.meta['name']
    $version = $palette.meta['version']
    if ($built -eq 0) {
        Write-Host "$name ${version}: no ports to build yet."
    }
    else {
        Write-Host "$name ${version}: $built port(s), $fileCount file(s) written."
    }
}
