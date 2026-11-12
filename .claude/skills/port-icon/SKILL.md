---
name: port-icon
description: Find and add the card icon for a port on the ports page. Use when asked to "add an icon for X", "find an icon for the X port", "replace the monogram", or as the last step of a new port.
argument-hint: [app_name]
---

# Port icon

Give the port in `Ports/$ARGUMENTS/` an icon for its card on the ports page.

Read [ADR 0007](../../../docs/adr/0007-port-icons-are-single-color.md) first. In short: an icon is a single-color SVG that takes its color from the page, so it follows the palette rule. Full-color logos are never used. Without an icon, the card shows the monogram, and that is fine.

## 1. Search both sets

```
pwsh build/icon.ps1 -Search "<app name>"
```

Try the app's name, then its short name or old name. The script lists:

- **Brand marks** from Simple Icons, with each one's icon license and brand guidelines when Simple Icons has them.
- **Glyphs** from Lucide.

## 2. Use the brand mark if it is allowed

Use a brand mark only when all of these hold:

- Simple Icons has the app itself, not its parent company or a related product.
- The icon license allows redistribution (`CC0-1.0` and most others the script prints do).
- **The app allows its mark to be shown.** Look for this yourself, in the app's license (if its repo includes the logo, an open license such as ISC or MIT covers it), brand guidelines, or press kit. Note the URL. If the owner restricts its marks (Microsoft, for example), or you cannot find anything, do not use the brand mark. Use a glyph.

```
pwsh build/icon.ps1 -Port <app_name> -Brand <slug> -Mark <url>
```

## 3. Otherwise, pick a glyph

Search for what the app **is**, not its name: `terminal`, `code`, `pen`, `browser`, `music`, `folder`.

```
pwsh build/icon.ps1 -Search terminal
```

Pick the glyph someone would connect with that kind of app at a glance. Avoid a glyph another port already uses (check `"name"` in the other `Ports/*/port.json`), so cards stay distinct. Then:

```
pwsh build/icon.ps1 -Port <app_name> -Glyph <name>
```

If nothing fits, stop. Keep the monogram and tell the user. Do not draw an icon by hand, and do not take one from anywhere else without asking.

## 4. Record the credit

The script prints an `"icon": { ... }` object. Paste it into `Ports/<app_name>/port.json` as the last field, unchanged. It records the kind, set and version, author, source URL, license, and, for brand marks, the `mark` URL.

## 5. Check and look at it

```
pwsh build/check.ps1
pwsh build/site.ps1
python3 -m http.server -d _site 8765    # open http://127.0.0.1:8765/ports/
```

Look at the card in both Dark and Light. The icon should read as the app at card size (about 24 px). If it turns into a blob, pick another one.

## Report back

In one or two lines: which icon, brand mark or glyph, and why (for a glyph, why no brand mark was used).
