#requires -Version 7.0
<#
.SYNOPSIS
    Tests the build modules in build/lib/ through their interfaces. Exits 1
    if any test fails.

.DESCRIPTION
    Uses small palettes and ports written to a temp folder, never the repo's
    own files, so a test failure points at the module and not at a port.
    Plain PowerShell: no Pester needed.

.EXAMPLE
    pwsh build/test.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($m in 'Palette', 'Placeholders', 'Build', 'Catalog') {
    Import-Module (Join-Path $PSScriptRoot 'lib' "$m.psm1") -Force
}

$script:Passed = 0
$script:Failed = [System.Collections.Generic.List[string]]::new()
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('hyaline-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp | Out-Null

function Test([string]$Name, [scriptblock]$Body) {
    try { & $Body; $script:Passed++ }
    catch { $script:Failed.Add("$Name`n    $($_.Exception.Message)") }
}
function Assert-Equal($Expected, $Actual, [string]$What = 'value') {
    if ($Expected -is [array] -or $Actual -is [array]) {
        $e = @($Expected) -join ' | '; $a = @($Actual) -join ' | '
        if ($e -cne $a) { throw "$What`: expected [$e], got [$a]" }
    }
    elseif ($Expected -cne $Actual) { throw "$What`: expected '$Expected', got '$Actual'" }
}
function Assert-True($Condition, [string]$What) { if (-not $Condition) { throw $What } }
function Assert-Throws([scriptblock]$Body, [string]$Like) {
    try { & $Body } catch { if ($_.Exception.Message -notlike $Like) { throw "threw '$($_.Exception.Message)', expected like '$Like'" }; return }
    throw "did not throw (expected like '$Like')"
}

# A palette that passes every check: the variant's roles are all the same
# except text and the eight color roles. Tests change it, then write it.
function New-PaletteData {
    $variant = {
        param($Mode, $Bg, $Fg)
        $roles = [ordered]@{}
        foreach ($r in 'backdrop', 'chrome', 'chrome_flat', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line') { $roles[$r] = $Bg }
        $roles['chrome'] = [ordered]@{ hex = $Bg; alpha = 0.5 }
        foreach ($r in 'text', 'text_dim', 'text_muted', 'on_accent') { $roles[$r] = $Fg }
        $roles['on_accent'] = $Bg
        foreach ($r in 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange') { $roles[$r] = $Fg }
        [ordered]@{ name = "Test $Mode"; mode = $Mode; wash = 0.2; roles = $roles }
    }
    return [ordered]@{
        meta = [ordered]@{ name = 'Test'; version = '1.2.3'; repository = 'https://example.invalid/repo' }
        variants = [ordered]@{ dark = (& $variant 'dark' '#101010' '#f0f0f0'); light = (& $variant 'light' '#f8f8f8' '#202020') }
    }
}
function Get-TestPalette($Data) {
    $path = Join-Path $Tmp ("palette-" + [guid]::NewGuid().ToString('N') + '.json')
    ConvertTo-Json -InputObject $Data -Depth 8 | Set-Content -Path $path
    return Read-Palette -Path $path
}

# --- Palette ------------------------------------------------------------------

Test 'Palette: a valid palette has no errors and both variants' {
    $p = Get-TestPalette (New-PaletteData)
    Assert-Equal 0 $p.Errors.Count 'errors'
    Assert-Equal @('dark', 'light') @($p.Variants.Keys) 'variants'
    Assert-Equal 0.5 $p.Variants['dark'].Roles['chrome'].Alpha 'chrome alpha'
}

Test 'Palette: reports every problem at once' {
    $d = New-PaletteData
    $d.variants.Remove('light')
    $d.variants.dark.roles.red = '#12345'
    $d.variants.dark.wash = 1.5
    $d.variants.dark.roles.Remove('panel_flat')
    $p = Get-TestPalette $d
    $all = $p.Errors -join "`n"
    foreach ($want in "variant 'light' is missing", 'dark.red is not a valid', 'wash must be a number', "missing role 'panel_flat'") {
        Assert-True ($all -like "*$want*") "expected an error like '$want' in:`n$all"
    }
}

Test 'Palette: blend and contrast' {
    Assert-Equal '#808080' (Get-Blend '#ffffff' '#000000' 0.5) 'blend'
    Assert-Equal '#ffffff' (Get-Blend '#ffffff' '#000000' 1) 'blend at 1'
    Assert-Equal '21.00' ('{0:0.00}' -f (Get-Contrast '#000000' '#ffffff')) 'contrast'
    Assert-Equal '1.00' ('{0:0.00}' -f (Get-Contrast '#777777' '#777777')) 'contrast with itself'
}

Test 'Palette: every filter' {
    $d = New-PaletteData
    $d.variants.dark.roles.red = '#FF8000'
    $d.variants.dark.roles.panel = [ordered]@{ hex = '#102030'; alpha = 0.875 }
    $v = (Get-TestPalette $d).Variants['dark']
    Assert-Equal '#ff8000' (Format-RoleColor $v 'red') 'hex'
    Assert-Equal 'ff8000' (Format-RoleColor $v 'red' 'nohash') 'nohash'
    Assert-Equal '255, 128, 0' (Format-RoleColor $v 'red' 'rgb') 'rgb'
    Assert-Equal 'rgba(16, 32, 48, 0.875)' (Format-RoleColor $v 'panel' 'rgba') 'rgba'
    Assert-Equal '#102030df' (Format-RoleColor $v 'panel' 'hexa') 'hexa'
    Assert-Equal '0.875' (Format-RoleColor $v 'panel' 'alpha') 'alpha'
    Assert-Equal '88' (Format-RoleColor $v 'panel' 'percent') 'percent'
    Assert-Equal '#ff800000' (Format-RoleColor $v 'red' 'clear') 'clear'
    Assert-Equal '#ff800033' (Format-RoleColor $v 'red' 'wash') 'wash'
    Assert-Equal (Get-Blend '#ff8000' '#101010' 0.2) (Format-RoleColor $v 'red' 'washflat') 'washflat is the blend over panel_flat'
    Assert-Equal (Get-WashColor $v 'red') (Format-RoleColor $v 'red' 'washflat') 'washflat is what the contrast check measures'
}

Test 'Palette: wash filters only on wash roles, unknown filters throw' {
    $v = (Get-TestPalette (New-PaletteData)).Variants['dark']
    Assert-Throws { Format-RoleColor $v 'text' 'washflat' } '*only applies to the wash roles*'
    Assert-Throws { Format-RoleColor $v 'red' 'bogus' } "*unknown filter 'bogus'*"
    Assert-Throws { Format-RoleColor $v 'nope' } "*unknown role 'nope'*"
}

Test 'Palette: ANSI slots follow ADR 0001' {
    $p = Get-TestPalette (New-PaletteData)
    Assert-Equal 'raised_flat' (Get-AnsiRole 'black' $p.Variants['dark']) 'dark black'
    Assert-Equal 'text' (Get-AnsiRole 'black' $p.Variants['light']) 'light black'
    Assert-Equal 'line' (Get-AnsiRole 'white' $p.Variants['light']) 'light white'
    Assert-Equal 'red' (Get-AnsiRole 'bright_red' $p.Variants['dark']) 'bright red'
    Assert-Equal $null (Get-AnsiRole 'purple' $p.Variants['dark']) 'unknown slot'
}

Test 'Palette: contrast floor' {
    Assert-Equal 0 (Test-PaletteContrast (Get-TestPalette (New-PaletteData))).Failures.Count 'failures on a good palette'
    $d = New-PaletteData
    $d.variants.light.roles.yellow = '#f0f0a0'
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-True (($c.Failures -join "`n") -like '*light.yellow on panel_flat*') "expected a yellow failure, got: $($c.Failures -join '; ')"
}

# --- Placeholders ---------------------------------------------------------------

Test 'Placeholders: expand every kind' {
    $p = Get-TestPalette (New-PaletteData)
    $values = @{ dark = @{ theme = 'vs-dark' }; light = @{ theme = 'vs' } }
    $out = Expand-Template -Text '{{red}} {{ meta.name }} {{variant.key}} {{variant.name}} {{port.theme}} {{ansi.black}} {{ansi.red|nohash}}' `
        -Palette $p -Variant $p.Variants['light'] -PortValues $values -Source 'test'
    Assert-Equal '#202020 Test light Test light vs #202020 202020' $out 'expanded'
}

Test 'Placeholders: the first bad placeholder throws, naming the source' {
    $p = Get-TestPalette (New-PaletteData)
    Assert-Throws { Expand-Template -Text '{{nope}}' -Palette $p -Variant $p.Variants['dark'] -PortValues $null -Source 'x.css' } '*Unknown placeholder {{nope}}*x.css*'
}

Test 'Placeholders: every problem is listed, once' {
    $p = Get-TestPalette (New-PaletteData)
    $values = @{ dark = @{ only = 'x' }; light = @{} }
    $errs = @(Find-PlaceholderError -Text '{{nope}} {{nope}} {{text|washflat}} {{meta.name|rgb}} {{port.only}} {{red|bogus}} {{red}}' -Palette $p -PortValues $values)
    Assert-Equal 5 $errs.Count "errors ($($errs -join '; '))"
    Assert-True (($errs -join "`n") -like '*port.only*light*') 'names the variant missing a port value'
    Assert-Equal 0 @(Find-PlaceholderError -Text 'plain {{red|wash}}' -Palette $p -PortValues $null).Count 'a good template'
}

Test 'Placeholders: leftovers and encodings' {
    Assert-Equal '{{ red|wash }}' (Find-Placeholder 'a {{ red|wash }} b') 'found'
    Assert-Equal $null (Find-Placeholder 'a { red } b') 'none'
    $path = Join-Path $Tmp 'utf16.txt'
    [System.IO.File]::WriteAllText($path, '{{red}}', [System.Text.UnicodeEncoding]::new($false, $true))
    $t = Read-TemplateFile $path
    Assert-Equal $false $t.Binary 'UTF-16 is text'
    Assert-Equal '{{red}}' $t.Text 'UTF-16 text'
    [System.IO.File]::WriteAllBytes($path, [byte[]](0x89, 0x50, 0x00, 0x01))
    Assert-Equal $true (Read-TemplateFile $path).Binary 'binary'
}

# --- Build --------------------------------------------------------------------

function New-TestPort([string]$Name, [hashtable]$Files) {
    $dir = Join-Path $Tmp $Name
    foreach ($rel in $Files.Keys) {
        $path = Join-Path $dir 'template' $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        Set-Content -Path $path -Value $Files[$rel] -NoNewline
    }
    return $dir
}

Test 'Build: statuses across a port''s life' {
    $port = New-TestPort 'life' @{ 'theme.txt' = 'Version {{meta.version}}, red {{red}}'; '{{variant.key}}/name.txt' = '{{variant.name}}' }
    $d = New-PaletteData
    $p = Get-TestPalette $d
    $r = Update-Port -Palette $p -PortDir $port
    Assert-Equal 'new' $r.Status 'first build'
    Assert-Equal 4 $r.Written 'files written'
    Assert-Equal 'Version 1.2.3, red #f0f0f0' (Get-Content -Raw (Join-Path $port 'dist' 'dark' 'theme.txt')) 'rendered'
    Assert-True (Test-Path (Join-Path $port 'dist' 'light' 'light' 'name.txt')) 'placeholder in a file name'
    Assert-Equal 'unchanged' (Update-Port -Palette $p -PortDir $port).Status 'rebuild'

    $d.meta.version = '1.2.4'
    $s = Get-PortStatus -Palette (Get-TestPalette $d) -PortDir $port
    Assert-Equal 'version stamp only' $s.Status 'version bump'
    Assert-Equal 2 $s.Files.Count 'files that differ'
    Assert-Equal 'Version 1.2.3, red #f0f0f0' (Get-Content -Raw (Join-Path $port 'dist' 'dark' 'theme.txt')) 'Get-PortStatus leaves dist alone'

    $d.variants.dark.roles.red = '#f0f0f1'
    Assert-Equal 'changed' (Get-PortStatus -Palette (Get-TestPalette $d) -PortDir $port).Status 'color change'
}

Test 'Build: drift kinds' {
    $port = New-TestPort 'drift' @{ 'a.txt' = '{{red}}'; 'b.txt' = 'b' }
    $p = Get-TestPalette (New-PaletteData)
    $null = Update-Port -Palette $p -PortDir $port
    Set-Content -Path (Join-Path $port 'dist' 'dark' 'extra.txt') -Value 'x'
    Remove-Item (Join-Path $port 'dist' 'dark' 'b.txt')
    Set-Content -Path (Join-Path $port 'dist' 'light' 'a.txt') -Value 'stale' -NoNewline
    $s = Get-PortStatus -Palette $p -PortDir $port
    Assert-Equal 'changed' $s.Status 'status'
    $kinds = @($s.Files | Sort-Object { $_.Path } | ForEach-Object { "$($_.Path)=$($_.Kind)" })
    Assert-Equal @('dark/b.txt=missing', 'dark/extra.txt=extra', 'light/a.txt=out of date') $kinds 'files'
}

Test 'Build: CRLF in dist is not drift' {
    $port = New-TestPort 'crlf' @{ 'a.txt' = "one`ntwo" }
    $p = Get-TestPalette (New-PaletteData)
    $null = Update-Port -Palette $p -PortDir $port
    Set-Content -Path (Join-Path $port 'dist' 'dark' 'a.txt') -Value "one`r`ntwo" -NoNewline
    Assert-Equal 'unchanged' (Get-PortStatus -Palette $p -PortDir $port).Status 'status'
}

# --- Catalog ------------------------------------------------------------------

function New-TestPorts([hashtable]$Index, [hashtable]$Ports) {
    $root = Join-Path $Tmp ('ports-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root | Out-Null
    ConvertTo-Json -InputObject $Index -Depth 6 | Set-Content (Join-Path $root 'ports.json')
    foreach ($name in $Ports.Keys) {
        $dir = Join-Path $root $name
        New-Item -ItemType Directory -Path (Join-Path $dir 'template') -Force | Out-Null
        Set-Content (Join-Path $dir 'README.md') '# x'
        if ($null -ne $Ports[$name]) { ConvertTo-Json -InputObject $Ports[$name] -Depth 6 | Set-Content (Join-Path $dir 'port.json') }
    }
    return $root
}
$GoodMeta = @{ name = 'Good'; category = 'editor'; tier = 2; platforms = @('linux', 'web') }

Test 'Catalog: a valid catalog' {
    $root = New-TestPorts @{ categories = @{ editor = 'Editors' }; unlisted = @('preview'); planned = @(@{ folder = 'later'; name = 'Later'; category = 'editor'; tier = $null; platforms = @('linux') }) } `
        @{ good = $GoodMeta; preview = $null }
    New-Item -ItemType Directory -Path (Join-Path $root 'good' 'dist' 'dark') -Force | Out-Null
    $c = Get-PortCatalog -PortsRoot $root
    Assert-Equal 0 ($c.Errors.Count + $c.StructureErrors.Count) "errors: $($c.Errors + $c.StructureErrors -join '; ')"
    $data = ConvertTo-PortsData $c
    Assert-Equal 1 @($data.ports).Count 'listed ports'
    Assert-Equal @('dark') @($data.ports[0].variants) 'variants from dist/'
    Assert-Equal 'Flat' $data.tiers['2'] 'tier names'
    Assert-Equal 'Web' $data.platforms['web'] 'platform names'
    Assert-Equal 'later' $data.planned[0].folder 'planned'
}

Test 'Catalog: reports bad port.json, unlisted, and planned entries' {
    $bad = @{ name = 'Bad'; category = 'nope'; tier = 4; platforms = @('amiga'); extra = 1 }
    $root = New-TestPorts @{ categories = @{ editor = 'Editors' }; unlisted = @('ghost'); planned = @(@{ folder = 'good'; name = 'Good'; category = 'editor'; tier = 1; platforms = @('linux') }) } `
        @{ good = $GoodMeta; bad = $bad; nometa = $null }
    $all = (Get-PortCatalog -PortsRoot $root).Errors -join "`n"
    foreach ($want in "unknown field 'extra'", "category 'nope'", "needs 'tier'", "platform 'amiga'", 'nometa/port.json does not exist',
                      'unlisted folder Ports/ghost', 'Ports/good exists, so remove it') {
        Assert-True ($all -like "*$want*") "expected an error like '$want' in:`n$all"
    }
}

Test 'Catalog: icons and site.json' {
    $meta = $GoodMeta.Clone()
    $meta.icon = @{ kind = 'glyph'; set = 'Lucide'; name = 'x'; author = 'A'; source = 'https://example.invalid/x'; license = 'ISC' }
    $root = New-TestPorts @{ categories = @{ editor = 'Editors' }; planned = @() } @{ good = $meta }
    $svg = Join-Path $root 'good' 'icon.svg'
    Set-Content $svg '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M0 0h24v24H0z"/></svg>'
    $c = Get-PortCatalog -PortsRoot $root
    Assert-Equal 0 $c.Errors.Count "errors: $($c.Errors -join '; ')"
    Assert-Equal 'Lucide' $c.Ports[0].Icon['set'] 'icon kept'

    Set-Content $svg '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#ff0000"><text>x</text></svg>'
    Set-Content (Join-Path $root 'good' 'site.json') '{ "copy": ["nothere"], "entries": [{ "path": "x/index.html", "page": "missing.html", "title": "X" }] }'
    $c = Get-PortCatalog -PortsRoot $root
    $all = $c.Errors -join "`n"
    Assert-True ($all -like '*fill="#ff0000"*' -and $all -like '*<text>*') "icon errors: $all"
    Assert-Equal $null $c.Ports[0].Icon 'invalid icon dropped'
    $site = $c.StructureErrors -join "`n"
    Assert-True ($site -like "*copies 'nothere'*" -and $site -like "*opens 'missing.html'*") "site.json errors: $site"
}

# --- Summary ------------------------------------------------------------------

Remove-Item -Path $Tmp -Recurse -Force -ErrorAction SilentlyContinue
foreach ($f in $script:Failed) { Write-Host "FAIL: $f" -ForegroundColor Red }
Write-Host "$($script:Passed) passed, $($script:Failed.Count) failed."
if ($script:Failed.Count -gt 0) { exit 1 }
exit 0
