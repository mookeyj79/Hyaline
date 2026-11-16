#requires -Version 7.0
<#
.SYNOPSIS
    Reports which palette roles each port's templates use. A report, not a
    check: it exits 0 whatever ports use, 1 only on a bad -Role or palette.

.DESCRIPTION
    Reads every {{placeholder}} in each port's template/ folder, file names
    included. A {{role}} counts with any filter, and an {{ansi.<slot>}} counts
    as the role the slot maps to in either variant.

    Without -Role: per port, the roles it uses and the surface and edge roles
    it does not. With -Role: the ports that use each role and those that do
    not, for checking which ports adopted a new role.

.PARAMETER Role
    Roles to report on, such as window_edge_flat.

.EXAMPLE
    pwsh build/roles.ps1

.EXAMPLE
    pwsh build/roles.ps1 -Role window_edge_flat
#>
[CmdletBinding()]
param([string[]]$Role = @())

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($m in 'Palette', 'Placeholders', 'Catalog') {
    Import-Module (Join-Path $PSScriptRoot 'lib' "$m.psm1") -Force
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$palette = Read-Palette -Path (Join-Path $RepoRoot 'palette' 'palette.json')
if ($palette.Errors.Count) { Write-Host 'The palette has errors. Run build/check.ps1.'; exit 1 }
$catalog = Get-PortCatalog -PortsRoot (Join-Path $RepoRoot 'Ports') -VariantKeys (Get-VariantKeys)

# From the command line, -Role a,b arrives as one string.
$Role = @($Role | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$known = Get-RequiredRoles
foreach ($r in $Role) { if ($r -notin $known) { Write-Host "'$r' is not a palette role. Roles: $($known -join ', ')."; exit 1 } }

$usage = [ordered]@{}
foreach ($port in $catalog.Ports | Where-Object HasTemplate) {
    $templateDir = Join-Path $port.Dir 'template'
    $text = foreach ($file in Get-ChildItem -Path $templateDir -Recurse -File -Force) {
        [System.IO.Path]::GetRelativePath($templateDir, $file.FullName)
        $tpl = Read-TemplateFile -Path $file.FullName
        if (-not $tpl.Binary) { $tpl.Text }
    }
    $usage[$port.Name] = @(Get-PlaceholderRole -Text ($text -join "`n") -Palette $palette)
}

if ($Role.Count) {
    foreach ($r in $Role) {
        $using = @($usage.Keys | Where-Object { $r -in $usage[$_] })
        $not = @($usage.Keys | Where-Object { $r -notin $usage[$_] })
        Write-Output $r
        Write-Output "  used by:     $(if ($using) { $using -join ', ' } else { 'none' })"
        Write-Output "  not used by: $(if ($not) { $not -join ', ' } else { 'none' })"
    }
    exit 0
}

$surfaces = Get-SurfaceRoles
foreach ($name in $usage.Keys) {
    $used = @($known | Where-Object { $_ -in $usage[$name] })
    $missing = @($surfaces | Where-Object { $_ -notin $usage[$name] })
    Write-Output "$name ($($used.Count) of $($known.Count) roles)"
    Write-Output "  uses:     $($used -join ', ')"
    Write-Output "  not used: $(if ($missing) { $missing -join ', ' } else { 'none' })   (surface and edge roles)"
}
exit 0
