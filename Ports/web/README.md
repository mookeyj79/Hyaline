# Hyaline for the web

**Tier:** 1 Full glass
**Variants:** Hyaline Dark, Hyaline Light
**Tested with:** Hugo 0.131 on Linux

This port is two CSS files of custom properties, one per variant, for a website you build. It does not style a page by itself. Your own CSS reads the properties with `var()`.

Every property name starts with the variant, such as `--hyaline-dark-panel` and `--hyaline-light-panel`. That way you can load both files at once and switch between them on your site.

## Before you start

- A website whose CSS you can edit.
- For the Hugo module route: Hugo 0.56 or later, with [Go](https://go.dev/dl/) and Git installed. Hugo needs both to fetch modules.
- For a Hugo site, the site must already be a module. If there is no `go.mod` next to your `hugo.toml`, run `hugo mod init <your-site-name>` in the site folder first.

## Install

### Hugo, as a module

1. Open your site's `hugo.toml`.
2. Add the import, mounting the port's files under `assets/hyaline`:

   ```toml
   [module]
     [[module.imports]]
       path = 'github.com/mookeyj79/Hyaline'
       [[module.imports.mounts]]
         source = 'Ports/web/dist'
         target = 'assets/hyaline'
   ```

3. Pick the Hyaline version to pin. Open the [commit list](https://github.com/mookeyj79/Hyaline/commits/main) and copy the short hash of the commit you want, or use a release tag if there is one.
4. In the site folder, run `hugo mod get github.com/mookeyj79/Hyaline@<hash or tag>`. Hugo writes that exact version into your `go.mod`, and it stays there until you change it.
5. In the template that writes your page's `<head>`, load both files as one stylesheet:

   ```go-html-template
   {{ $dark := resources.Get "hyaline/dark/theme.css" }}
   {{ $light := resources.Get "hyaline/light/theme.css" }}
   {{ $css := slice $dark $light | resources.Concat "css/hyaline.css" | minify | fingerprint }}
   <link rel="stylesheet" href="{{ $css.RelPermalink }}">
   ```

6. In your own CSS, use the properties. See [Use the properties](#use-the-properties).
7. Run `hugo server`. The site builds without errors, and your page's `<head>` links a `hyaline` stylesheet.

To move to a newer Hyaline later, run step 4 again with the new hash or tag. On Hugo 0.150 or later you can also put `version = '<tag or hash>'` under the import in `hugo.toml` instead. Hugo then ignores `hugo mod get` for it, so edit that line to update.

### Any other site

1. Download or clone this repo.
2. Copy `Ports/web/dist/dark/theme.css` and `Ports/web/dist/light/theme.css` into your site. Rename them if two files called `theme.css` would clash, such as `hyaline-dark.css` and `hyaline-light.css`.
3. Link both from your page's `<head>`, before your own stylesheet:

   ```html
   <link rel="stylesheet" href="/css/hyaline-dark.css">
   <link rel="stylesheet" href="/css/hyaline-light.css">
   ```

4. Use the properties in your own CSS.

Files to use:

- Hyaline Dark: `dist/dark/theme.css`
- Hyaline Light: `dist/light/theme.css`

## Use the properties

Each file sets these on `:root`. Swap `dark` for `light` in the names for the other variant.

| Property | What it is for |
|---|---|
| `--hyaline-dark-backdrop` | The page background behind the glass |
| `--hyaline-dark-chrome` | Header, footer, navigation bars. Holds plain text and solid accent buttons only |
| `--hyaline-dark-panel` | The main content area |
| `--hyaline-dark-raised` | Cards, code blocks, inputs, and tags on top of a panel |
| `--hyaline-dark-line` | Borders and dividers |
| `--hyaline-dark-text`, `-text-dim`, `-text-muted` | Body text, supporting text, captions and dates |
| `--hyaline-dark-accent`, `-on-accent` | Links, focus rings, primary buttons, and the text on them |
| `--hyaline-dark-red`, `-green`, `-yellow`, `-blue`, `-magenta`, `-cyan`, `-orange` | Errors, success, warnings, info, and syntax colors |
| `--hyaline-dark-<color>-wash` | A see-through tint of a color, for selections and highlighted lines |

Chrome, panel, and raised also come in three more forms:

- `-flat`: a solid color, for places where see-through looks wrong, such as a printed page.
- `-rgb` and `-alpha`: the color's channels and its see-through amount, so you can change the amount, as in `rgba(var(--hyaline-dark-panel-rgb), 0.6)`. The channels are comma-separated, so use the comma form of `rgba()`, not the slash form.

A site that defaults to Dark and has a Light switch can map the properties once:

```css
:root {
  color-scheme: dark;
  --bg: var(--hyaline-dark-backdrop);
  --surface: var(--hyaline-dark-panel);
  --ink: var(--hyaline-dark-text);
  --link: var(--hyaline-dark-accent);
}
:root[data-theme="light"] {
  color-scheme: light;
  --bg: var(--hyaline-light-backdrop);
  --surface: var(--hyaline-light-panel);
  --ink: var(--hyaline-light-text);
  --link: var(--hyaline-light-accent);
}
body { background: var(--bg); color: var(--ink); }
main { background: var(--surface); }
a { color: var(--link); }
```

To follow the visitor's OS setting instead, put the Light block inside `@media (prefers-color-scheme: light)`.

## Set the font

Hyaline uses [FiraCode Nerd Font](https://www.nerdfonts.com/font-downloads). On a website you cannot rely on visitors having it, so it is not in these files.

1. If you want it on your site, serve the font files yourself with `@font-face`. Check the font's license (SIL Open Font License) first.
2. Set `font-family: "FiraCode Nerd Font Mono", monospace;` on `code` and `pre`.

## Check that it worked

Open your browser's developer tools, select `<html>`, and look at the computed styles. You see the `--hyaline-dark-...` and `--hyaline-light-...` properties with values.

## Switch between Dark and Light

Both variants are loaded at once, so switching is your site's choice:

1. Point your own properties at the `dark` or `light` set, as in the example above.
2. Change which set is active with an attribute or class on `<html>`, or with `prefers-color-scheme`.

## Turn on the glass effect

`chrome`, `panel`, and `raised` are already see-through. To blur what is behind them:

1. Add `backdrop-filter: blur(18px);` to the element that uses the glass.
2. Put a backdrop image or color on `body` so there is something to see through.
3. Keep body text on `panel`, not on `chrome`. Chrome is clear enough that small or colored text gets hard to read.

## Uninstall

1. Remove the `<link>` or the `resources.Get` lines from your `<head>`.
2. On Hugo, delete the `[[module.imports]]` block for Hyaline from `hugo.toml`, then run `hugo mod tidy`.
3. Replace any `var(--hyaline-...)` in your CSS with your own values.

## Troubleshooting

- **`resources.Get` returns nil**: the mount is missing or misspelled. Check that `source` is `Ports/web/dist` and that the path in `resources.Get` starts with your mount's `target` minus `assets/`.
- **`hugo mod get` fails with "go: command not found"**: install Go and open a new terminal.
- **A property has no value**: the name is misspelled, or the file for that variant is not loaded.

## Known limits

- The files only define properties. Your site decides which elements use them.
- There is no ready-made light and dark switch. You write the few lines that pick a set.
- Blur needs `backdrop-filter`, which some older browsers do not support. Without it the glass still shows, just not blurred.

## Sources

- [Hugo: Use Hugo Modules](https://gohugo.io/hugo-modules/use-modules/)
- [Hugo: Module configuration](https://gohugo.io/configuration/module/)
- [MDN: Using CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [MDN: backdrop-filter](https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter)
