---
name: wallpaper
description: Find, check, and add a wallpaper (a found backdrop image) from Wikimedia Commons. Use when asked to "find a wallpaper", "add a backdrop", "check this image", or to recheck the wallpapers after a palette change.
argument-hint: [search words]
---

# Wallpaper

Wallpapers are found images behind Hyaline's glass (ADR 0003). They are the one exception to the palette rule, so every one must earn its place. `build/wallpaper.ps1` applies the rules; this skill is the order to run it in.

## The rules

A wallpaper passes only if all of these hold. The script checks each one.

- **License** allows redistribution: CC0, public domain, CC BY, or CC BY-SA.
- **Fit**: a landscape JPEG at least 1920 px wide, light, low in saturation, low in detail.
- **Readable**: scaled to 1920 px and blurred 18 px, every role passes on `panel` and primary text passes on `chrome` and on a tab, in both variants.

Hyaline Light's panel is the tight one. Most photos fail it. Bright, even scenes do best: snow, sand, mist over water, pale sky.

## 1. Search

```
pwsh build/wallpaper.ps1 -Search "$ARGUMENTS"
```

Grades up to 50 Commons results from previews (about a minute). Try several words if nothing passes. `-All` shows why each one failed. Pick candidates that pass and suit "smoke by night, frost by day": calm, airy, no faces, no text, no logos.

## 2. Check at full size

```
pwsh build/wallpaper.ps1 -Check "File:<title>.jpg"
```

Previews can be off by a little. Only the full-size check counts. It exits 1 on any failure.

## 3. Read the Commons page yourself

Open the candidate's Commons page. The script reads the license field, but confirm:

- The license on the page matches, and there is no extra restriction (personality rights, trademarks, a "do not use" note).
- The author is the real author. For "Public domain", the reason it is public domain applies worldwide, not just in one country.

If anything is unclear, stop and ask the user. Do not add it.

## 4. Show the user before adding

List the passing candidates with their Commons links and let the user pick. Taste is theirs, not the script's.

## 5. Add

```
pwsh build/wallpaper.ps1 -Add "File:<title>.jpg" -Name <short-name>
```

Saves the original byte for byte to `wallpapers/<short-name>.jpg`, writes the 640 px thumbnail, and prints a credit section. Paste it into `wallpapers/README.md` after the last wallpaper. Rewrite **Subject** as one plain line. Keep the README to what a reader needs: image, credit, license. No measurements or notes.

Then run `pwsh build/check.ps1`. It confirms every wallpaper has a thumbnail and a credit.

## After a palette change

Recheck every wallpaper, since the result depends on the palette:

```
pwsh build/wallpaper.ps1 -Check wallpapers/<name>.jpg
```

If one fails, tell the user. The palette or the wallpaper has to give way; that is their call.

## Report back

One or two lines: which image, its license and author, and its tightest contrast.
