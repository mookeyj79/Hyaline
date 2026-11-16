---
name: wallpaper
description: Find, check, and add a wallpaper (a found backdrop image) from Wikimedia Commons, marked with the variant it suits. Use when asked to "find a wallpaper", "add a backdrop", "find a dark wallpaper", "find the other half of a pair", or "check this image".
argument-hint: [search words]
---

# Wallpaper

Wallpapers are found images behind Hyaline's glass (ADR 0012). The glass keeps text readable over any backdrop, so a wallpaper is chosen by taste. `build/wallpaper.ps1` applies the hard rules and grades the rest; this skill is the order to run it in.

## The rules

Gates (the script refuses an image that fails one):

- **License** allows redistribution: CC0, public domain, CC BY, or CC BY-SA.
- **Format**: a landscape JPEG at least 1920 px wide.

Grades (they rank results and never refuse):

- **Lightness** suggests a variant: `light` at L* 60 or above, `dark` at 40 or below, `both` in between.
- **Saturation** over 25 is `colorful`, **detail** over 1.5 is `busy`. Otherwise `calm`.

Taste: calm, not busy; color that doesn't fight the role colors; suits the variant it is marked for. No faces, text, or logos.

## 1. Search

```
pwsh build/wallpaper.ps1 -Search "$ARGUMENTS"
pwsh build/wallpaper.ps1 -Search "$ARGUMENTS" -Variant dark
```

Grades up to 50 Commons results from previews (about a minute), calmest first. `-Variant dark|light|both` keeps images suggested for that variant, exact suggestions first, then those suggested for `both`. `-All` shows why candidates failed a gate. Try several words if nothing suits.

To find the other half of a pair, search for the same kind of subject with the other variant, for example `-Search "dunes night" -Variant dark` for White Sands.

## 2. Check from a large copy

```
pwsh build/wallpaper.ps1 -Check "File:<title>.jpg"
```

Previews can be off by a little. `-Check` grades the 1920 px copy, and those grades count. It exits 1 only on a failed gate.

The script paces its requests to Commons and waits out a busy server on its own, even across parallel runs. If Commons asks for a long pause, the script stops and says how long. Wait that long; retrying sooner extends the block.

## 3. Read the Commons page yourself

Open the candidate's Commons page. The script reads the license field, but confirm:

- The license on the page matches, and there is no extra restriction (personality rights, trademarks, a "do not use" note).
- The author is the real author. For "Public domain", the reason it is public domain applies worldwide, not just in one country.

If anything is unclear, stop and ask the user. Do not add it.

## 4. Show the user before adding

List the candidates with their Commons links, grades, and suggested variant, and let the user pick the image and its mark. Taste is theirs, not the script's.

## 5. Add

```
pwsh build/wallpaper.ps1 -Add "File:<title>.jpg" -Name <short-name> -Variant <dark|light|both>
```

`-Variant` is required; the script shows the suggestion beside it. It saves the original byte for byte to `wallpapers/<short-name>.jpg`, writes the 640 px thumbnail, and prints a credit section with the mark.

Paste it into `wallpapers/README.md`:

- Add each image as a single. Make a pair only when the user asks for one.
- A single image gets its own `##` section, after the last one.
- A pair is one `##` section, listed before single images, with both thumbnails and a `###` subsection per image: one `dark`, one `light`.

Rewrite **Subject** as one plain line. Keep the README to what a reader needs: image, mark, credit, license. No measurements or notes.

Then run `pwsh build/check.ps1`. It confirms every wallpaper has a thumbnail, a credit, and a mark, and every pair has one dark and one light image.

## Report back

One or two lines: which image, its license and author, its mark, and the suggested variant if it differs.
