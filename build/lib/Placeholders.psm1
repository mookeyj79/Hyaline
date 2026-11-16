# Template placeholders: the one definition of the {{...}} grammar, how each
# placeholder resolves for a variant, and how template files are read.
# The build expands templates with it; the checks ask it what is wrong.
# The table in CONTRIBUTING.md ("Add a port", step 4) documents it.

Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Palette.psm1')

$Pattern = '\{\{\s*([A-Za-z_][A-Za-z0-9_.]*)\s*(?:\|\s*([A-Za-z0-9]+)\s*)?\}\}'

function Resolve-Placeholder {
    <#
    .SYNOPSIS
        Resolves one placeholder for a variant. Returns @{ Value } or @{ Error }.
    .PARAMETER PortValues
        The port's values.json: @{ dark = @{ key = value }; light = @{ ... } }, or $null.
    #>
    param([string]$Name, [string]$Filter, $Palette, $Variant, $PortValues)
    $token = '{{' + $Name + $(if ($Filter) { "|$Filter" }) + '}}'
    $value = $null
    $role = $null
    switch -Regex ($Name) {
        '^meta\.(.+)$' {
            if ($Palette.Meta.Contains($Matches[1])) { $value = [string]$Palette.Meta[$Matches[1]] }
            break
        }
        '^variant\.(.+)$' {
            switch ($Matches[1]) { 'key' { $value = $Variant.Key } 'name' { $value = $Variant.Name } 'mode' { $value = $Variant.Mode } }
            break
        }
        '^port\.(.+)$' {
            $set = if ($PortValues -is [System.Collections.IDictionary]) { $PortValues[$Variant.Key] } else { $null }
            if ($set -is [System.Collections.IDictionary] -and $set.Contains($Matches[1])) { $value = [string]$set[$Matches[1]] }
            break
        }
        '^ansi\.(.+)$' {
            $role = Get-AnsiRole -Slot $Matches[1] -Variant $Variant
            if (-not $role) { return @{ Error = "Unknown ANSI slot in $token." } }
            break
        }
        default {
            if ($Variant.Roles.ContainsKey($Name)) { $role = $Name }
        }
    }
    if ($role) {
        try { return @{ Value = (Format-RoleColor -Variant $Variant -Role $role -Filter $Filter) } }
        catch { return @{ Error = "$token`: $($_.Exception.Message)." } }
    }
    if ($null -eq $value) { return @{ Error = "Unknown placeholder $token." } }
    if ($Filter) { return @{ Error = "Filters only apply to color roles: $token." } }
    return @{ Value = $value }
}

function Expand-Template {
    # Replaces every placeholder in $Text for one variant. Throws on the first
    # one that does not resolve, naming $Source.
    param([string]$Text, $Palette, $Variant, $PortValues, [string]$Source)
    return $Text -creplace $Pattern, {
        $r = Resolve-Placeholder -Name $_.Groups[1].Value -Filter $_.Groups[2].Value `
            -Palette $Palette -Variant $Variant -PortValues $PortValues
        if ($r.Contains('Error')) { throw "$($r.Error) In $Source." }
        $r.Value
    }
}

function Find-PlaceholderError {
    # Every placeholder in $Text that does not resolve in some variant, as
    # messages. Empty when the text is fine.
    param([string]$Text, $Palette, $PortValues)
    $seen = [ordered]@{}
    foreach ($m in [regex]::Matches($Text, $Pattern)) {
        foreach ($variant in $Palette.Variants.Values) {
            $r = Resolve-Placeholder -Name $m.Groups[1].Value -Filter $m.Groups[2].Value `
                -Palette $Palette -Variant $variant -PortValues $PortValues
            if ($r.Contains('Error')) {
                $msg = $r.Error
                if ($m.Groups[1].Value -match '^port\.') { $msg = "$msg (missing from values.json for $($variant.Key))" }
                $seen[$msg] = $true
            }
        }
    }
    return @($seen.Keys)
}

function Get-PlaceholderRole {
    # The palette roles $Text draws, in either variant: {{role}} with any
    # filter, and {{ansi.<slot>}} as the role the slot maps to.
    param([string]$Text, $Palette)
    $roles = [System.Collections.Generic.SortedSet[string]]::new()
    foreach ($m in [regex]::Matches($Text, $Pattern)) {
        $name = $m.Groups[1].Value
        foreach ($variant in $Palette.Variants.Values) {
            $role = if ($name -match '^ansi\.(.+)$') { Get-AnsiRole -Slot $Matches[1] -Variant $variant }
                    elseif ($variant.Roles.ContainsKey($name)) { $name }
            if ($role) { [void]$roles.Add($role) }
        }
    }
    return @($roles)
}

function Find-Placeholder {
    # The first {{placeholder}} in $Text, or $null. For checking generated output.
    param([string]$Text)
    $m = [regex]::Match($Text, $Pattern)
    if ($m.Success) { return $m.Value }
    return $null
}

function Read-TemplateFile {
    <#
    .SYNOPSIS
        Reads a template. Returns @{ Binary = $true; Bytes } for a binary file,
        otherwise @{ Binary = $false; Encoding; Text }, keeping a BOM or UTF-16.
    #>
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $enc = $null
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $enc = [System.Text.UTF8Encoding]::new($true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $enc = [System.Text.UnicodeEncoding]::new($false, $true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $enc = [System.Text.UnicodeEncoding]::new($true, $true)
    }
    elseif ([Array]::IndexOf($bytes, [byte]0) -ge 0) {
        return @{ Binary = $true; Bytes = $bytes }
    }
    else {
        $enc = [System.Text.UTF8Encoding]::new($false)
    }
    $skip = $enc.GetPreamble().Length
    return @{ Binary = $false; Encoding = $enc; Text = $enc.GetString($bytes, $skip, $bytes.Length - $skip) }
}

Export-ModuleMember -Function Resolve-Placeholder, Expand-Template, Find-PlaceholderError, Get-PlaceholderRole, Find-Placeholder, Read-TemplateFile
