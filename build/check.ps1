#requires -Version 7.0
<#
.SYNOPSIS
    Checks the palette and every port. Exits 1 if anything fails.

.DESCRIPTION
    1. Palette    Both variants exist, every required role is present and valid.
    2. Contrast   Text and color roles meet the contrast floor in PHILOSOPHY.md,
                  measured against panel_flat. Primary text must also pass on
                  chrome_flat, the only text role chrome carries. On raised_flat,
                  anything under 3:1 is reported as a warning. On a wash (a
                  color role at the variant's wash alpha over panel_flat),
                  text and text_dim need 4.5:1, muted and color roles 3:1.
    3. Structure  Every port has a README.md and a template/ folder.
    4. Port list  Every port has a valid port.json (except folders listed as
                  unlisted), and planned ports in Ports/ports.json do not
                  exist yet. A port's icon.svg and the "icon" credit in its
                  port.json come together, and the icon is plain shapes in
                  currentColor on a 24 x 24 viewBox (ADR 0007).
    5. Raw color  No hex, rgb(), or hsl() values in templates or values.json.
                  Add "hyaline-ignore" to a line to skip it (for example a CSS
                  id selector that happens to look like a hex color).
    6. Drift      Committed dist/ matches a fresh build.
    7. Leftovers  No unresolved {{placeholders}} in dist/.

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
    'backdrop', 'chrome', 'chrome_flat', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line',
    'text', 'text_dim', 'text_muted', 'accent', 'on_accent',
    'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange'
)
# Contrast floor from PHILOSOPHY.md
$TextFloor  = 4.5
$MutedFloor = 3.0
$RaisedFloor = 3.0   # warning only
$TextRoles  = @('text', 'text_dim', 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')
$WashRoles  = @('accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange')

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

function Get-Blend([string]$Fg, [string]$Bg, [double]$Alpha) {
    # The solid color of $Fg at $Alpha over $Bg, as #rrggbb.
    $out = foreach ($i in 1, 3, 5) {
        $f = [Convert]::ToInt32($Fg.Substring($i, 2), 16)
        $b = [Convert]::ToInt32($Bg.Substring($i, 2), 16)
        ([int][math]::Round($f * $Alpha + $b * (1 - $Alpha))).ToString('x2')
    }
    return '#' + ($out -join '')
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
        if (-not $v.ContainsKey('wash') -or -not ($v['wash'] -is [double] -or $v['wash'] -is [long]) -or $v['wash'] -le 0 -or $v['wash'] -ge 1) {
            Add-Failure "Palette: variants.$vKey.wash must be a number between 0 and 1."
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

        $onChrome = Get-Contrast (Get-RoleHex $roles['text']) (Get-RoleHex $roles['chrome_flat'])
        if ($onChrome -lt $TextFloor) {
            Add-Failure ('Contrast: {0}.text on chrome_flat is {1:0.00}:1, needs {2}:1.' -f $vKey, $onChrome, $TextFloor)
        }

        $wash = [double]$palette.variants[$vKey]['wash']
        foreach ($washRole in $WashRoles) {
            $washed = Get-Blend (Get-RoleHex $roles[$washRole]) $panel $wash
            foreach ($role in $TextRoles + 'text_muted') {
                $floor = if ($role -in 'text', 'text_dim') { $TextFloor } else { $MutedFloor }
                $onWash = Get-Contrast (Get-RoleHex $roles[$role]) $washed
                if ($onWash -lt $floor) {
                    Add-Failure ('Contrast: {0}.{1} on {2} wash is {3:0.00}:1, needs {4}:1.' -f $vKey, $role, $washRole, $onWash, $floor)
                }
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

# --- 4. Port list -------------------------------------------------------------
# Ports/<app>/port.json describes a port for the ports page.
# Ports/ports.json holds the category names, the planned ports, and the
# folders that are not app ports (unlisted), such as the preview page.

$before = $script:Failures.Count
$Platforms = @('windows', 'macos', 'linux', 'web')
$categories = @{}

function Test-PortMeta($Meta, [string]$Where, [bool]$Planned) {
    if ($Meta -isnot [System.Collections.IDictionary]) { Add-Failure "Port list: $Where must be a JSON object."; return }
    $known = @('name', 'category', 'tier', 'platforms', 'monogram') + $(if ($Planned) { 'folder' } else { 'icon' })
    foreach ($k in $Meta.Keys) {
        if ($k -notin $known) { Add-Failure "Port list: $Where has an unknown field '$k'." }
    }
    if (-not ($Meta['name'] -is [string] -and $Meta['name'].Trim())) {
        Add-Failure "Port list: $Where needs a 'name'."
    }
    if (-not ($Meta['category'] -is [string] -and $categories.ContainsKey($Meta['category']))) {
        Add-Failure "Port list: $Where has category '$($Meta['category'])'. Use one of: $(@($categories.Keys) -join ', ') (from Ports/ports.json)."
    }
    $tier = $Meta['tier']
    $tierOk = ($tier -is [long] -or $tier -is [int]) -and $tier -ge 1 -and $tier -le 3
    if (-not $tierOk -and -not ($Planned -and $null -eq $tier -and $Meta.Contains('tier'))) {
        $allowed = if ($Planned) { '1, 2, 3, or null' } else { '1, 2, or 3' }
        Add-Failure "Port list: $Where needs 'tier': $allowed."
    }
    $plat = $Meta['platforms']
    if (-not ($plat -is [System.Collections.IList] -and $plat.Count -gt 0)) {
        Add-Failure "Port list: $Where needs 'platforms', a list of: $($Platforms -join ', ')."
    }
    else {
        foreach ($p in $plat) {
            if ($p -notin $Platforms) { Add-Failure "Port list: $Where has platform '$p'. Use: $($Platforms -join ', ')." }
        }
    }
    if ($Meta.Contains('monogram') -and -not ($Meta['monogram'] -is [string] -and $Meta['monogram'] -match '^\S{1,3}$')) {
        Add-Failure "Port list: $Where has a 'monogram' that is not 1 to 3 characters."
    }
}

# Icons (ADR 0007): single-color shapes that take their color from the page.
# build/icon.ps1 writes them in this shape.
$IconShapes = @('path', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'rect', 'g')
$IconShapeAttrs = @('d', 'cx', 'cy', 'r', 'rx', 'ry', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'points', 'width', 'height',
    'transform', 'fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')
$IconRootAttrs = @('xmlns', 'viewBox', 'fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')
$IconMaxBytes = 8KB

function Test-PortIcon([string]$Dir, $Meta, [string]$Name) {
    $svgPath = Join-Path $Dir 'icon.svg'
    $hasSvg = Test-Path $svgPath
    $hasCredit = $Meta -is [System.Collections.IDictionary] -and $Meta.Contains('icon')
    if (-not $hasSvg -and -not $hasCredit) { return }
    if ($hasSvg -and -not $hasCredit) { Add-Failure "Icon: Ports/$Name/icon.svg has no 'icon' credit in port.json. build/icon.ps1 prints it."; return }
    if ($hasCredit -and -not $hasSvg) { Add-Failure "Icon: Ports/$Name/port.json has an 'icon' credit but there is no icon.svg."; return }

    # The credit
    $c = $Meta['icon']
    $where = "Ports/$Name/port.json icon"
    if ($c -isnot [System.Collections.IDictionary]) { Add-Failure "Icon: $where must be an object."; return }
    $fields = @('kind', 'set', 'name', 'author', 'source', 'license', 'mark')
    foreach ($k in $c.Keys) { if ($k -notin $fields) { Add-Failure "Icon: $where has an unknown field '$k'." } }
    foreach ($k in 'set', 'name', 'author', 'license') {
        if (-not ($c[$k] -is [string] -and $c[$k].Trim())) { Add-Failure "Icon: $where needs '$k'." }
    }
    if (-not ($c['source'] -is [string] -and $c['source'] -match '^https://\S+$')) { Add-Failure "Icon: $where needs 'source', an https URL." }
    if ($c['kind'] -eq 'brand') {
        if (-not ($c['mark'] -is [string] -and $c['mark'] -match '^https://\S+$')) {
            Add-Failure "Icon: $where is a brand mark, so it needs 'mark': an https URL showing the app allows its mark to be used."
        }
    }
    elseif ($c['kind'] -eq 'glyph') {
        if ($c.Contains('mark')) { Add-Failure "Icon: $where is a glyph, so it takes no 'mark'." }
    }
    else { Add-Failure "Icon: $where needs 'kind': brand or glyph." }

    # The file
    $rel = "Ports/$Name/icon.svg"
    if ((Get-Item $svgPath).Length -gt $IconMaxBytes) { Add-Failure "Icon: $rel is over $($IconMaxBytes / 1KB) KB. Icons are simple shapes."; return }
    $text = [System.IO.File]::ReadAllText($svgPath)
    $xml = [System.Xml.XmlDocument]::new()
    $xml.XmlResolver = $null
    try { $xml.LoadXml($text) }
    catch { Add-Failure "Icon: $rel is not valid XML: $($_.Exception.Message)"; return }
    if ($xml.DocumentType) { Add-Failure "Icon: $rel has a DOCTYPE. Remove it." }
    $root = $xml.DocumentElement
    if ($root.LocalName -ne 'svg' -or $root.NamespaceURI -ne 'http://www.w3.org/2000/svg') { Add-Failure "Icon: $rel is not an SVG."; return }
    if ($root.GetAttribute('viewBox') -ne '0 0 24 24') { Add-Failure "Icon: $rel needs viewBox=`"0 0 24 24`", so every card icon is the same size." }

    $paints = @('fill', 'stroke')
    $check = {
        param([System.Xml.XmlElement]$El, [string[]]$Allowed)
        foreach ($a in $El.Attributes) {
            if ($a.Prefix -eq 'xmlns' -or ($a.LocalName -notin $Allowed)) {
                Add-Failure "Icon: $rel has the attribute '$($a.Name)' on <$($El.LocalName)>, which icons may not use."
                continue
            }
            if ($a.LocalName -in $paints -and $a.Value -notin 'currentColor', 'none') {
                Add-Failure "Icon: $rel has $($a.LocalName)=`"$($a.Value)`". Icons use currentColor or none only, so the page colors them."
            }
        }
    }
    & $check $root $IconRootAttrs
    foreach ($node in $root.SelectNodes('.//node()')) {
        if ($node.NodeType -in 'Comment', 'Whitespace', 'SignificantWhitespace') { continue }
        if ($node.NodeType -ne 'Element') { Add-Failure "Icon: $rel has $($node.NodeType) content. Icons are shapes only."; continue }
        if ($node.LocalName -notin $IconShapes -or $node.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
            Add-Failure "Icon: $rel has <$($node.LocalName)>. Icons may use only: $($IconShapes -join ', ')."
            continue
        }
        & $check $node $IconShapeAttrs
    }
}

$indexPath = Join-Path $PortsRoot 'ports.json'
$index = $null
if (-not (Test-Path $indexPath)) {
    Add-Failure 'Port list: Ports/ports.json does not exist.'
}
else {
    try { $index = Get-Content -Raw -Path $indexPath | ConvertFrom-Json -AsHashtable }
    catch { Add-Failure "Port list: Ports/ports.json is not valid JSON: $($_.Exception.Message)" }
}
if ($index) {
    if ($index['categories'] -is [System.Collections.IDictionary] -and $index['categories'].Count -gt 0) {
        $categories = $index['categories']
    }
    else {
        Add-Failure "Port list: Ports/ports.json needs 'categories', an object of id to display name."
    }
    if ($index['planned'] -isnot [System.Collections.IList]) {
        Add-Failure "Port list: Ports/ports.json needs 'planned', a list (it can be empty)."
    }
}

$unlisted = @()
if ($index -and $index.Contains('unlisted')) {
    if ($index['unlisted'] -is [System.Collections.IList]) { $unlisted = @($index['unlisted']) }
    else { Add-Failure "Port list: 'unlisted' in Ports/ports.json must be a list of folder names." }
}
foreach ($u in $unlisted) {
    if (-not ($portDirs | Where-Object Name -eq $u)) { Add-Failure "Port list: unlisted folder Ports/$u does not exist." }
}

foreach ($dir in $portDirs) {
    if ($dir.Name -in $unlisted) { continue }
    $metaPath = Join-Path $dir.FullName 'port.json'
    $where = "Ports/$($dir.Name)/port.json"
    if (-not (Test-Path $metaPath)) { Add-Failure "Port list: $where does not exist."; continue }
    try { $meta = Get-Content -Raw -Path $metaPath | ConvertFrom-Json -AsHashtable }
    catch { Add-Failure "Port list: $where is not valid JSON: $($_.Exception.Message)"; continue }
    Test-PortMeta $meta $where $false
    Test-PortIcon $dir.FullName $meta $dir.Name
}

if ($index -and $index['planned'] -is [System.Collections.IList]) {
    $seen = @{}
    $portNames = @($portDirs | ForEach-Object Name)
    $i = 0
    foreach ($p in $index['planned']) {
        $where = "Ports/ports.json planned[$i]"
        $i++
        Test-PortMeta $p $where $true
        if ($p -isnot [System.Collections.IDictionary]) { continue }
        $folder = $p['folder']
        if (-not ($folder -is [string] -and $folder -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$')) {
            Add-Failure "Port list: $where needs 'folder', the future Ports/ folder name (lowercase, hyphenated)."
            continue
        }
        if ($seen.ContainsKey($folder)) { Add-Failure "Port list: '$folder' is planned twice." }
        $seen[$folder] = $true
        if ($folder -in $portNames) {
            Add-Failure "Port list: Ports/$folder exists, so remove it from 'planned' in Ports/ports.json."
        }
    }
}
Write-Section 'Port list' $before

# --- 5. Raw colors in templates ---------------------------------------------

$before = $script:Failures.Count
$hexPattern  = '(?<![\w&])#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b'
$funcPattern = '\b(?:rgba?|hsla?)\(\s*[\d.]'
foreach ($dir in $portDirs) {
    $templateDir = Join-Path $dir.FullName 'template'
    if (-not (Test-Path $templateDir)) { continue }
    $scan = @(Get-ChildItem -Path $templateDir -Recurse -File -Force)
    $valuesPath = Join-Path $dir.FullName 'values.json'
    if (Test-Path $valuesPath) { $scan += Get-Item -Path $valuesPath }
    foreach ($file in $scan) {
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

# --- 6. Drift ---------------------------------------------------------------

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

# --- 7. Unresolved placeholders in dist --------------------------------------

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
