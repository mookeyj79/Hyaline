# The port catalog: which folders under Ports/ are ports, what their port.json
# and Ports/ports.json say, their card icons (ADR 0007), and a site.json for a
# port the Pages site publishes. Loaded and validated once here; check.ps1
# reports the errors, site.ps1 publishes the records, icon.ps1 shares the icon rules.

Set-StrictMode -Version Latest

$Tiers = [ordered]@{ '1' = 'Full glass'; '2' = 'Flat'; '3' = 'Minimal' }
$Platforms = [ordered]@{ windows = 'Windows'; macos = 'macOS'; linux = 'Linux'; web = 'Web' }

# Icons: single-color shapes that take their color from the page.
$IconShapes = @('path', 'circle', 'ellipse', 'line', 'polyline', 'polygon', 'rect', 'g')
$IconShapeAttrs = @('d', 'cx', 'cy', 'r', 'rx', 'ry', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'points', 'width', 'height',
    'transform', 'fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')
$IconPaintAttrs = @('fill', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin', 'fill-rule', 'clip-rule')
$IconMaxBytes = 8KB

function Get-IconRules {
    # What an icon.svg may contain. RootAttrs excludes xmlns and viewBox,
    # which every icon has.
    return @{ Shapes = $IconShapes; ShapeAttrs = $IconShapeAttrs; RootAttrs = $IconPaintAttrs }
}

function Read-Json([string]$Path, [string]$Where, $Errors) {
    try { return Get-Content -Raw -Path $Path | ConvertFrom-Json -AsHashtable }
    catch { $Errors.Add("$Where is not valid JSON: $($_.Exception.Message)"); return $null }
}

function Test-PortMeta($Meta, [string]$Where, [bool]$Planned, $Categories, $Errors) {
    if ($Meta -isnot [System.Collections.IDictionary]) { $Errors.Add("$Where must be a JSON object."); return }
    $known = @('name', 'category', 'tier', 'platforms', 'monogram') + $(if ($Planned) { 'folder' } else { 'icon' })
    foreach ($k in $Meta.Keys) { if ($k -notin $known) { $Errors.Add("$Where has an unknown field '$k'.") } }
    if (-not ($Meta['name'] -is [string] -and $Meta['name'].Trim())) { $Errors.Add("$Where needs a 'name'.") }
    if (-not ($Meta['category'] -is [string] -and $Categories.Contains($Meta['category']))) {
        $Errors.Add("$Where has category '$($Meta['category'])'. Use one of: $(@($Categories.Keys) -join ', ') (from Ports/ports.json).")
    }
    $tier = $Meta['tier']
    $tierOk = ($tier -is [long] -or $tier -is [int]) -and $Tiers.Contains([string]$tier)
    if (-not $tierOk -and -not ($Planned -and $null -eq $tier -and $Meta.Contains('tier'))) {
        $allowed = ($Tiers.Keys -join ', ') + $(if ($Planned) { ', or null' } else { '' })
        $Errors.Add("$Where needs 'tier': $allowed.")
    }
    $plat = $Meta['platforms']
    if (-not ($plat -is [System.Collections.IList] -and $plat.Count -gt 0)) {
        $Errors.Add("$Where needs 'platforms', a list of: $($Platforms.Keys -join ', ').")
    }
    else {
        foreach ($p in $plat) { if (-not $Platforms.Contains([string]$p)) { $Errors.Add("$Where has platform '$p'. Use: $($Platforms.Keys -join ', ').") } }
    }
    if ($Meta.Contains('monogram') -and -not ($Meta['monogram'] -is [string] -and $Meta['monogram'] -match '^\S{1,3}$')) {
        $Errors.Add("$Where has a 'monogram' that is not 1 to 3 characters.")
    }
}

function Test-PortIcon([string]$Dir, $Meta, [string]$Name, $Errors) {
    # Returns $true when the port has a valid icon.svg and credit.
    $svgPath = Join-Path $Dir 'icon.svg'
    $hasSvg = Test-Path $svgPath
    $hasCredit = $Meta -is [System.Collections.IDictionary] -and $Meta.Contains('icon')
    if (-not $hasSvg -and -not $hasCredit) { return $false }
    if (-not $hasCredit) { $Errors.Add("Icon: Ports/$Name/icon.svg has no 'icon' credit in port.json. build/icon.ps1 prints it."); return $false }
    if (-not $hasSvg) { $Errors.Add("Icon: Ports/$Name/port.json has an 'icon' credit but there is no icon.svg."); return $false }
    $before = $Errors.Count

    $c = $Meta['icon']
    $where = "Ports/$Name/port.json icon"
    if ($c -isnot [System.Collections.IDictionary]) { $Errors.Add("Icon: $where must be an object."); return $false }
    foreach ($k in $c.Keys) { if ($k -notin 'kind', 'set', 'name', 'author', 'source', 'license', 'mark') { $Errors.Add("Icon: $where has an unknown field '$k'.") } }
    foreach ($k in 'set', 'name', 'author', 'license') {
        if (-not ($c[$k] -is [string] -and $c[$k].Trim())) { $Errors.Add("Icon: $where needs '$k'.") }
    }
    if (-not ($c['source'] -is [string] -and $c['source'] -match '^https://\S+$')) { $Errors.Add("Icon: $where needs 'source', an https URL.") }
    if ($c['kind'] -eq 'brand') {
        if (-not ($c['mark'] -is [string] -and $c['mark'] -match '^https://\S+$')) {
            $Errors.Add("Icon: $where is a brand mark, so it needs 'mark': an https URL showing the app allows its mark to be used.")
        }
    }
    elseif ($c['kind'] -eq 'glyph') { if ($c.Contains('mark')) { $Errors.Add("Icon: $where is a glyph, so it takes no 'mark'.") } }
    else { $Errors.Add("Icon: $where needs 'kind': brand or glyph.") }

    $rel = "Ports/$Name/icon.svg"
    if ((Get-Item $svgPath).Length -gt $IconMaxBytes) { $Errors.Add("Icon: $rel is over $($IconMaxBytes / 1KB) KB. Icons are simple shapes."); return $false }
    $xml = [System.Xml.XmlDocument]::new()
    $xml.XmlResolver = $null
    try { $xml.LoadXml([System.IO.File]::ReadAllText($svgPath)) }
    catch { $Errors.Add("Icon: $rel is not valid XML: $($_.Exception.Message)"); return $false }
    if ($xml.DocumentType) { $Errors.Add("Icon: $rel has a DOCTYPE. Remove it.") }
    $root = $xml.DocumentElement
    if ($root.LocalName -ne 'svg' -or $root.NamespaceURI -ne 'http://www.w3.org/2000/svg') { $Errors.Add("Icon: $rel is not an SVG."); return $false }
    if ($root.GetAttribute('viewBox') -ne '0 0 24 24') { $Errors.Add("Icon: $rel needs viewBox=`"0 0 24 24`", so every card icon is the same size.") }
    $check = {
        param([System.Xml.XmlElement]$El, [string[]]$Allowed)
        foreach ($a in $El.Attributes) {
            if ($a.Prefix -eq 'xmlns' -or ($a.LocalName -notin $Allowed)) {
                $Errors.Add("Icon: $rel has the attribute '$($a.Name)' on <$($El.LocalName)>, which icons may not use.")
                continue
            }
            if ($a.LocalName -in 'fill', 'stroke' -and $a.Value -notin 'currentColor', 'none') {
                $Errors.Add("Icon: $rel has $($a.LocalName)=`"$($a.Value)`". Icons use currentColor or none only, so the page colors them.")
            }
        }
    }
    & $check $root (@('xmlns', 'viewBox') + $IconPaintAttrs)
    foreach ($node in $root.SelectNodes('.//node()')) {
        if ($node.NodeType -in 'Comment', 'Whitespace', 'SignificantWhitespace') { continue }
        if ($node.NodeType -ne 'Element') { $Errors.Add("Icon: $rel has $($node.NodeType) content. Icons are shapes only."); continue }
        if ($node.LocalName -notin $IconShapes -or $node.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
            $Errors.Add("Icon: $rel has <$($node.LocalName)>. Icons may use only: $($IconShapes -join ', ').")
            continue
        }
        & $check $node $IconShapeAttrs
    }
    return $Errors.Count -eq $before
}

function Read-SiteSpec([string]$Dir, [string]$Name, $Errors) {
    # site.json: what the Pages site publishes from this port.
    #   copy:    folders of the port to publish, at their repo paths
    #   entries: site paths that open a page of dist/<variant>/ in the
    #            visitor's variant: [{ "path": "ports/index.html", "page": "ports.html", "title": "Ports" }]
    #   guide:   optional page of template/, in a folder of its own, that site.ps1 fills
    #            with each listed port's README.md: "guides/guide.html"
    $path = Join-Path $Dir 'site.json'
    if (-not (Test-Path $path)) { return $null }
    $where = "Ports/$Name/site.json"
    $spec = Read-Json $path $where $Errors
    if ($spec -isnot [System.Collections.IDictionary]) { if ($spec) { $Errors.Add("$where must be an object.") }; return $null }
    $before = $Errors.Count
    if (-not ($spec['copy'] -is [System.Collections.IList] -and $spec['copy'].Count -gt 0)) { $Errors.Add("$where needs 'copy', a list of the port's folders to publish.") }
    else {
        foreach ($c in $spec['copy']) { if (-not ($c -is [string] -and $c -notmatch '[\\/]|^\.' -and (Test-Path (Join-Path $Dir $c) -PathType Container))) { $Errors.Add("$where copies '$c', which is not a folder in Ports/$Name.") } }
    }
    if (-not ($spec['entries'] -is [System.Collections.IList] -and $spec['entries'].Count -gt 0)) { $Errors.Add("$where needs 'entries', a list of { path, page, title }.") }
    else {
        foreach ($e in $spec['entries']) {
            if (-not ($e -is [System.Collections.IDictionary] -and $e['path'] -is [string] -and $e['path'] -match '^([a-z0-9-]+/)*index\.html$' -and $e['page'] -is [string] -and $e['title'] -is [string])) {
                $Errors.Add("$where has an entry that is not { path: '<folder>/index.html', page, title }.")
                continue
            }
            if (-not (Test-Path (Join-Path $Dir 'template' $e['page']))) { $Errors.Add("$where entry '$($e['path'])' opens '$($e['page'])', which is not in template/.") }
        }
    }
    if ($spec.Contains('guide')) {
        $g = $spec['guide']
        if (-not ($g -is [string] -and $g -match '^[a-z0-9-]+/[a-z0-9-]+\.html$')) { $Errors.Add("$where has a 'guide' that is not '<folder>/<page>.html'.") }
        elseif (-not (Test-Path (Join-Path $Dir 'template' $g))) { $Errors.Add("$where has guide '$g', which is not in template/.") }
    }
    if ($Errors.Count -ne $before) { return $null }
    return $spec
}

function Get-PortCatalog {
    <#
    .SYNOPSIS
        Every folder under Ports/, validated. Returns
        @{ Ports; Categories; Planned; StructureErrors; Errors }.
    .DESCRIPTION
        Each port is @{ Name; Dir; Listed; HasTemplate; HasReadme; Meta;
        Variants; Icon; Site }. Listed is $false for folders in 'unlisted'
        (not app ports, like the preview page). Meta is port.json, Variants
        the dist/ variant folders present, Icon the validated credit or $null,
        Site the validated site.json or $null.
        StructureErrors covers README.md, template/, and site.json; Errors
        covers port.json, ports.json, and icons.
    #>
    param([Parameter(Mandatory)][string]$PortsRoot, [string[]]$VariantKeys = @('dark', 'light'))
    $errors = [System.Collections.Generic.List[string]]::new()
    $structure = [System.Collections.Generic.List[string]]::new()
    $catalog = @{ Ports = [System.Collections.Generic.List[object]]::new(); Categories = [ordered]@{}; Planned = @(); StructureErrors = $structure; Errors = $errors }
    $dirs = if (Test-Path $PortsRoot) { @(Get-ChildItem -Path $PortsRoot -Directory | Sort-Object Name) } else { @() }

    $index = $null
    $indexPath = Join-Path $PortsRoot 'ports.json'
    if (-not (Test-Path $indexPath)) { $errors.Add('Ports/ports.json does not exist.') }
    else { $index = Read-Json $indexPath 'Ports/ports.json' $errors }
    if ($index -is [System.Collections.IDictionary]) {
        if ($index['categories'] -is [System.Collections.IDictionary] -and $index['categories'].Count -gt 0) { $catalog.Categories = $index['categories'] }
        else { $errors.Add("Ports/ports.json needs 'categories', an object of id to display name.") }
        if ($index['planned'] -isnot [System.Collections.IList]) { $errors.Add("Ports/ports.json needs 'planned', a list (it can be empty).") }
    }
    $unlisted = @()
    if ($index -is [System.Collections.IDictionary] -and $index.Contains('unlisted')) {
        if ($index['unlisted'] -is [System.Collections.IList]) { $unlisted = @($index['unlisted']) }
        else { $errors.Add("'unlisted' in Ports/ports.json must be a list of folder names.") }
    }
    foreach ($u in $unlisted) { if (-not ($dirs | Where-Object Name -eq $u)) { $errors.Add("unlisted folder Ports/$u does not exist.") } }

    foreach ($dir in $dirs) {
        $name = $dir.Name
        $port = @{
            Name = $name; Dir = $dir.FullName; Listed = ($name -notin $unlisted)
            HasTemplate = Test-Path (Join-Path $dir.FullName 'template')
            HasReadme = Test-Path (Join-Path $dir.FullName 'README.md')
            Meta = $null; Icon = $null; Site = $null
            Variants = @(foreach ($v in $VariantKeys) { if (Test-Path (Join-Path $dir.FullName 'dist' $v)) { $v } })
        }
        if (-not $port.HasReadme) { $structure.Add("Ports/$name has no README.md.") }
        if (-not $port.HasTemplate) { $structure.Add("Ports/$name has no template/ folder.") }
        $port.Site = Read-SiteSpec $dir.FullName $name $structure
        if ($port.Listed) {
            $where = "Ports/$name/port.json"
            $metaPath = Join-Path $dir.FullName 'port.json'
            if (-not (Test-Path $metaPath)) { $errors.Add("$where does not exist.") }
            else {
                $meta = Read-Json $metaPath $where $errors
                if ($null -ne $meta) {
                    $port.Meta = $meta
                    Test-PortMeta $meta $where $false $catalog.Categories $errors
                    if (Test-PortIcon $dir.FullName $meta $name $errors) { $port.Icon = $meta['icon'] }
                }
            }
        }
        $catalog.Ports.Add($port)
    }

    if ($index -is [System.Collections.IDictionary] -and $index['planned'] -is [System.Collections.IList]) {
        $catalog.Planned = @($index['planned'])
        $seen = @{}
        $i = 0
        foreach ($p in $index['planned']) {
            $where = "Ports/ports.json planned[$i]"
            $i++
            Test-PortMeta $p $where $true $catalog.Categories $errors
            if ($p -isnot [System.Collections.IDictionary]) { continue }
            $folder = $p['folder']
            if (-not ($folder -is [string] -and $folder -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$')) {
                $errors.Add("$where needs 'folder', the future Ports/ folder name (lowercase, hyphenated).")
                continue
            }
            if ($seen.ContainsKey($folder)) { $errors.Add("'$folder' is planned twice.") }
            $seen[$folder] = $true
            if ($dirs | Where-Object Name -eq $folder) { $errors.Add("Ports/$folder exists, so remove it from 'planned' in Ports/ports.json.") }
        }
    }
    return $catalog
}

function ConvertTo-PortsData {
    # The data the ports page reads (window.THEME_PORTS), from a valid catalog.
    param($Catalog)
    $card = {
        param($m, [string]$Folder)
        [ordered]@{
            folder    = $Folder
            name      = $m['name']
            category  = $m['category']
            tier      = $m['tier']
            platforms = @($m['platforms'])
            monogram  = if ($m.Contains('monogram')) { $m['monogram'] } else { $null }
        }
    }
    $ports = @(foreach ($p in $Catalog.Ports) {
        if (-not $p.Listed) { continue }
        $c = & $card $p.Meta $p.Name
        $c['icon'] = if ($p.Icon) {
            [ordered]@{ path = "Ports/$($p.Name)/icon.svg"; kind = $p.Icon['kind']; set = $p.Icon['set']
                        author = $p.Icon['author']; license = $p.Icon['license']; source = $p.Icon['source'] }
        } else { $null }
        $c['variants'] = @($p.Variants)
        $c
    })
    return [ordered]@{
        categories = $Catalog.Categories
        tiers      = $Tiers
        platforms  = $Platforms
        ports      = $ports
        planned    = @(foreach ($p in $Catalog.Planned) { & $card $p $p['folder'] })
    }
}

Export-ModuleMember -Function Get-PortCatalog, ConvertTo-PortsData, Get-IconRules
