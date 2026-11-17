#requires -Version 7.0
<#
.SYNOPSIS
    Checks the palette and every port. Exits 1 if anything fails.

.DESCRIPTION
    1. Palette       Both variants exist, every required role is present and valid.
    2. Contrast      Text and color roles meet the contrast floor in PHILOSOPHY.md
                     (ADR 0011). Solid surfaces are measured as drawn. Chrome and
                     panel glass are measured over pure black and pure white, at
                     the dense alpha and through the clamp, and every result must
                     pass. Chrome carries primary text only. Raised is
                     raised_flat, and translucent raised on the clamped panel.
                     Washes are measured over every panel surface. Opacity-only
                     glass (the panel at its dense alpha, and washes over it)
                     is held to the opacity-only rows for the panel and a wash
                     (ADR 0013); everything else to the full rows. The numbers
                     are in PHILOSOPHY.md, "Contrast floor". line and edge have
                     no floor.
    3. Structure     Every port has a README.md and a template/ folder, and a
                     site.json, where there is one, points at real files.
    4. Port list     Every port has a valid port.json (except folders listed as
                     unlisted), and planned ports in Ports/ports.json do not
                     exist yet. A port's icon.svg and the "icon" credit in its
                     port.json come together, and the icon is plain shapes in
                     currentColor on a 24 x 24 viewBox (ADR 0007).
    5. Raw color     No hex, rgb(), or hsl() values in templates or values.json.
                     Add "hyaline-ignore" to a line to skip it (for example a CSS
                     id selector that happens to look like a hex color).
    6. Placeholders  Every {{placeholder}} in every template resolves in both
                     variants, and the table in CONTRIBUTING.md lists exactly
                     the filters the build supports.
    7. Drift         Committed dist/ matches a fresh build.
    8. Leftovers     No unresolved {{placeholders}} in dist/.
    9. Format        Every dist/ file is valid for its format: .json parses,
                     .svg and .xml are well formed, and .css has balanced
                     braces, comments, and quotes.
   10. Wallpapers   Every image in wallpapers/ has a thumbnail and a section in
                     wallpapers/README.md with its author, source, license, and
                     variant mark. Each pair has one dark and one light image,
                     and pairs come before single images. A port's values.json
                     shows a wallpaper only in a variant it is marked for.
   11. Prose         No em dashes in the repo's Markdown (outside dist/ and
                     third-party assets/). Add "hyaline-ignore" to a line to
                     skip it.

    The rules live in build/lib/: Palette.psm1, Placeholders.psm1,
    Build.psm1, Catalog.psm1, and Wallpaper.psm1. This script runs them and reports.

.EXAMPLE
    pwsh build/check.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($m in 'Palette', 'Placeholders', 'Build', 'Catalog', 'Wallpaper') {
    Import-Module (Join-Path $PSScriptRoot 'lib' "$m.psm1") -Force
}

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$PortsRoot = Join-Path $RepoRoot 'Ports'

$script:Failures = [System.Collections.Generic.List[string]]::new()
function Add-Failure([string]$Message) { $script:Failures.Add($Message) }

function Invoke-Section([string]$Title, [scriptblock]$Body) {
    $before = $script:Failures.Count
    & $Body
    $status = if ($script:Failures.Count -gt $before) { 'FAIL' } else { 'ok' }
    Write-Host ('{0,-12} {1}' -f $Title, $status)
}
function Skip-Section([string]$Title, [string]$Reason) { Write-Host ('{0,-12} skipped ({1})' -f $Title, $Reason) }

function Get-RepoPath([string]$Path) { [System.IO.Path]::GetRelativePath($RepoRoot, $Path) -replace '\\', '/' }

$palette = Read-Palette -Path (Join-Path $RepoRoot 'palette' 'palette.json')
$paletteOk = $palette.Errors.Count -eq 0
$catalog = Get-PortCatalog -PortsRoot $PortsRoot -VariantKeys (Get-VariantKeys)
$templatePorts = @($catalog.Ports | Where-Object HasTemplate)

# --- 1. Palette ---------------------------------------------------------------

Invoke-Section 'Palette' { foreach ($e in $palette.Errors) { Add-Failure "Palette: $e" } }

# --- 2. Contrast --------------------------------------------------------------

if ($paletteOk) {
    Invoke-Section 'Contrast' {
        $c = Test-PaletteContrast -Palette $palette
        foreach ($f in $c.Failures) { Add-Failure "Contrast: $f" }
    }
}
else { Skip-Section 'Contrast' 'fix the palette first' }

# --- 3. Structure -------------------------------------------------------------

Invoke-Section 'Structure' { foreach ($e in $catalog.StructureErrors) { Add-Failure "Structure: $e" } }

# --- 4. Port list -------------------------------------------------------------

Invoke-Section 'Port list' {
    foreach ($e in $catalog.Errors) { Add-Failure $(if ($e -like 'Icon: *') { $e } else { "Port list: $e" }) }
}

# --- 5. Raw colors in templates -------------------------------------------------

Invoke-Section 'Raw color' {
    $hexPattern  = '(?<![\w&])#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b'
    $funcPattern = '\b(?:rgba?|hsla?)\(\s*[\d.]'
    foreach ($port in $templatePorts) {
        $scan = @(Get-ChildItem -Path (Join-Path $port.Dir 'template') -Recurse -File -Force)
        $valuesPath = Join-Path $port.Dir 'values.json'
        if (Test-Path $valuesPath) { $scan += Get-Item -Path $valuesPath }
        foreach ($file in $scan) {
            $tpl = Read-TemplateFile -Path $file.FullName
            if ($tpl.Binary) { continue }
            $rel = Get-RepoPath $file.FullName
            $lineNo = 0
            foreach ($line in $tpl.Text -split "`r?`n") {
                $lineNo++
                if ($line -match 'hyaline-ignore') { continue }
                foreach ($pattern in $hexPattern, $funcPattern) {
                    $m = [regex]::Match($line, $pattern)
                    if ($m.Success) { Add-Failure "Raw color: ${rel}:$lineNo contains '$($m.Value)'. Use a {{role}} placeholder." }
                }
            }
        }
    }
}

# --- 6. Placeholders ------------------------------------------------------------

$placeholderOk = $true
if ($paletteOk) {
    Invoke-Section 'Placeholders' {
        $before = $script:Failures.Count
        foreach ($port in $templatePorts) {
            $values = $null
            $valuesPath = Join-Path $port.Dir 'values.json'
            if (Test-Path $valuesPath) {
                try { $values = Get-Content -Raw -Path $valuesPath | ConvertFrom-Json -AsHashtable }
                catch { Add-Failure "Placeholders: $(Get-RepoPath $valuesPath) is not valid JSON: $($_.Exception.Message)"; continue }
            }
            $templateDir = Join-Path $port.Dir 'template'
            foreach ($file in Get-ChildItem -Path $templateDir -Recurse -File -Force) {
                $rel = Get-RepoPath $file.FullName
                $nameRel = [System.IO.Path]::GetRelativePath($templateDir, $file.FullName)
                foreach ($e in Find-PlaceholderError -Text $nameRel -Palette $palette -PortValues $values) {
                    Add-Failure "Placeholders: $rel (file name): $e"
                }
                $tpl = Read-TemplateFile -Path $file.FullName
                if ($tpl.Binary) { continue }
                foreach ($e in Find-PlaceholderError -Text $tpl.Text -Palette $palette -PortValues $values) {
                    Add-Failure "Placeholders: ${rel}: $e"
                }
            }
        }
        $script:placeholderOk = $script:Failures.Count -eq $before

        # The CONTRIBUTING.md table documents the filters; keep it complete.
        $docPath = Join-Path $RepoRoot 'CONTRIBUTING.md'
        if (Test-Path $docPath) {
            $documented = @([regex]::Matches((Get-Content -Raw $docPath), '\{\{role\\?\|([a-z]+)\}\}') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            $supported = @(Get-ColorFilters | Sort-Object)
            foreach ($f in $supported) { if ($f -notin $documented) { Add-Failure "Placeholders: CONTRIBUTING.md does not list the filter {{role|$f}}." } }
            foreach ($f in $documented) { if ($f -notin $supported) { Add-Failure "Placeholders: CONTRIBUTING.md lists {{role|$f}}, which the build does not support." } }
        }
    }
}
else { Skip-Section 'Placeholders' 'fix the palette first' }

# --- 7. Drift -----------------------------------------------------------------

if (-not $paletteOk) { Skip-Section 'Drift' 'fix the palette first' }
elseif (-not $placeholderOk) { Skip-Section 'Drift' 'fix the placeholders first' }
else {
    Invoke-Section 'Drift' {
        foreach ($port in $templatePorts) {
            $dist = "Ports/$($port.Name)/dist"
            try { $status = Get-PortStatus -Palette $palette -PortDir $port.Dir }
            catch { Add-Failure "Drift: Ports/$($port.Name) does not build: $($_.Exception.Message)"; continue }
            foreach ($f in $status.Files) {
                switch ($f.Kind) {
                    'missing' { Add-Failure "Drift: $dist/$($f.Path) is missing. Run build/build.ps1." }
                    'extra'   { Add-Failure "Drift: $dist/$($f.Path) is not produced by the build. Delete it or run build/build.ps1." }
                    default   { Add-Failure "Drift: $dist/$($f.Path) is out of date. Run build/build.ps1." }
                }
            }
        }
    }
}

# --- 8. Unresolved placeholders in dist -----------------------------------------

Invoke-Section 'Leftovers' {
    foreach ($port in $catalog.Ports) {
        $distDir = Join-Path $port.Dir 'dist'
        if (-not (Test-Path $distDir)) { continue }
        foreach ($file in Get-ChildItem -Path $distDir -Recurse -File -Force) {
            $rel = Get-RepoPath $file.FullName
            if (Find-Placeholder -Text $file.Name) { Add-Failure "Leftover: $rel has a placeholder in its file name." }
            $tpl = Read-TemplateFile -Path $file.FullName
            if ($tpl.Binary) { continue }
            $left = Find-Placeholder -Text $tpl.Text
            if ($left) { Add-Failure "Leftover: $rel still contains '$left'." }
        }
    }
}

# --- 9. Format of generated files -----------------------------------------------

function Test-CssBalance([string]$Text) {
    # Returns $null when balanced, otherwise a short reason.
    $depth = 0
    $i = 0
    $n = $Text.Length
    while ($i -lt $n) {
        $c = $Text[$i]
        if ($c -eq '/' -and $i + 1 -lt $n -and $Text[$i + 1] -eq '*') {
            $end = $Text.IndexOf('*/', $i + 2)
            if ($end -lt 0) { return 'unclosed /* comment' }
            $i = $end + 2
            continue
        }
        if ($c -eq '"' -or $c -eq "'") {
            $j = $i + 1
            while ($j -lt $n -and $Text[$j] -ne $c) {
                if ($Text[$j] -eq '\') { $j++ }
                elseif ($Text[$j] -eq "`n") { return "unclosed $c string" }
                $j++
            }
            if ($j -ge $n) { return "unclosed $c string" }
            $i = $j + 1
            continue
        }
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') {
            $depth--
            if ($depth -lt 0) { return "unexpected '}'" }
        }
        $i++
    }
    if ($depth -gt 0) { return "$depth unclosed '{'" }
    return $null
}

Invoke-Section 'Format' {
    foreach ($port in $catalog.Ports) {
        $distDir = Join-Path $port.Dir 'dist'
        if (-not (Test-Path $distDir)) { continue }
        foreach ($file in Get-ChildItem -Path $distDir -Recurse -File -Force) {
            $rel = Get-RepoPath $file.FullName
            $ext = $file.Extension.ToLowerInvariant()
            if ($ext -notin '.json', '.svg', '.xml', '.css') { continue }
            $text = [System.IO.File]::ReadAllText($file.FullName)
            switch ($ext) {
                '.json' {
                    try { $null = $text | ConvertFrom-Json -AsHashtable }
                    catch { Add-Failure "Format: $rel is not valid JSON: $($_.Exception.Message)" }
                }
                { $_ -in '.svg', '.xml' } {
                    try { $null = [xml]$text }
                    catch { Add-Failure "Format: $rel is not well-formed XML: $($_.Exception.Message)" }
                }
                '.css' {
                    $reason = Test-CssBalance $text
                    if ($reason) { Add-Failure "Format: $rel has broken CSS: $reason." }
                }
            }
        }
    }
}

# --- 10. Wallpapers -------------------------------------------------------------

Invoke-Section 'Wallpapers' {
    $wallpaperDir = Join-Path $RepoRoot 'wallpapers'
    foreach ($e in Test-WallpaperFolder -Path $wallpaperDir) { Add-Failure "Wallpapers: $e" }
    foreach ($port in $catalog.Ports) {
        $valuesPath = Join-Path $port.Dir 'values.json'
        if (-not (Test-Path $valuesPath)) { continue }
        # Invalid JSON is reported by the Placeholders section.
        try { $values = Get-Content -Raw -Path $valuesPath | ConvertFrom-Json -AsHashtable } catch { continue }
        if ($values -isnot [System.Collections.IDictionary]) { continue }
        foreach ($e in Test-WallpaperUse -Path $wallpaperDir -Values $values -Source (Get-RepoPath $valuesPath)) { Add-Failure "Wallpapers: $e" }
    }
}

# --- 11. Prose ------------------------------------------------------------------

Invoke-Section 'Prose' {
    $emDash = [string][char]0x2014
    $mdFiles = @()
    Push-Location $RepoRoot
    try { $mdFiles = @(git ls-files -- '*.md' 2>$null) }
    finally { Pop-Location }
    if ($LASTEXITCODE -ne 0 -or $mdFiles.Count -eq 0) {
        # Not a git checkout: fall back to the file system, skipping local folders.
        $mdFiles = @(Get-ChildItem -Path $RepoRoot -Recurse -File -Filter '*.md' -Force |
            ForEach-Object { Get-RepoPath $_.FullName } |
            Where-Object { $_ -notmatch '^(\.git|_site|scripts|\.claude/worktrees)/' })
    }
    foreach ($rel in $mdFiles) {
        if ($rel -match '(^|/)(dist|assets)/') { continue }
        $path = Join-Path $RepoRoot $rel
        if (-not (Test-Path $path)) { continue }
        $lineNo = 0
        foreach ($line in [System.IO.File]::ReadAllLines($path)) {
            $lineNo++
            if ($line.Contains($emDash) -and $line -notmatch 'hyaline-ignore') {
                Add-Failure "Prose: ${rel}:$lineNo has an em dash. Use a colon, comma, or period."
            }
        }
    }
}

# --- Summary ------------------------------------------------------------------

Write-Host ''
if ($catalog.Ports.Count -eq 0) { Write-Host 'No ports yet. Palette checks only.' }

foreach ($f in $script:Failures) { Write-Host "FAIL: $f" -ForegroundColor Red }

if ($script:Failures.Count -gt 0) {
    Write-Host ''
    Write-Host "$($script:Failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "All checks passed ($($catalog.Ports.Count) port(s))."
exit 0
