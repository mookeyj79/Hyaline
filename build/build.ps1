#requires -Version 7.0
<#
.SYNOPSIS
    Builds theme files for every port from palette/palette.json.

.DESCRIPTION
    For each folder in Ports/ that has a template/ folder, every file in
    template/ is rendered once per palette variant into dist/<variant>/.
    File names and folder structure are kept. Placeholders are allowed in
    file contents and in file names. The placeholders are listed in
    CONTRIBUTING.md ("Add a port", step 4) and defined in
    build/lib/Placeholders.psm1.

.PARAMETER Port
    Build only this port (the folder name under Ports/).

.PARAMETER Quiet
    Print nothing on success.

.OUTPUTS
    One line per port saying what changed in its dist/: "changed" (colors or
    other content), "version stamp only" (only the palette version moved),
    "unchanged", or "new". Use it when summarizing a palette change.

.EXAMPLE
    pwsh build/build.ps1

.EXAMPLE
    pwsh build/build.ps1 -Port windows-terminal
#>
[CmdletBinding()]
param(
    [string]$Port,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib' 'Palette.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib' 'Build.psm1') -Force

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$PortsRoot = Join-Path $RepoRoot 'Ports'

$palette = Read-Palette -Path (Join-Path $RepoRoot 'palette' 'palette.json')
if ($palette.Errors.Count -gt 0) {
    throw "palette/palette.json has problems. Run build/check.ps1 for the full list.`n" + ($palette.Errors -join "`n")
}

$portDirs = if (Test-Path $PortsRoot) { @(Get-ChildItem -Path $PortsRoot -Directory | Sort-Object Name) } else { @() }
if ($Port) {
    $portDirs = @($portDirs | Where-Object { $_.Name -eq $Port })
    if ($portDirs.Count -eq 0) { throw "Port not found: Ports/$Port" }
}

$built = 0
$fileCount = 0
foreach ($dir in $portDirs) {
    if (-not (Test-Path (Join-Path $dir.FullName 'template'))) {
        if (-not $Quiet) { Write-Warning "Skipping $($dir.Name): no template/ folder." }
        continue
    }
    $result = Update-Port -Palette $palette -PortDir $dir.FullName
    $built++
    $fileCount += $result.Written
    if (-not $Quiet) { Write-Host "Built $($dir.Name): $($result.Status)" }
}

if (-not $Quiet) {
    $name = $palette.Meta['name']
    $version = $palette.Meta['version']
    if ($built -eq 0) { Write-Host "$name ${version}: no ports to build yet." }
    else { Write-Host "$name ${version}: $built port(s), $fileCount file(s) written." }
}
