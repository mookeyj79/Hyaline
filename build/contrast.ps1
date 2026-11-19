#requires -Version 7.0
<#
.SYNOPSIS
    Prints every contrast measurement for a palette, passing or not. Exits 1
    if any fails.

.DESCRIPTION
    Takes the same measurements as the Contrast section of check.ps1, with
    the same module (Test-PaletteContrast in build/lib/Palette.psm1), so the
    numbers match. Use it to try palette values before they go in
    palette/palette.json: point -Palette at an edited copy, or change single
    values with -Set.

    One line per measurement: variant, foreground role, surface (with the
    backdrop and whether the glass is blurred), ratio, floor, and pass or FAIL.

.PARAMETER Palette
    The palette to measure. Default palette/palette.json.

.PARAMETER Set
    A value to change before measuring, as path=value. The path starts at a
    variant: dark.roles.panel=#40444b, dark.roles.panel.alpha=0.8,
    light.roles.chrome.glass.alpha=0.5, dark.wash=0.2. Setting a hex on
    a role that has an alpha keeps the alpha. Separate several values with
    commas.

.PARAMETER Variant
    Show only this variant.

.PARAMETER Role
    Show only these foreground roles. Wildcards work.

.PARAMETER Surface
    Show only surfaces like this, such as "panel*" or "*blurred over white".

.PARAMETER Failing
    Show only measurements under the floor: failures, and glass set by eye.

.EXAMPLE
    pwsh build/contrast.ps1

.EXAMPLE
    pwsh build/contrast.ps1 -Set dark.roles.panel=#40444b,dark.roles.panel.alpha=0.8 -Variant dark -Surface 'panel*'

.EXAMPLE
    pwsh build/contrast.ps1 -Palette ./candidate.json -Failing
#>
[CmdletBinding()]
param(
    [string]$Palette,
    [string[]]$Set = @(),
    [ValidateSet('dark', 'light')]
    [string]$Variant,
    [string[]]$Role = @('*'),
    [string]$Surface = '*',
    [switch]$Failing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib' 'Palette.psm1') -Force

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Palette) { $Palette = Join-Path $RepoRoot 'palette' 'palette.json' }
if (-not (Test-Path -LiteralPath $Palette)) { Write-Host "$Palette does not exist."; exit 2 }

try { $data = Get-Content -Raw -LiteralPath $Palette | ConvertFrom-Json -AsHashtable }
catch { Write-Host "$Palette is not valid JSON: $($_.Exception.Message)"; exit 2 }

# From bash, -Set a,b arrives as one string: split it here.
foreach ($s in ($Set -split ',')) {
    if ($s -notmatch '^([A-Za-z0-9_.]+)=(.+)$') { Write-Host "-Set '$s' is not path=value."; exit 2 }
    $keys = @('variants') + ($Matches[1] -split '\.')
    $text = $Matches[2].Trim()
    $number = 0.0
    $value = if ([double]::TryParse($text, 'Float', [cultureinfo]::InvariantCulture, [ref]$number)) { $number } else { $text }
    $node = $data
    for ($i = 0; $i -lt $keys.Count - 1; $i++) {
        $node = if ($node -is [System.Collections.IDictionary]) { $node[$keys[$i]] } else { $null }
        if ($node -isnot [System.Collections.IDictionary]) { Write-Host "-Set '$s': $(($keys[1..$i]) -join '.') is not in the palette."; exit 2 }
    }
    $last = $keys[-1]
    if (-not $node.Contains($last)) { Write-Host "-Set '$s': $($Matches[1]) is not in the palette."; exit 2 }
    if ($node[$last] -is [System.Collections.IDictionary] -and $value -is [string]) { $node[$last]['hex'] = $value }
    else { $node[$last] = $value }
}

$p = Read-Palette -Data $data
if ($p.Errors.Count) {
    foreach ($e in $p.Errors) { Write-Host "Palette: $e" }
    exit 2
}

# From the command line, -Role a,b arrives as one string.
$Role = @($Role | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

$all = @((Test-PaletteContrast -Palette $p).Measurements)
$shown = @($all | Where-Object {
    $m = $_
    (-not $Variant -or $m.Variant -eq $Variant) -and
    @($Role | Where-Object { $m.Role -like $_ }).Count -gt 0 -and
    $m.Surface -like $Surface -and
    (-not $Failing -or -not $m.Pass)
})

$line = '{0,-6} {1,-11} {2,-42} {3,7} {4,5}  {5}'
Write-Output ($line -f 'Var', 'Role', 'Surface', 'Ratio', 'Floor', 'Result')
foreach ($m in $shown) {
    Write-Output ($line -f $m.Variant, $m.Role, $m.Surface, $m.Ratio.ToString('0.00', [cultureinfo]::InvariantCulture),
        $m.Floor.ToString('0.0', [cultureinfo]::InvariantCulture), $(if ($m.Pass) { 'pass' } elseif ($m.Enforced) { 'FAIL' } else { 'by eye' }))
}

$fails = @($all | Where-Object { -not $_.Pass -and $_.Enforced })
$byEye = @($all | Where-Object { -not $_.Pass -and -not $_.Enforced })
Write-Output ''
Write-Output "$($all.Count) measurements, $($fails.Count) failing, $($byEye.Count) under the floor on glass set by eye ($($shown.Count) shown)."
if ($fails.Count) { exit 1 }
exit 0
