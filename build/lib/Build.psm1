# Building a port: rendering its template/ into dist/<variant>/ for every
# palette variant, and telling how a build compares with the committed dist/.
# build.ps1 writes with it; check.ps1 asks it whether dist/ is current.

Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Placeholders.psm1')

function Read-PortValues([string]$PortDir) {
    $path = Join-Path $PortDir 'values.json'
    if (Test-Path $path) { return Get-Content -Raw -Path $path | ConvertFrom-Json -AsHashtable }
    return $null
}

function Write-PortFiles {
    # Renders the port into $OutRoot/<variant>/, replacing what is there.
    # Returns the number of files written. Throws on a bad placeholder.
    param($Palette, [string]$PortDir, [string]$OutRoot)
    $name = Split-Path -Leaf $PortDir
    $templateDir = Join-Path $PortDir 'template'
    $files = @(Get-ChildItem -Path $templateDir -Recurse -File -Force)
    $values = Read-PortValues $PortDir
    $count = 0
    foreach ($variant in $Palette.Variants.Values) {
        $outDir = Join-Path $OutRoot $variant.Key
        if (Test-Path $outDir) { Remove-Item -Path $outDir -Recurse -Force }
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        foreach ($file in $files) {
            $rel = [System.IO.Path]::GetRelativePath($templateDir, $file.FullName)
            $source = "Ports/$name/template/$($rel -replace '\\', '/')"
            $relOut = Expand-Template -Text $rel -Palette $Palette -Variant $variant -PortValues $values -Source "$source (file name)"
            $target = Join-Path $outDir $relOut
            $targetDir = Split-Path -Parent $target
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            $tpl = Read-TemplateFile -Path $file.FullName
            if ($tpl.Binary) { [System.IO.File]::WriteAllBytes($target, $tpl.Bytes) }
            else {
                $text = Expand-Template -Text $tpl.Text -Palette $Palette -Variant $variant -PortValues $values -Source $source
                $bytes = [byte[]](@($tpl.Encoding.GetPreamble()) + @($tpl.Encoding.GetBytes($text)))
                [System.IO.File]::WriteAllBytes($target, $bytes)
            }
            $count++
        }
    }
    return $count
}

function Get-Snapshot([string]$Root) {
    # Relative path -> content. Text has line endings normalized, so a CRLF
    # checkout is not a change; binary files are compared by hash.
    $snap = @{}
    if (-not (Test-Path $Root)) { return $snap }
    foreach ($f in Get-ChildItem -Path $Root -Recurse -File -Force) {
        $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\', '/'
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $snap[$rel] = if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { 'bin:' + (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash }
                      else { 'txt:' + ([System.Text.Encoding]::UTF8.GetString($bytes) -replace "`r`n", "`n") }
    }
    return $snap
}

function Compare-Snapshot($Old, $New) {
    # @{ Status; Files }. Status is 'new', 'unchanged', 'version stamp only'
    # (only x.y.z version numbers differ), or 'changed'. Files lists each
    # differing path with 'missing' (in New only), 'extra' (in Old only), or
    # 'out of date'.
    $files = [System.Collections.Generic.List[object]]::new()
    if ($Old.Count -eq 0) { return @{ Status = 'new'; Files = $files } }
    $semver = '(?<![\d.])\d+\.\d+\.\d+(?!\.?\d)'
    $stampOnly = $false
    $changed = $false
    foreach ($k in @(@($Old.Keys) + @($New.Keys) | Sort-Object -Unique)) {
        if (-not $Old.ContainsKey($k)) { $files.Add(@{ Path = $k; Kind = 'missing' }); $changed = $true; continue }
        if (-not $New.ContainsKey($k)) { $files.Add(@{ Path = $k; Kind = 'extra' }); $changed = $true; continue }
        if ($Old[$k] -ceq $New[$k]) { continue }
        $files.Add(@{ Path = $k; Kind = 'out of date' })
        if (($Old[$k] -creplace $semver, 'X.Y.Z') -ceq ($New[$k] -creplace $semver, 'X.Y.Z')) { $stampOnly = $true }
        else { $changed = $true }
    }
    $status = if ($changed) { 'changed' } elseif ($stampOnly) { 'version stamp only' } else { 'unchanged' }
    return @{ Status = $status; Files = $files }
}

function Get-PortStatus {
    <#
    .SYNOPSIS
        How a fresh build of the port compares with its committed dist/,
        without touching dist/. Returns @{ Status; Files } (see Update-Port).
    #>
    param($Palette, [string]$PortDir)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('hyaline-' + [guid]::NewGuid().ToString('N'))
    try {
        $null = Write-PortFiles -Palette $Palette -PortDir $PortDir -OutRoot $tmp
        return Compare-Snapshot (Get-Snapshot (Join-Path $PortDir 'dist')) (Get-Snapshot $tmp)
    }
    finally {
        if (Test-Path $tmp) { Remove-Item -Path $tmp -Recurse -Force }
    }
}

function Update-Port {
    <#
    .SYNOPSIS
        Builds the port into its dist/. Returns @{ Status; Files; Written }.
    .DESCRIPTION
        Status says what changed in dist/: 'new', 'unchanged',
        'version stamp only' (only the palette version moved), or 'changed'.
        Files lists each path that differed. Throws on a bad placeholder.
    #>
    param($Palette, [string]$PortDir)
    $dist = Join-Path $PortDir 'dist'
    $old = Get-Snapshot $dist
    $written = Write-PortFiles -Palette $Palette -PortDir $PortDir -OutRoot $dist
    $result = Compare-Snapshot $old (Get-Snapshot $dist)
    $result['Written'] = $written
    return $result
}

Export-ModuleMember -Function Get-PortStatus, Update-Port
