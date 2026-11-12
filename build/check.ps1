#requires -Version 7.0
<#
.SYNOPSIS
    Checks the palette and every port. Exits 1 if anything fails.

.DESCRIPTION
    1. Palette    Both variants exist, every required role is present and valid.
    2. Contrast   Text and color roles meet the contrast floor in PHILOSOPHY.md,
                  measured against panel_flat. On raised_flat, anything under
                  3:1 is reported as a warning.
    3. Structure  Every port has a README.md and a template/ folder.
    4. Raw color  No hex, rgb(), or hsl() values in templates.
                  Add "hyaline-ignore" to a line to skip it (for example a CSS
                  id selector that happens to look like a hex color).
    5. Drift      Committed dist/ matches a fresh build.
    6. Leftovers  No unresolved {{placeholders}} in dist/.

.EXAMPLE
    pwsh build/check.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot    = Split-Path -Parent $PSScriptRoot
$PalettePath = Join-Path $RepoRoot 'palette' 'palette.json'
$PortsRoot   = Join-Path $RepoRoot 'Ports'
$BuildScript = Join-Path $PSScriptRoot 'build.ps1'
$Placeholder = '\{\{\s*[A-Za-z_][A-Za-z0-9_.]*\s*(?:\|\s*[A-Za-z0-9]+\s*)?\}\}'

$RequiredRoles = @(
    'backdrop', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line',
    'text', 'text_dim', 'text_muted', 'accent', 'on_accent',
    'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange'
)
# Contrast floor from PHILOSOPHY.md
$TextFloor  = 4.5
$MutedFloor = 3.0
$RaisedFloor = 3.0   # warning only
$TextRoles  = @('text', 'text_dim', 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Warnings = [System.Collections.Generic.List[string]]::new()
function Add-Failure([string]$Message) { $script:Failures.Add($Message) }
function Add-Warning([string]$Message) { $script:Warnings.Add($Message) }

function Write-Section([string]$Title, [int]$FailuresBefore) {
    $status = if ($script:Failures.Count -gt $FailuresBefore) { 'FAIL' } else { 'ok' }
    Write-Host ('{0,-10} {1}' -f $Title, $status)
}

function Get-RoleHex($Raw) {
    if ($Raw -is [string]) { return $Raw }
    if ($Raw -is [System.Collections.IDictionary]) { return [string]$Raw['hex'] }
    return $null
}

function Get-Luminance([string]$Hex) {
    $channels = foreach ($i in 1, 3, 5) {
        $c = [Convert]::ToInt32($Hex.Substring($i, 2), 16) / 255
        if ($c -le 0.03928) { $c / 12.92 } else { [math]::Pow(($c + 0.055) / 1.055, 2.4) }
    }
    return 0.2126 * $channels[0] + 0.7152 * $channels[1] + 0.0722 * $channels[2]
}

function Get-Contrast([string]$A, [string]$B) {
    $la = Get-Luminance $A
    $lb = Get-Luminance $B
    if ($la -lt $lb) { $la, $lb = $lb, $la }
    return ($la + 0.05) / ($lb + 0.05)
}

function Test-IsBinary([byte[]]$Bytes) {
    return ([Array]::IndexOf($Bytes, [byte]0) -ge 0)
}

function Get-Tree([string]$Root) {
    # Relative path -> content signature. Text is compared with line endings
    # normalized, so a CRLF checkout does not count as drift.
    $tree = @{}
    if (-not (Test-Path $Root)) { return $tree }
    foreach ($file in Get-ChildItem -Path $Root -Recurse -File -Force) {
        $rel = [System.IO.Path]::GetRelativePath($Root, $file.FullName) -replace '\\', '/'
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if (Test-IsBinary $bytes) {
            $tree[$rel] = 'bin:' + (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        }
        else {
            $tree[$rel] = 'txt:' + ([System.Text.Encoding]::UTF8.GetString($bytes) -replace "`r`n", "`n")
        }
    }
    return $tree
}

# --- 1. Palette -------------------------------------------------------------

$before = $script:Failures.Count
$palette = $null
if (-not (Test-Path $PalettePath)) {
    Add-Failure 'palette/palette.json does not exist.'
}
else {
    try {
        $palette = Get-Content -Raw -Path $PalettePath | ConvertFrom-Json -AsHashtable
    }
    catch {
        Add-Failure "palette/palette.json is not valid JSON: $($_.Exception.Message)"
    }
}

if ($palette) {
    foreach ($k in 'name', 'version') {
        if (-not ($palette.ContainsKey('meta') -and $palette.meta.ContainsKey($k))) {
            Add-Failure "Palette: meta.$k is missing."
        }
    }
    if (-not $palette.ContainsKey('variants')) {
        Add-Failure 'Palette: variants is missing.'
        $palette = $null
    }
}

if ($palette) {
    foreach ($vKey in 'dark', 'light') {
        if (-not $palette.variants.ContainsKey($vKey)) {
            Add-Failure "Palette: variant '$vKey' is missing."
            continue
        }
        $v = $palette.variants[$vKey]
        if (-not $v.ContainsKey('name')) { Add-Failure "Palette: variants.$vKey.name is missing." }
        if (-not $v.ContainsKey('mode') -or $v['mode'] -ne $vKey) {
            Add-Failure "Palette: variants.$vKey.mode must be '$vKey'."
        }
        if (-not $v.ContainsKey('roles')) { Add-Failure "Palette: variants.$vKey.roles is missing."; continue }
        foreach ($role in $RequiredRoles) {
            if (-not $v.roles.ContainsKey($role)) {
                Add-Failure "Palette: $vKey is missing role '$role'."
            }
        }
        foreach ($rKey in @($v.roles.Keys)) {
            $raw = $v.roles[$rKey]
            $hex = Get-RoleHex $raw
            if ($null -eq $hex -or $hex -notmatch '^#[0-9a-fA-F]{6}$') {
                Add-Failure "Palette: $vKey.$rKey is not a valid #rrggbb value."
            }
            if ($raw -is [System.Collections.IDictionary] -and $raw.Contains('alpha')) {
                $a = [double]$raw['alpha']
                if ($a -lt 0 -or $a -gt 1) { Add-Failure "Palette: $vKey.$rKey alpha must be between 0 and 1." }
            }
        }
    }
}
Write-Section 'Palette' $before
$paletteOk = ($script:Failures.Count -eq $before)

# --- 2. Contrast ------------------------------------------------------------

$before = $script:Failures.Count
if ($paletteOk) {
    foreach ($vKey in 'dark', 'light') {
        $roles = $palette.variants[$vKey].roles
        $panel = Get-RoleHex $roles['panel_flat']
        $raised = Get-RoleHex $roles['raised_flat']

        foreach ($role in $TextRoles + 'text_muted') {
            $floor = if ($role -eq 'text_muted') { $MutedFloor } else { $TextFloor }
            $hex = Get-RoleHex $roles[$role]

            $onPanel = Get-Contrast $hex $panel
            if ($onPanel -lt $floor) {
                Add-Failure ('Contrast: {0}.{1} on panel_flat is {2:0.00}:1, needs {3}:1.' -f $vKey, $role, $onPanel, $floor)
            }
            $onRaised = Get-Contrast $hex $raised
            if ($onRaised -lt $RaisedFloor) {
                Add-Warning ('Contrast: {0}.{1} on raised_flat is {2:0.00}:1, under {3}:1.' -f $vKey, $role, $onRaised, $RaisedFloor)
            }
        }

        $onAccent = Get-Contrast (Get-RoleHex $roles['on_accent']) (Get-RoleHex $roles['accent'])
        if ($onAccent -lt $TextFloor) {
            Add-Failure ('Contrast: {0}.on_accent on accent is {1:0.00}:1, needs {2}:1.' -f $vKey, $onAccent, $TextFloor)
        }
    }
    Write-Section 'Contrast' $before
}
else {
    Write-Host ('{0,-10} {1}' -f 'Contrast', 'skipped (fix the palette first)')
}

# --- Ports ------------------------------------------------------------------

$portDirs = @()
if (Test-Path $PortsRoot) {
    $portDirs = @(Get-ChildItem -Path $PortsRoot -Directory | Sort-Object Name)
}

# --- 3. Structure -----------------------------------------------------------

$before = $script:Failures.Count
foreach ($dir in $portDirs) {
    if (-not (Test-Path (Join-Path $dir.FullName 'README.md'))) {
        Add-Failure "Structure: Ports/$($dir.Name) has no README.md."
    }
    if (-not (Test-Path (Join-Path $dir.FullName 'template'))) {
        Add-Failure "Structure: Ports/$($dir.Name) has no template/ folder."
    }
}
Write-Section 'Structure' $before

# --- 4. Raw colors in templates ---------------------------------------------

$before = $script:Failures.Count
$hexPattern  = '(?<![\w&])#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b'
$funcPattern = '\b(?:rgba?|hsla?)\(\s*[\d.]'
foreach ($dir in $portDirs) {
    $templateDir = Join-Path $dir.FullName 'template'
    if (-not (Test-Path $templateDir)) { continue }
    foreach ($file in Get-ChildItem -Path $templateDir -Recurse -File -Force) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ((Test-IsBinary $bytes) -and -not ($bytes.Length -ge 2 -and $bytes[0] -in 0xFF, 0xFE)) { continue }
        $rel = [System.IO.Path]::GetRelativePath($RepoRoot, $file.FullName) -replace '\\', '/'
        $lineNo = 0
        foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
            $lineNo++
            if ($line -match 'hyaline-ignore') { continue }
            foreach ($pattern in $hexPattern, $funcPattern) {
                $m = [regex]::Match($line, $pattern)
                if ($m.Success) {
                    Add-Failure "Raw color: ${rel}:$lineNo contains '$($m.Value)'. Use a {{role}} placeholder."
                }
            }
        }
    }
}
Write-Section 'Raw color' $before

# --- 5. Drift ---------------------------------------------------------------

$before = $script:Failures.Count
if ($paletteOk -and $portDirs.Count -gt 0) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('hyaline-check-' + [guid]::NewGuid().ToString('N'))
    try {
        $buildOk = $true
        try {
            & $BuildScript -Destination $tmp -Quiet
        }
        catch {
            $buildOk = $false
            Add-Failure "Build: $($_.Exception.Message)"
        }
        if ($buildOk) {
            foreach ($dir in $portDirs) {
                if (-not (Test-Path (Join-Path $dir.FullName 'template'))) { continue }
                $fresh = Get-Tree (Join-Path $tmp $dir.Name)
                $committed = Get-Tree (Join-Path $dir.FullName 'dist')
                $port = "Ports/$($dir.Name)/dist"
                foreach ($rel in $fresh.Keys) {
                    if (-not $committed.ContainsKey($rel)) {
                        Add-Failure "Drift: $port/$rel is missing. Run build/build.ps1."
                    }
                    elseif ($committed[$rel] -cne $fresh[$rel]) {
                        Add-Failure "Drift: $port/$rel is out of date. Run build/build.ps1."
                    }
                }
                foreach ($rel in $committed.Keys) {
                    if (-not $fresh.ContainsKey($rel)) {
                        Add-Failure "Drift: $port/$rel is not produced by the build. Delete it or run build/build.ps1."
                    }
                }
            }
        }
    }
    finally {
        if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force }
    }
}
Write-Section 'Drift' $before

# --- 6. Unresolved placeholders in dist --------------------------------------

$before = $script:Failures.Count
foreach ($dir in $portDirs) {
    $distDir = Join-Path $dir.FullName 'dist'
    if (-not (Test-Path $distDir)) { continue }
    foreach ($file in Get-ChildItem -Path $distDir -Recurse -File -Force) {
        $rel = [System.IO.Path]::GetRelativePath($RepoRoot, $file.FullName) -replace '\\', '/'
        if ($file.Name -match $Placeholder) {
            Add-Failure "Leftover: $rel has a placeholder in its file name."
        }
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if (Test-IsBinary $bytes) { continue }
        $m = [regex]::Match([System.Text.Encoding]::UTF8.GetString($bytes), $Placeholder)
        if ($m.Success) {
            Add-Failure "Leftover: $rel still contains '$($m.Value)'."
        }
    }
}
Write-Section 'Leftovers' $before

# --- Summary ----------------------------------------------------------------

Write-Host ''
if ($portDirs.Count -eq 0) { Write-Host 'No ports yet. Palette checks only.' }

foreach ($w in $script:Warnings) { Write-Host "warning: $w" -ForegroundColor Yellow }
foreach ($f in $script:Failures) { Write-Host "FAIL: $f" -ForegroundColor Red }

if ($script:Failures.Count -gt 0) {
    Write-Host ''
    Write-Host "$($script:Failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "All checks passed ($($portDirs.Count) port(s), $($script:Warnings.Count) warning(s))."
exit 0
