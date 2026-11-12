# One wash alpha for see-through highlights

Some apps draw a highlight under text they cannot recolor. VS Code is the first: its editor selection, diff lines, and find matches sit under the code, and the selected text keeps its syntax colors. A solid `accent` or `green` there hides the code. The palette had no see-through version of any color role.

So each variant gets one `wash` alpha, and the `{{role|wash}}` filter writes any color role at that alpha. A selection is the `accent` wash, an added line the `green` wash, and so on. One number per variant covers every role and every future port, instead of a new role for each kind of highlight.

| Variant | Wash |
|---|---|
| Hyaline Dark | 0.15 |
| Hyaline Light | 0.20 |

The role colors already sit at about 4.5:1 on `panel_flat` (Dark `red`, Light `green`), so no wash keeps them at the text floor. The contrast floor gains a rule for washes instead: on any color role's wash over `panel_flat`, `text` and `text_dim` keep 4.5:1, and `text_muted` and the color roles keep 3:1. The values above are the strongest that pass, rounded down. Light's wash is stronger because frost needs more color to show.

## Consequences

- Palette 0.3.0, a minor change: a new value, no role changed meaning.
- `check.ps1` measures every text and color role on every color role's wash.
- The rule covers one wash layer. Where an app stacks two (a selection over an added line), the result is darker than the floor assumes. Ports avoid stacking where the app allows it.
- Washes are for highlights under text. Solid fills with `on_accent` text stay the way to mark selected items in lists and menus.
