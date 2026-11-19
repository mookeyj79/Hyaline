#requires -Version 7.0
<#
.SYNOPSIS
    Tests the build modules in build/lib/ through their interfaces, and
    smoke tests the entry scripts. Exits 1 if any test fails.

.DESCRIPTION
    Module tests use small palettes and ports written to a temp folder, never
    the repo's own files, so a test failure points at the module and not at a
    port. The entry script tests run each script once, offline: contrast.ps1
    and roles.ps1 on the repo, wallpaper.ps1 -Check on a local fixture image.
    Plain PowerShell: no Pester needed.

.EXAMPLE
    pwsh build/test.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($m in 'Palette', 'Placeholders', 'Build', 'Catalog', 'Wallpaper') {
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
        param($Mode, $Bg, $Fg, $Bright)
        $roles = [ordered]@{}
        foreach ($r in 'backdrop', 'chrome', 'chrome_flat', 'panel', 'panel_flat', 'raised', 'raised_flat', 'line', 'edge', 'edge_flat', 'window_edge', 'window_edge_flat') { $roles[$r] = $Bg }
        # Glass dense enough, and clamped hard enough, to pass over black and white.
        $roles['chrome'] = [ordered]@{ hex = $Bg; alpha = 0.9; clamp = [ordered]@{ blur = 30; contrast = 0.2; brightness = $Bright; saturate = 1.5; alpha = 0.5 } }
        $roles['panel'] = [ordered]@{ hex = $Bg; alpha = 0.9; clamp = [ordered]@{ blur = 30; contrast = 0.2; brightness = $Bright; saturate = 1.5; alpha = 0.6 } }
        $roles['raised'] = [ordered]@{ hex = $Bg; alpha = 0.5 }
        foreach ($r in 'text', 'text_dim', 'text_muted', 'on_accent') { $roles[$r] = $Fg }
        $roles['on_accent'] = $Bg
        foreach ($r in 'accent', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'orange') { $roles[$r] = $Fg }
        [ordered]@{ name = "Test $Mode"; mode = $Mode; wash = 0.2; roles = $roles }
    }
    return [ordered]@{
        meta = [ordered]@{ name = 'Test'; version = '1.2.3'; repository = 'https://example.invalid/repo' }
        variants = [ordered]@{ dark = (& $variant 'dark' '#101010' '#f0f0f0' 0.4); light = (& $variant 'light' '#f8f8f8' '#202020' 2) }
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
    Assert-Equal 0.9 $p.Variants['dark'].Roles['chrome'].Alpha 'chrome alpha'
}

Test 'Palette: a clamp block sits beside the dense alpha' {
    $p = Get-TestPalette (New-PaletteData)
    $clamp = $p.Variants['light'].Roles['panel'].Clamp
    Assert-Equal 30 $clamp.Blur 'blur'
    Assert-Equal 0.2 $clamp.Contrast 'contrast'
    Assert-Equal 2 $clamp.Brightness 'brightness'
    Assert-Equal 1.5 $clamp.Saturate 'saturate'
    Assert-Equal 0.6 $clamp.Alpha 'tint alpha'
    Assert-Equal 0.9 $p.Variants['light'].Roles['panel'].Alpha 'dense alpha'
    Assert-Equal $null $p.Variants['light'].Roles['raised'].Clamp 'no clamp on raised'
}

Test 'Palette: edge and clamp problems are reported at once' {
    $d = New-PaletteData
    $d.variants.dark.roles.Remove('edge')
    $d.variants.light.roles.Remove('edge_flat')
    $d.variants.dark.roles.Remove('window_edge')
    $d.variants.light.roles.Remove('window_edge_flat')
    $d.variants.dark.roles.chrome.Remove('clamp')
    $d.variants.dark.roles.panel.clamp.Remove('brightness')
    $d.variants.light.roles.panel.clamp.alpha = 1.5
    $d.variants.light.roles.chrome.clamp.contrast = 'high'
    $d.variants.light.roles.raised.clamp = [ordered]@{ blur = 30; contrast = 0.2; brightness = 2; saturate = 1.5; alpha = 0.5 }
    $p = Get-TestPalette $d
    $all = $p.Errors -join "`n"
    foreach ($want in "dark is missing role 'edge'", "light is missing role 'edge_flat'",
        "dark is missing role 'window_edge'", "light is missing role 'window_edge_flat'", 'dark.chrome needs a clamp block',
        'dark.panel clamp.brightness must be a number', 'light.panel clamp.alpha must be between 0 and 1',
        'light.chrome clamp.contrast must be a number', 'light.raised cannot have a clamp') {
        Assert-True ($all -like "*$want*") "expected an error like '$want' in:`n$all"
    }
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

Test 'Palette: clamp filters write the CSS recipe and its thin tint' {
    $d = New-PaletteData
    $d.variants.dark.roles.panel = [ordered]@{ hex = '#1c2028'; alpha = 0.82; clamp = [ordered]@{ blur = 30; contrast = 0.15; brightness = 0.45; saturate = 2.5; alpha = 0.6 } }
    $v = (Get-TestPalette $d).Variants['dark']
    Assert-Equal 'blur(30px) contrast(0.15) brightness(0.45) saturate(2.5)' (Format-RoleColor $v 'panel' 'clamp') 'clamp'
    Assert-Equal 'rgba(28, 32, 40, 0.6)' (Format-RoleColor $v 'panel' 'clamptint') 'clamptint'
    Assert-Equal 'rgba(28, 32, 40, 0.82)' (Format-RoleColor $v 'panel' 'rgba') 'rgba stays the dense alpha'
    Assert-Throws { Format-RoleColor $v 'raised' 'clamp' } '*only applies to*chrome*panel*'
    Assert-Throws { Format-RoleColor $v 'text' 'clamptint' } '*only applies to*chrome*panel*'
}

Test 'Palette: ANSI slots follow ADR 0001' {
    $p = Get-TestPalette (New-PaletteData)
    Assert-Equal 'raised_flat' (Get-AnsiRole 'black' $p.Variants['dark']) 'dark black'
    Assert-Equal 'text' (Get-AnsiRole 'black' $p.Variants['light']) 'light black'
    Assert-Equal 'line' (Get-AnsiRole 'white' $p.Variants['light']) 'light white'
    Assert-Equal 'red' (Get-AnsiRole 'bright_red' $p.Variants['dark']) 'bright red'
    Assert-Equal $null (Get-AnsiRole 'purple' $p.Variants['dark']) 'unknown slot'
}

Test 'Palette: glass over a backdrop, dense or clamped' {
    $d = New-PaletteData
    $d.variants.dark.roles.panel = [ordered]@{ hex = '#ffffff'; alpha = 0.25; clamp = [ordered]@{ blur = 30; contrast = 0.5; brightness = 2; saturate = 3; alpha = 0.5 } }
    $v = (Get-TestPalette $d).Variants['dark']
    # Dense: the tint at its alpha. Clamped: black squeezed to 0.25, doubled to 0.5, then the thin tint.
    Assert-Equal '#404040' (Get-GlassColor $v 'panel' '#000000') 'dense over black'
    Assert-Equal '#c0c0c0' (Get-GlassColor $v 'panel' '#000000' -Clamp) 'clamped over black'
    Assert-Equal '#ffffff' (Get-GlassColor $v 'panel' '#ffffff' -Clamp) 'clamped over white, brightness capped at white'
}

Test 'Palette: contrast floor' {
    $c = Test-PaletteContrast (Get-TestPalette (New-PaletteData))
    Assert-Equal 0 $c.Failures.Count "failures on a good palette ($($c.Failures -join '; '))"
    $d = New-PaletteData
    $d.variants.light.roles.yellow = '#f0f0a0'
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-True (($c.Failures -join "`n") -like '*light.yellow on panel_flat*') "expected a yellow failure, got: $($c.Failures -join '; ')"
}

function Assert-Failure($Contrast, [string]$Like) {
    $all = $Contrast.Failures -join "`n"
    Assert-True ($all -like $Like) "expected a failure like '$Like', got:`n$all"
}
function Assert-NoFailure($Contrast, [string]$Like) {
    $hit = @($Contrast.Failures | Where-Object { $_ -like $Like })
    Assert-True ($hit.Count -eq 0) "expected no failure like '$Like', got:`n$($hit -join "`n")"
}

Test 'Contrast: dense glass is measured over black and white, the lower counts' {
    # Thin dark glass passes over black but not over white.
    $d = New-PaletteData
    $d.variants.dark.roles.panel.alpha = 0.5
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*dark.text on panel over white*'
    Assert-NoFailure $c '*dark.text on panel over black*'
    Assert-NoFailure $c '*on panel clamp*'
    # Chrome carries primary text only, so only text is measured there.
    $d = New-PaletteData
    $d.variants.light.roles.chrome.alpha = 0.3
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*light.text on chrome over black*'
    Assert-NoFailure $c '*light.red on chrome*'
}

Test 'Contrast: the clamp is measured with contrast and brightness, blur ignored' {
    # A clamp that darkens Light's backdrop fails, though the dense alpha passes.
    $d = New-PaletteData
    $d.variants.light.roles.panel.clamp.brightness = 0.5
    $d.variants.light.roles.panel.clamp.alpha = 0.2
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*light.text on panel clamp over black*'
    Assert-NoFailure $c '*light.text on panel over black*'
    # A clamp with no squeeze fails over the wrong backdrop; blur cannot save it.
    foreach ($blur in 0, 200) {
        $d = New-PaletteData
        $d.variants.dark.roles.chrome.clamp.contrast = 1
        $d.variants.dark.roles.chrome.clamp.brightness = 1
        $d.variants.dark.roles.chrome.clamp.blur = $blur
        Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.text on chrome clamp over white*'
    }
}

Test 'Contrast: translucent raised is measured on the clamped panel' {
    $d = New-PaletteData
    $d.variants.dark.roles.raised = [ordered]@{ hex = '#ffffff'; alpha = 0.8 }
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*dark.text on raised over panel clamp over black*'
}

Test 'Contrast: role colors on raised fail under 3:1, short labels pass from 3:1' {
    $d = New-PaletteData
    $d.variants.dark.roles.raised_flat = '#707070'   # #f0f0f0 on it is about 3.9:1
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-NoFailure $c '*dark.red on raised_flat*'
    Assert-Failure $c '*dark.text on raised_flat*needs 4.5*'
    $d.variants.dark.roles.raised_flat = '#a0a0a0'   # about 1.9:1
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.red on raised_flat*needs 3*'
}

Test 'Contrast: on_accent needs 4.5:1 on solid red as on accent' {
    $d = New-PaletteData
    $d.variants.dark.roles.red = '#303030'   # #101010 on it is about 1.4:1
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*dark.on_accent on red is*needs 4.5*'
    Assert-NoFailure $c '*light.on_accent*'
}

Test 'Contrast: dim text on a wash needs 3:1, primary text 4.5:1' {
    $d = New-PaletteData
    $d.variants.dark.roles.red = '#ffffff'
    $d.variants.dark.wash = 0.25
    $d.variants.dark.roles.text_dim = '#a0a0a0'   # about 3.3:1 on the red wash over panel_flat
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-NoFailure $c '*dark.text_dim on red wash over panel_flat*'
    $d.variants.dark.roles.text_dim = '#808080'   # about 2.2:1
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.text_dim on red wash over panel_flat*needs 3:1*'
    $d.variants.dark.roles.text = '#a0a0a0'
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.text on red wash over panel_flat*needs 4.5:1*'
}

Test 'Contrast: washes are measured over the glass too' {
    $d = New-PaletteData
    $d.variants.dark.roles.panel.alpha = 0.7   # text passes on the glass itself, not under a wash
    $d.variants.dark.roles.yellow = '#ffff00'
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-NoFailure $c '*dark.text on panel over white*'
    Assert-Failure $c '*dark.text on yellow wash over panel over white*'
}

Test 'Contrast: role colors on opacity-only glass need 3:1, on the clamp and panel_flat 4.5:1' {
    $d = New-PaletteData
    $d.variants.dark.roles.red = '#6b6b6b'   # about 3.6:1 on the panel over black, 3.6:1 on panel_flat, 3.3:1 on the clamp
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-NoFailure $c '*dark.red on panel over black*'
    Assert-Failure $c '*dark.red on panel_flat is*needs 4.5:1*'
    Assert-Failure $c '*dark.red on panel clamp over black is*needs 4.5:1*'
    $m = @($c.Measurements | Where-Object { $_.Variant -eq 'dark' -and $_.Role -eq 'red' -and $_.Surface -eq 'panel over black' })
    Assert-Equal 3.0 $m[0].Floor 'floor on opacity-only glass'
    $d.variants.dark.roles.red = '#505050'   # about 2.3:1
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.red on panel over black is*needs 3:1*'
}

Test 'Contrast: on opacity-only glass primary text needs 4.5:1, dim 3:1, muted 2:1' {
    $d = New-PaletteData
    $d.variants.dark.roles.text = '#808080'         # about 4.9:1 over black, 3.7:1 over white
    $d.variants.dark.roles.text_dim = '#6b6b6b'     # about 3.6:1 over black, 2.8:1 over white
    $d.variants.dark.roles.text_muted = '#5a5a5a'   # about 2.8:1 over black, 2.1:1 over white
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-NoFailure $c '*dark.text on panel over black*'
    Assert-Failure $c '*dark.text on panel over white is*needs 4.5:1*'
    Assert-NoFailure $c '*dark.text_dim on panel over black*'
    Assert-Failure $c '*dark.text_dim on panel over white is*needs 3:1*'
    Assert-NoFailure $c '*dark.text_muted on panel over*'
    $d.variants.dark.roles.text_muted = '#505050'   # about 1.8:1 over white
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.text_muted on panel over white is*needs 2:1*'
}

Test 'Contrast: on a wash over opacity-only glass everything but primary text needs 2:1' {
    $d = New-PaletteData
    $d.variants.dark.roles.red = '#ffffff'
    $d.variants.dark.wash = 0.25
    # About 2.2:1 on the red wash over the panel over black, and over panel_flat.
    foreach ($r in 'text_dim', 'text_muted', 'green') { $d.variants.dark.roles[$r] = '#808080' }
    $c = Test-PaletteContrast (Get-TestPalette $d)
    foreach ($r in 'text_dim', 'text_muted', 'green') {
        Assert-NoFailure $c "*dark.$r on red wash over panel over black*"
        # The full wash row still holds over panel_flat and the clamped panel.
        Assert-Failure $c "*dark.$r on red wash over panel_flat is*needs 3:1*"
        Assert-Failure $c "*dark.$r on red wash over panel clamp over black is*needs 3:1*"
    }
    $d.variants.dark.roles.text = '#a0a0a0'   # about 3.4:1
    $c = Test-PaletteContrast (Get-TestPalette $d)
    # Primary text needs 4.5:1 on a wash over every panel surface.
    Assert-Failure $c '*dark.text on red wash over panel over black is*needs 4.5:1*'
    Assert-Failure $c '*dark.text on red wash over panel_flat is*needs 4.5:1*'
    Assert-Failure $c '*dark.text on red wash over panel clamp over black is*needs 4.5:1*'
    $d.variants.dark.roles.text_dim = '#606060'   # under 2:1
    Assert-Failure (Test-PaletteContrast (Get-TestPalette $d)) '*dark.text_dim on red wash over panel over black is*needs 2:1*'
}

Test 'Contrast: raised and chrome keep their rows beside opacity-only glass' {
    $d = New-PaletteData
    $d.variants.dark.roles.raised_flat = '#707070'   # #f0f0f0 on it is about 3.9:1
    $d.variants.dark.roles.text = '#808080'          # about 3.7:1 on chrome over white
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Failure $c '*dark.text_dim on raised_flat is*needs 4.5:1*'
    Assert-Failure $c '*dark.text on chrome over white is*needs 4.5:1*'
    $m = @($c.Measurements | Where-Object { $_.Variant -eq 'dark' -and $_.Surface -like 'chrome*' })
    Assert-Equal 'text' (@($m.Role | Sort-Object -Unique) -join ',') 'roles measured on chrome'
    Assert-Equal 3.0 @($c.Measurements | Where-Object { $_.Variant -eq 'dark' -and $_.Role -eq 'red' -and $_.Surface -eq 'raised_flat' })[0].Floor 'role colors on raised_flat'
    Assert-Equal 3.0 @($c.Measurements | Where-Object { $_.Variant -eq 'dark' -and $_.Role -eq 'text_muted' -and $_.Surface -eq 'raised over panel clamp over black' })[0].Floor 'muted text on translucent raised'
}

Test 'Contrast: line, edge, and the window edge have no floor' {
    $d = New-PaletteData
    foreach ($r in 'line', 'edge', 'edge_flat', 'window_edge', 'window_edge_flat') { $d.variants.dark.roles[$r] = '#101010'; $d.variants.light.roles[$r] = '#f8f8f8' }
    $d.variants.dark.roles.edge = [ordered]@{ hex = '#ffffff'; alpha = 0.14 }
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Equal 0 $c.Failures.Count "failures ($($c.Failures -join '; '))"
}

Test 'Contrast: every measurement is listed, failures among them' {
    $d = New-PaletteData
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Equal 0 @($c.Measurements | Where-Object { -not $_.Pass }).Count 'failing measurements on a passing palette'
    $m = @($c.Measurements | Where-Object { $_.Variant -eq 'dark' -and $_.Role -eq 'text' -and $_.Surface -eq 'panel over white' })
    Assert-Equal 1 $m.Count 'dark text on panel over white measured once'
    Assert-Equal 4.5 $m[0].Floor 'floor'
    Assert-True ($m[0].Ratio -ge 4.5) "ratio $($m[0].Ratio)"
    $d.variants.dark.roles.panel.alpha = 0.5
    $c = Test-PaletteContrast (Get-TestPalette $d)
    Assert-Equal $c.Failures.Count @($c.Measurements | Where-Object { -not $_.Pass }).Count 'one failing measurement per failure'
}

Test 'Palette: read from data as from a file' {
    $d = New-PaletteData
    $fromFile = Get-TestPalette $d
    $fromData = Read-Palette -Data ((ConvertTo-Json -InputObject $d -Depth 8) | ConvertFrom-Json -AsHashtable)
    Assert-Equal 0 $fromData.Errors.Count 'errors'
    Assert-Equal $fromFile.Variants['dark'].Roles['panel'].Hex $fromData.Variants['dark'].Roles['panel'].Hex 'panel hex'
}

# --- Placeholders ---------------------------------------------------------------

Test 'Placeholders: roles a template draws' {
    $p = Get-TestPalette (New-PaletteData)
    $text = '{{panel|rgba}} {{text}} {{meta.name}} {{port.font}} {{ansi.black}} {{ansi.bright_red}} {{nope}}'
    # ansi.black is raised_flat in dark and text in light.
    Assert-Equal @('panel', 'raised_flat', 'red', 'text') @(Get-PlaceholderRole -Text $text -Palette $p) 'roles'
    Assert-Equal 0 @(Get-PlaceholderRole -Text 'no placeholders' -Palette $p).Count 'none'
}

Test 'Placeholders: expand every kind' {
    $p = Get-TestPalette (New-PaletteData)
    $values = @{ dark = @{ theme = 'vs-dark' }; light = @{ theme = 'vs' } }
    $out = Expand-Template -Text '{{red}} {{ meta.name }} {{variant.key}} {{variant.name}} {{port.theme}} {{ansi.black}} {{ansi.red|nohash}}' `
        -Palette $p -Variant $p.Variants['light'] -PortValues $values -Source 'test'
    Assert-Equal '#202020 Test light Test light vs #202020 202020' $out 'expanded'
}

Test 'Placeholders: slug turns a name into an identifier' {
    $p = Get-TestPalette (New-PaletteData)
    $out = Expand-Template -Text '--{{variant.name|slug}}-red {{ meta.name | slug }}' `
        -Palette $p -Variant $p.Variants['light'] -PortValues $null -Source 'test'
    Assert-Equal '--test-light-red test' $out 'slugged'
    $punct = Expand-Template -Text '{{port.label|slug}}' -Palette $p -Variant $p.Variants['dark'] `
        -PortValues @{ dark = @{ label = ' Hyaline: Dark (v2)! ' } } -Source 'test'
    Assert-Equal 'hyaline-dark-v2' $punct 'runs of punctuation become one hyphen, trimmed'
}

Test 'Placeholders: the first bad placeholder throws, naming the source' {
    $p = Get-TestPalette (New-PaletteData)
    Assert-Throws { Expand-Template -Text '{{nope}}' -Palette $p -Variant $p.Variants['dark'] -PortValues $null -Source 'x.css' } '*Unknown placeholder {{nope}}*x.css*'
}

Test 'Placeholders: every problem is listed, once' {
    $p = Get-TestPalette (New-PaletteData)
    $values = @{ dark = @{ only = 'x' }; light = @{} }
    $errs = @(Find-PlaceholderError -Text '{{nope}} {{nope}} {{text|washflat}} {{meta.name|rgb}} {{port.only}} {{red|bogus}} {{red|slug}} {{red}}' -Palette $p -PortValues $values)
    Assert-Equal 6 $errs.Count "errors ($($errs -join '; '))"
    Assert-True (($errs -join "`n") -like '*port.only*light*') 'names the variant missing a port value'
    Assert-Equal 0 @(Find-PlaceholderError -Text 'plain {{red|wash}}' -Palette $p -PortValues $null).Count 'a good template'
}

Test 'Placeholders: the clamp expands for chrome and panel only' {
    $p = Get-TestPalette (New-PaletteData)
    $out = Expand-Template -Text 'backdrop-filter: {{panel|clamp}}; background: {{ chrome|clamptint }};' -Palette $p -Variant $p.Variants['light'] -PortValues $null -Source 'test'
    Assert-Equal 'backdrop-filter: blur(30px) contrast(0.2) brightness(2) saturate(1.5); background: rgba(248, 248, 248, 0.5);' $out 'expanded'
    Assert-Throws { Expand-Template -Text '{{raised|clamp}}' -Palette $p -Variant $p.Variants['dark'] -PortValues $null -Source 'glass.css' } '*{{raised|clamp}}*only applies to*glass.css*'
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
    Set-Content (Join-Path $root 'good' 'site.json') '{ "copy": ["nothere"], "entries": [{ "path": "x/index.html", "page": "missing.html", "title": "X" }], "guide": "guides/missing.html" }'
    $c = Get-PortCatalog -PortsRoot $root
    $all = $c.Errors -join "`n"
    Assert-True ($all -like '*fill="#ff0000"*' -and $all -like '*<text>*') "icon errors: $all"
    Assert-Equal $null $c.Ports[0].Icon 'invalid icon dropped'
    $site = $c.StructureErrors -join "`n"
    Assert-True ($site -like "*copies 'nothere'*" -and $site -like "*opens 'missing.html'*" -and $site -like "*guide 'guides/missing.html'*") "site.json errors: $site"
}

# --- Wallpaper ----------------------------------------------------------------

function New-Pixels([int]$Count, [byte[]]$Rgb) {
    $b = [byte[]]::new($Count * 3)
    for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = $Rgb[$i % 3] }
    return , $b
}

Test 'Wallpaper: licenses' {
    foreach ($ok in 'CC0', 'CC0 1.0', 'Public domain', 'CC BY 4.0', 'CC BY-SA 3.0') { Assert-True (Test-WallpaperLicense $ok) "$ok should pass" }
    foreach ($no in 'CC BY-NC 4.0', 'CC BY-ND 2.0', 'CC BY-NC-SA 4.0', 'GFDL', '', 'Copyrighted') { Assert-True (-not (Test-WallpaperLicense $no)) "'$no' should fail" }
}

Test 'Wallpaper: format needs a wide landscape image' {
    Assert-Equal 0 @(Test-WallpaperFormat -Width 1920 -Height 1080).Count 'a 1920 x 1080 image passes'
    Assert-Equal @('1919 px wide, needs at least 1920.') @(Test-WallpaperFormat -Width 1919 -Height 1000) 'too narrow'
    Assert-Equal @('not landscape.') @(Test-WallpaperFormat -Width 2000 -Height 2000) 'square'
    Assert-Equal @('1080 px wide, needs at least 1920.', 'not landscape.') @(Test-WallpaperFormat -Width 1080 -Height 1920) 'portrait phone shot'
}

Test 'Wallpaper: fit of flat, colorful, and busy images' {
    $f = Measure-WallpaperFit -Pixels (New-Pixels 16 @(240, 240, 240)) -Width 4 -Height 4
    Assert-Equal 0.0 $f.Detail 'flat detail'
    Assert-Equal 0.0 $f.Saturation 'gray saturation'
    Assert-Equal 'calm' $f.Grades.Saturation 'gray saturation grade'
    Assert-Equal 'calm' $f.Grades.Detail 'flat detail grade'
    $red = Measure-WallpaperFit -Pixels (New-Pixels 16 @(250, 120, 120)) -Width 4 -Height 4
    Assert-Equal 'colorful' $red.Grades.Saturation 'red saturation grade'
    $check = [byte[]]::new(48)
    for ($p = 0; $p -lt 16; $p++) { $v = if ((($p % 4) + [math]::Floor($p / 4)) % 2) { 255 } else { 160 }; foreach ($c in 0, 1, 2) { $check[3 * $p + $c] = $v } }
    $busy = Measure-WallpaperFit -Pixels $check -Width 4 -Height 4
    Assert-Equal 'busy' $busy.Grades.Detail "checkerboard detail grade ($($busy.Detail))"
    Assert-Throws { Measure-WallpaperFit -Pixels ([byte[]]::new(5)) -Width 2 -Height 1 } '*expected 6 bytes*'
}

Test 'Wallpaper: variant suggested from lightness' {
    # Gray 240 is L* 94, 119 is L* 50, 40 is L* 16.
    Assert-Equal 'light' (Measure-WallpaperFit -Pixels (New-Pixels 16 @(240, 240, 240)) -Width 4 -Height 4).Variant 'light gray'
    Assert-Equal 'both' (Measure-WallpaperFit -Pixels (New-Pixels 16 @(119, 119, 119)) -Width 4 -Height 4).Variant 'middle gray'
    Assert-Equal 'dark' (Measure-WallpaperFit -Pixels (New-Pixels 16 @(40, 40, 40)) -Width 4 -Height 4).Variant 'dark gray'
    foreach ($case in @(60, 'light'), @(59.9, 'both'), @(40.1, 'both'), @(40, 'dark')) {
        Assert-Equal $case[1] (Get-WallpaperVariant -Lightness $case[0]) "lightness $($case[0])"
    }
}

Test 'Wallpaper: retry delays for a rate-limited download' {
    $now = [datetimeoffset]::new(2026, 11, 16, 12, 0, 0, [timespan]::Zero)
    Assert-Equal 5 (Get-WallpaperRetryDelay -Status 429 -Attempt 1) 'first retry, no Retry-After'
    Assert-Equal 20 (Get-WallpaperRetryDelay -Status 503 -Attempt 3) 'backs off by doubling'
    Assert-Equal 30 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter '30') 'Retry-After in seconds'
    Assert-Equal 45 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter 'Mon, 16 Nov 2026 12:00:45 GMT' -Now $now) 'Retry-After as a date'
    Assert-Equal 1 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter '0') 'never sooner than the gap'
    Assert-Equal 1 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter 'Mon, 16 Nov 2026 11:59:00 GMT' -Now $now) 'a date in the past'
    Assert-Equal 600 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter '600') 'a long Retry-After is honored, not cut short'
    Assert-Equal 40 (Get-WallpaperRetryDelay -Status 429 -Attempt 4) 'last retry without Retry-After'
    Assert-Equal 5 (Get-WallpaperRetryDelay -Status 429 -Attempt 1 -RetryAfter 'soon') 'unreadable Retry-After falls back'
    Assert-Equal -1 (Get-WallpaperRetryDelay -Status 404 -Attempt 1) '404 is not retried'
    Assert-Equal -1 (Get-WallpaperRetryDelay -Status 429 -Attempt 5) 'attempts spent'
}

Test 'Wallpaper: candidates filtered and ranked by variant' {
    $c = { param($Name, $L, $S, $D) [pscustomobject]@{ Name = $Name; Fit = @{ Lightness = $L; Saturation = $S; Detail = $D; Variant = (Get-WallpaperVariant -Lightness $L) } } }
    $all = @(
        (& $c 'busy-night' 20 10 3.0)
        (& $c 'calm-night' 25 5 0.2)
        (& $c 'dusk' 50 5 0.1)
        (& $c 'snow' 90 2 0.1)
    )
    Assert-Equal @('calm-night', 'busy-night', 'dusk') @((Select-WallpaperCandidate -Candidate $all -Variant dark).Name) 'dark: exact marks first, calmest first, then both'
    Assert-Equal @('snow', 'dusk') @((Select-WallpaperCandidate -Candidate $all -Variant light).Name) 'light'
    Assert-Equal @('dusk') @((Select-WallpaperCandidate -Candidate $all -Variant both).Name) 'both'
    Assert-Equal @('snow', 'dusk', 'calm-night', 'busy-night') @((Select-WallpaperCandidate -Candidate $all).Name) 'no variant: calmest first'
}

Test 'Wallpaper: folder needs thumbnails and credits' {
    $dir = Join-Path $Tmp ('wp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $dir 'thumbs') -Force | Out-Null
    Set-Content (Join-Path $dir 'good.jpg') 'x'; Set-Content (Join-Path $dir 'thumbs' 'good.jpg') 'x'
    Set-Content (Join-Path $dir 'bare.jpg') 'x'
    Set-Content (Join-Path $dir 'thumbs' 'orphan.jpg') 'x'
    Set-Content (Join-Path $dir 'README.md') @"
# Wallpapers

## Good

| File | [``good.jpg``](good.jpg) |
| Variant | Light |
| Author | A |
| Source | [S](https://example.invalid) |
| License | CC0 |

## Gone

| File | [``gone.jpg``](gone.jpg) |
"@
    $all = (Test-WallpaperFolder -Path $dir) -join "`n"
    foreach ($want in 'bare.jpg has no thumbs/bare.jpg', 'bare.jpg has no section', 'thumbs/orphan.jpg has no wallpaper', 'credits gone.jpg') {
        Assert-True ($all -like "*$want*") "expected '$want' in:`n$all"
    }
    Assert-True ($all -notlike '*good.jpg*') "good.jpg should pass:`n$all"
}

Test 'Wallpaper: folder needs a variant mark, and pairs of one dark and one light' {
    $dir = Join-Path $Tmp ('wp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $dir 'thumbs') -Force | Out-Null
    foreach ($n in 'day', 'night', 'snow-a', 'snow-b', 'fog', 'odd', 'late-a', 'late-b') {
        Set-Content (Join-Path $dir "$n.jpg") 'x'; Set-Content (Join-Path $dir 'thumbs' "$n.jpg") 'x'
    }
    $image = { param($Name, $Mark) @"
| | |
|---|---|
| File | [``$Name.jpg``]($Name.jpg) |
$(if ($Mark) { "| Variant | $Mark |" })
| Author | A |
| Source | [S](https://example.invalid) |
| License | CC0 |
"@ }
    Set-Content (Join-Path $dir 'README.md') @"
# Wallpapers

## Dunes

### Light

$(& $image 'day' 'Light')

### Dark

$(& $image 'night' 'Dark')

## Snow

### One

$(& $image 'snow-a' 'Light')

### Two

$(& $image 'snow-b' 'light')

## Fog

$(& $image 'fog' 'Both')

## Odd

$(& $image 'odd' '')

## Late

### Light

$(& $image 'late-a' 'Light')

### Dark

$(& $image 'late-b' 'Dark')
"@
    $all = (Test-WallpaperFolder -Path $dir) -join "`n"
    foreach ($want in "the Snow pair needs one dark and one light image", 'the odd.jpg section has no Variant', "the Late pair comes after a single image") {
        Assert-True ($all -like "*$want*") "expected '$want' in:`n$all"
    }
    foreach ($fine in 'Dunes', 'day.jpg', 'night.jpg', 'fog.jpg') { Assert-True ($all -notlike "*$fine*") "$fine should pass:`n$all" }
    Assert-Equal 3 @(Test-WallpaperFolder -Path $dir).Count "problems:`n$all"
}

Test 'Wallpaper: a port uses a wallpaper only for a variant it is marked for' {
    $dir = Join-Path $Tmp ('wp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $image = { param($Name, $Mark) "## $Name`n`n| | |`n|---|---|`n| File | [``$Name.jpg``]($Name.jpg) |`n| Variant | $Mark |`n" }
    Set-Content (Join-Path $dir 'README.md') "# Wallpapers`n`n$(& $image 'snow' 'Light')`n$(& $image 'night' 'Dark')`n$(& $image 'dusk' 'Both')"
    $url = { param($Name) "url(`"../../../../wallpapers/$Name.jpg`")" }
    $good = @{ dark = @{ wallpaper = (& $url 'night') }; light = @{ wallpaper = (& $url 'snow'); other = (& $url 'dusk') } }
    Assert-Equal 0 @(Test-WallpaperUse -Path $dir -Values $good -Source 'values.json').Count 'marked uses pass'
    Assert-Equal 0 @(Test-WallpaperUse -Path $dir -Values @{ dark = @{ wallpaper = 'none' } } -Source 'values.json').Count 'no wallpaper passes'
    $bad = @{ dark = @{ wallpaper = (& $url 'snow') }; light = @{ wallpaper = (& $url 'gone') } }
    Assert-Equal @(
        "values.json: dark uses snow.jpg, which wallpapers/README.md marks light.",
        "values.json: light uses gone.jpg, which wallpapers/README.md does not mark."
    ) @(Test-WallpaperUse -Path $dir -Values $bad -Source 'values.json') 'problems'
}

# --- Entry scripts --------------------------------------------------------------

# Each runs in its own pwsh, as a person would run it. Returns @{ Exit; Text }.
function Invoke-Script([string]$Name, [string[]]$Arguments) {
    $pwsh = (Get-Process -Id $PID).Path
    $out = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot $Name) @Arguments 2>&1
    return @{ Exit = $LASTEXITCODE; Text = ($out | ForEach-Object { "$_" }) -join "`n" }
}

function New-TestImage([string]$Path, [int]$Width, [int]$Height) {
    # A flat gray binary PPM, which ImageSharp reads like a JPEG.
    $head = [System.Text.Encoding]::ASCII.GetBytes("P6`n$Width $Height`n255`n")
    $body = [byte[]]::new($Width * $Height * 3)
    [Array]::Fill($body, [byte]200)
    $fs = [System.IO.File]::Create($Path)
    try { $fs.Write($head, 0, $head.Length); $fs.Write($body, 0, $body.Length) } finally { $fs.Dispose() }
}

Test 'Entry: wallpaper.ps1 -Check passes a wide image and fails a small one' {
    # A local file, so nothing goes to Commons. ImageSharp is fetched once
    # from NuGet if it is not cached yet.
    $wide = Join-Path $Tmp 'wide.ppm'
    New-TestImage $wide 1920 1080
    $r = Invoke-Script 'wallpaper.ps1' @('-Check', $wide)
    Assert-Equal 0 $r.Exit "exit code, output:`n$($r.Text)"
    Assert-True ($r.Text -like '*Passes the format gate*') "no pass line in:`n$($r.Text)"
    Assert-True ($r.Text -notlike '*Fails*') "a fail line in:`n$($r.Text)"
    $small = Join-Path $Tmp 'small.ppm'
    New-TestImage $small 200 100
    $r = Invoke-Script 'wallpaper.ps1' @('-Check', $small)
    Assert-Equal 1 $r.Exit "exit code, output:`n$($r.Text)"
    Assert-True ($r.Text -like "*Fails:*- 200 px wide, needs at least 1920.*") "no reason in:`n$($r.Text)"
}

Test 'Entry: contrast.ps1 lists every measurement of the palette and passes' {
    $r = Invoke-Script 'contrast.ps1' @()
    Assert-Equal 0 $r.Exit "exit code, output:`n$($r.Text)"
    Assert-True ($r.Text -match '(?m)^dark +text +panel_flat +\d+\.\d\d +4\.5 +pass$') "no dark text on panel_flat line in:`n$($r.Text)"
    Assert-True ($r.Text -match '(\d+) measurements, 0 failing') "no summary in:`n$($r.Text)"
}

Test 'Entry: contrast.ps1 -Set tries a value and fails it' {
    $r = Invoke-Script 'contrast.ps1' @('-Set', 'dark.roles.panel.alpha=0.3', '-Variant', 'dark', '-Role', 'text', '-Surface', 'panel over white')
    Assert-Equal 1 $r.Exit "exit code, output:`n$($r.Text)"
    Assert-True ($r.Text -match '(?m)^dark +text +panel over white +\d+\.\d\d +4\.5 +FAIL$') "no failing line in:`n$($r.Text)"
    $r = Invoke-Script 'contrast.ps1' @('-Set', 'dark.roles.nope=#000000')
    Assert-Equal 2 $r.Exit "unknown path exit code, output:`n$($r.Text)"
}

Test 'Entry: roles.ps1 reports ports and roles' {
    $r = Invoke-Script 'roles.ps1' @('-Role', 'text')
    Assert-Equal 0 $r.Exit "exit code, output:`n$($r.Text)"
    Assert-True ($r.Text -like "text*used by:*preview*") "no report in:`n$($r.Text)"
    $r = Invoke-Script 'roles.ps1' @()
    Assert-True ($r.Text -match '(?m)^preview \(\d+ of \d+ roles\)$') "no preview line in:`n$($r.Text)"
}

# --- Summary ------------------------------------------------------------------

Remove-Item -Path $Tmp -Recurse -Force -ErrorAction SilentlyContinue
foreach ($f in $script:Failed) { Write-Host "FAIL: $f" -ForegroundColor Red }
Write-Host "$($script:Passed) passed, $($script:Failed.Count) failed."
if ($script:Failed.Count -gt 0) { exit 1 }
exit 0
