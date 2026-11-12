#requires -Version 7.0
<#
.SYNOPSIS
    Finds and fetches a single-color icon for a port's card on the ports page.

.DESCRIPTION
    Icons come from two open sets, pinned to the versions below (ADR 0007):

        Brand mark   Simple Icons, filled app logos (CC0 unless noted)
        Glyph        Lucide, outlined symbols (ISC, a few MIT from Feather)

    -Search lists matches in both sets. -Brand or -Glyph fetches one icon,
    keeps only its shapes, makes it take its color from the page
    (currentColor), and writes Ports/<Port>/icon.svg. It then prints the
    "icon" object to paste into Ports/<Port>/port.json. Run build/check.ps1
    afterwards: it validates the icon and the credit.

    Downloads go to a temp folder and are cached there.

.PARAMETER Search
    Words to look for: app name, alias, or what the app is ("terminal").

.PARAMETER Port
    The port folder name under Ports/ to write icon.svg into.

.PARAMETER Brand
    A Simple Icons slug, from -Search. Needs -Mark.

.PARAMETER Mark
    For -Brand: an https URL showing the app allows its mark to be used,
    such as its license or brand guidelines. Find this yourself; it is the
    one thing the script cannot check.

.PARAMETER Glyph
    A Lucide icon name, from -Search.

.EXAMPLE
    pwsh build/icon.ps1 -Search starship

.EXAMPLE
    pwsh build/icon.ps1 -Port starship -Brand starship -Mark https://github.com/starship/starship/blob/main/LICENSE

.EXAMPLE
    pwsh build/icon.ps1 -Port windows-terminal -Glyph square-terminal
#>
[CmdletBinding(DefaultParameterSetName = 'Search')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Search', Position = 0)]
    [string]$Search,

    [Parameter(Mandatory, ParameterSetName = 'Brand')]
    [Parameter(Mandatory, ParameterSetName = 'Glyph')]
    [string]$Port,

    [Parameter(Mandatory, ParameterSetName = 'Brand')]
    [string]$Brand,

    [Parameter(Mandatory, ParameterSetName = 'Brand')]
    [string]$Mark,

    [Parameter(Mandatory, ParameterSetName = 'Glyph')]
    [string]$Glyph
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SimpleIconsVersion = '16.37.0'
$LucideVersion      = '1.72.0'
$SimpleIconsBase    = "https://cdn.jsdelivr.net/npm/simple-icons@$SimpleIconsVersion"
$LucideBase         = "https://cdn.jsdelivr.net/npm/lucide-static@$LucideVersion"

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$CacheDir  = Join-Path ([System.IO.Path]::GetTempPath()) 'hyaline-icons'

# Elements and attributes an icon may keep. check.ps1 enforces the same list.
$Shapes    = @('path', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'rect', 'g')
$ShapeAttrs = @('d', 'cx', 'cy', 'r', 'rx', 'ry', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'points', 'width', 'height',
    'transform', 'fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')
$RootAttrs = @('fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')

function Get-Cached([string]$Url, [string]$Name) {
    if (-not (Test-Path $CacheDir)) { New-Item -ItemType Directory -Path $CacheDir | Out-Null }
    $path = Join-Path $CacheDir $Name
    if (-not (Test-Path $path)) {
        try { Invoke-WebRequest -Uri $Url -OutFile $path }
        catch { Remove-Item $path -ErrorAction SilentlyContinue; throw "Could not download $Url : $($_.Exception.Message)" }
    }
    return [System.IO.File]::ReadAllText($path)
}

function Get-SimpleIcons {
    $json = Get-Cached "$SimpleIconsBase/data/simple-icons.json" "simple-icons-$SimpleIconsVersion.json"
    return @($json | ConvertFrom-Json -AsHashtable)
}

function Get-LucideTags {
    $json = Get-Cached "$LucideBase/tags.json" "lucide-tags-$LucideVersion.json"
    return ($json | ConvertFrom-Json -AsHashtable)
}

# Lucide is ISC, except icons derived from Feather, which are MIT. The license
# file lists those by name.
function Get-LucideLicense([string]$Name) {
    $text = Get-Cached "$LucideBase/LICENSE" "lucide-license-$LucideVersion.txt"
    $m = [regex]::Match($text, 'derived from the Feather project:\s*(.+?)\r?\n\s*\r?\n', 'Singleline')
    $feather = if ($m.Success) { @($m.Groups[1].Value -split '\s*,\s*' | ForEach-Object Trim) } else { @() }
    if ($Name -in $feather) {
        return @{ author = 'Cole Bemis (Feather), Lucide Icons and Contributors'; license = 'MIT' }
    }
    return @{ author = 'Lucide Icons and Contributors'; license = 'ISC' }
}

function Get-SimpleIconLicense($Entry) {
    if ($Entry.Contains('license')) {
        $l = $Entry['license']
        if ($l.Contains('type')) { return [string]$l['type'] }
        if ($l.Contains('url')) { return [string]$l['url'] }
    }
    return 'CC0-1.0'
}

# --- Search -------------------------------------------------------------------

if ($PSCmdlet.ParameterSetName -eq 'Search') {
    $words = @($Search.ToLowerInvariant() -split '\s+' | Where-Object { $_ })
    # Every word must start a word in the name, slug, aliases, or tags.
    function Test-Words([string]$Hay) {
        foreach ($w in $words) { if ($Hay -notmatch ('(^|[\s\-:.])' + [regex]::Escape($w))) { return $false } }
        return $true
    }

    Write-Host "Brand marks (Simple Icons $SimpleIconsVersion):"
    $found = 0
    foreach ($e in Get-SimpleIcons) {
        $aka = @()
        if ($e.Contains('aliases') -and $e['aliases'].Contains('aka')) { $aka = @($e['aliases']['aka']) }
        $hay = (@($e['title'], $e['slug']) + $aka) -join ' '
        $hay = $hay.ToLowerInvariant()
        if (-not (Test-Words $hay)) { continue }
        $found++
        Write-Host ("  {0,-28} {1}  license: {2}" -f $e['slug'], $e['title'], (Get-SimpleIconLicense $e))
        if ($e.Contains('guidelines')) { Write-Host "  $(' ' * 28) guidelines: $($e['guidelines'])" }
    }
    if ($found -eq 0) { Write-Host '  none' }

    Write-Host ''
    Write-Host "Glyphs (Lucide $LucideVersion):"
    $tags = Get-LucideTags
    $hits = foreach ($name in $tags.Keys | Sort-Object) {
        $hay = ((@($name) + @($tags[$name])) -join ' ').ToLowerInvariant()
        if (Test-Words $hay) { $name }
    }
    if ($hits) {
        foreach ($h in $hits) { Write-Host "  $h  https://lucide.dev/icons/$h" }
    }
    else { Write-Host '  none. Try a word for what the app is, such as terminal, editor, or browser.' }
    return
}

# --- Fetch ----------------------------------------------------------------------

$portDir = Join-Path $RepoRoot 'Ports' $Port
if (-not (Test-Path (Join-Path $portDir 'port.json'))) { throw "Ports/$Port/port.json does not exist." }

if ($PSCmdlet.ParameterSetName -eq 'Brand') {
    if ($Mark -notmatch '^https://\S+$') { throw '-Mark must be an https URL.' }
    $entry = Get-SimpleIcons | Where-Object { $_['slug'] -eq $Brand } | Select-Object -First 1
    if (-not $entry) { throw "Simple Icons $SimpleIconsVersion has no icon '$Brand'. Use -Search." }
    $svgText = Get-Cached "$SimpleIconsBase/icons/$Brand.svg" "si-$SimpleIconsVersion-$Brand.svg"
    $credit = [ordered]@{
        kind    = 'brand'
        set     = "Simple Icons $SimpleIconsVersion"
        name    = $Brand
        author  = 'Simple Icons contributors'
        source  = "https://simpleicons.org/?q=$Brand"
        license = Get-SimpleIconLicense $entry
        mark    = $Mark
    }
    $note = "Simple Icons $SimpleIconsVersion, $Brand. Icon data $($credit.license). The mark belongs to its owner: $Mark"
}
else {
    if ($Glyph -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "'$Glyph' is not a Lucide icon name." }
    if (-not (Get-LucideTags).ContainsKey($Glyph)) { throw "Lucide $LucideVersion has no icon '$Glyph'. Use -Search." }
    $svgText = Get-Cached "$LucideBase/icons/$Glyph.svg" "lucide-$LucideVersion-$Glyph.svg"
    $lic = Get-LucideLicense $Glyph
    $credit = [ordered]@{
        kind    = 'glyph'
        set     = "Lucide $LucideVersion"
        name    = $Glyph
        author  = $lic.author
        source  = "https://lucide.dev/icons/$Glyph"
        license = $lic.license
    }
    $note = "Lucide $LucideVersion, $Glyph. $($lic.license) License, Copyright (c) $($lic.author). https://lucide.dev/license"
}

# Parse and keep only plain shapes. Anything else is an error, not a silent drop.
$xml = [System.Xml.XmlDocument]::new()
$xml.XmlResolver = $null
$xml.LoadXml($svgText)
$src = $xml.DocumentElement
if ($src.LocalName -ne 'svg') { throw 'The download is not an SVG.' }
if ($src.GetAttribute('viewBox') -ne '0 0 24 24') { throw "The icon's viewBox is '$($src.GetAttribute('viewBox'))', not '0 0 24 24'." }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("<!-- $($note -replace '--', '-') -->")
$svgAttrs = [ordered]@{ xmlns = 'http://www.w3.org/2000/svg'; viewBox = '0 0 24 24' }
foreach ($a in $RootAttrs) { if ($src.HasAttribute($a)) { $svgAttrs[$a] = $src.GetAttribute($a) } }
# Simple Icons leaves fill unset, which means black. Make it follow the page.
if (-not $svgAttrs.Contains('fill')) { $svgAttrs['fill'] = 'currentColor' }
[void]$sb.AppendLine('<svg ' + (($svgAttrs.GetEnumerator() | ForEach-Object { "$($_.Key)=`"$($_.Value)`"" }) -join ' ') + '>')

function Add-Shape([System.Xml.XmlNode]$Node, [int]$Depth) {
    if ($Node.NodeType -in 'Comment', 'Whitespace', 'SignificantWhitespace') { return }
    if ($Node.NodeType -ne 'Element') { throw "Unexpected $($Node.NodeType) in the SVG." }
    if ($Node.LocalName -eq 'title' -and $Depth -eq 1) { return }   # the card is aria-hidden
    if ($Node.LocalName -notin $Shapes) { throw "The icon uses <$($Node.LocalName)>, which is not allowed. Pick another icon." }
    $attrs = foreach ($a in $Node.Attributes) {
        if ($a.LocalName -notin $ShapeAttrs) { throw "The icon uses the attribute '$($a.LocalName)', which is not allowed." }
        "$($a.LocalName)=`"$([System.Security.SecurityElement]::Escape($a.Value))`""
    }
    $indent = '  ' * $Depth
    $open = "$indent<$($Node.LocalName)" + $(if ($attrs) { ' ' + ($attrs -join ' ') } else { '' })
    $kids = @($Node.ChildNodes | Where-Object NodeType -eq 'Element')
    if ($kids.Count -eq 0) { [void]$sb.AppendLine("$open />"); return }
    [void]$sb.AppendLine("$open>")
    foreach ($k in $Node.ChildNodes) { Add-Shape $k ($Depth + 1) }
    [void]$sb.AppendLine("$indent</$($Node.LocalName)>")
}
foreach ($child in $src.ChildNodes) { Add-Shape $child 1 }
[void]$sb.AppendLine('</svg>')

$out = Join-Path $portDir 'icon.svg'
[System.IO.File]::WriteAllText($out, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote Ports/$Port/icon.svg"
Write-Host ''
Write-Host "Add this to Ports/$Port/port.json, then run pwsh build/check.ps1:"
Write-Host ''
Write-Host ('"icon": ' + (ConvertTo-Json -InputObject $credit -Depth 3))
