# Web: role mapping

For maintainers. The install guide is [README.md](README.md).

## Role mapping

The port has no app slots. It exposes every role as a CSS custom property, so the mapping is one to one: role `text_dim` becomes `--<variant>-text-dim`, where `<variant>` is `{{variant.name|slug}}` (`hyaline-dark`, `hyaline-light`).

| Property suffix | Role | Why |
|---|---|---|
| `-backdrop` | `backdrop` | |
| `-chrome`, `-panel`, `-raised` | `chrome`, `panel`, `raised` with `rgba` | The translucent value, at the palette's alpha |
| `-chrome-rgb`, `-panel-rgb`, `-raised-rgb` | same, `rgb` | Channels for sites that need another alpha |
| `-chrome-alpha`, `-panel-alpha`, `-raised-alpha` | same, `alpha` | The palette's alpha on its own |
| `-chrome-flat`, `-panel-flat`, `-raised-flat` | `*_flat` | Solid fallbacks |
| `-line`, `-text`, `-text-dim`, `-text-muted` | same | |
| `-accent`, `-on-accent` | same | |
| `-red` to `-orange` | the seven color roles | |
| `-accent-wash`, `-<color>-wash` | wash roles, `wash` | The variant's wash alpha, for selections and diff lines (ADR 0006) |

## Gaps and trade-offs

- Property names carry the variant so both files can load together. The first user, mikewashere.com, defaults to Dark and toggles to Light without swapping stylesheets. Plain names on `:root` would make the second file overwrite the first.
- The `slug` filter was added to `build/lib/Placeholders.psm1` for this port, so the prefix comes from the palette's variant name and is never hardcoded.
- The file is `theme.css` in each variant folder. A filtered placeholder cannot go in a file name, because `|` is not allowed in Windows file names.
- `-rgb` is comma-separated (the `rgb` filter's output), which works in `rgba(var(--x-rgb), a)` but not in the space and slash syntax. Catppuccin's `-rgb` is space-separated. Changing the filter would change other ports' output, so the README names the comma form instead.
- No `color-scheme` in the files: with both loaded, the site sets it alongside its own switch.
- Tier 1 because every surface ships at its alpha. Blur is the site's `backdrop-filter`. The contrast floor over a wallpaper assumes 18 px blur and the palette alpha (ADR 0004); a site that lowers alpha through `-rgb` leaves that floor.
- The repo has no `go.mod`. Hugo and Go fetch it as a module anyway, pinned in the site's `go.mod` as a pseudo-version. Checked with `hugo mod get github.com/mookeyj79/Hyaline@279e2ec` (Hugo 0.131, Go 1.24), a commit from before this port, so it proves the fetch and pin but not the mount; the mount was checked separately through `module.replacements`. Redo the fetch against a commit that has `Ports/web/dist` once this is on `main`.
- There are no release tags yet, so the README pins by commit hash or tag. A `v<meta.version>` tag per palette release would let sites pin to a Hyaline version.

## Research

- Catppuccin's palette CSS (https://github.com/catppuccin/palette/blob/main/docs/css.md) names properties `--ctp-<flavor>-<color>` with `-rgb` and `-hsl` channel variants, and loads every flavor at once. This port takes the same method: one prefix per variant, plus channels.
- Hugo: setting mounts on an import replaces that module's default mounts, which is what we want, since only `Ports/web/dist` should be visible to the site. The `version` key on an import needs Hugo 0.150 or later; `hugo mod get <path>@<ref>` works on every Hugo with modules.
- Tested a scratch Hugo site with `module.replacements` pointing at this checkout: both files mount under `assets/hyaline`, `resources.Concat` joins them, and every property resolves.
