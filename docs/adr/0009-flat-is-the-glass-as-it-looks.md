# Flat is the glass as it looks

Flat values used to be worked out: the tint laid over a neutral backdrop at the panel's alpha, with Light's `panel_flat` pinned to the frost as the one exception (ADR 0004). Now every flat value is chosen, and what is chosen is the glass as it looks over a wallpaper, laid down solid. Real glass is always the goal; flat is that glass with the window closed.

| | Dark | Light |
|---|---|---|
| `chrome_flat` | `#575b63` | `#e3e8ee` |
| `panel_flat` | `#434850` | `#fafbfc` |
| `raised_flat` | `#565a62` | `#ffffff` |
| `line` | `#6c7076` | `#c4ccd7` |
| `edge` | `#6d7077` | `#ffffff` |

Without glass, a theme reads as a standard dark or light mode. What keeps it Hyaline is the **edge**: a lit 1 px hairline where light catches the glass, on the top inside of chrome and raised surfaces, and as an outline around the window. It is a new value in both variants, `#ffffff` at 0.14 on Dark glass and 0.85 on Light glass. In Light, the window outline uses `line`, and on white raised surfaces `line` carries the lift.

In the palette, the flat value is stored as `edge_flat` and the glass value as `edge`, matching `chrome` and `chrome_flat`. The window outline is its own role, `window_edge` and `window_edge_flat`: the edge's values in Dark, `line` in Light.

## Considered options

- **A deep Dark page** (`#1f2329`), the macOS arrangement. Chosen first, then judged by eye against the real glass and dropped: it looked like a different theme.
- **A blue signature tint on every surface.** It stood in for the glass, but the real glass is not steadily blue: it drifts with the scene around a cool gray, which the smoke already carries.

## Consequences

- There are no derived flat values and no exceptions. A change to a glass alpha does not move a flat value.
- `edge` is a new role, so it rides the next major palette version.
- Ports draw the edge where they can: CSS ports fully, VS Code as plain borders. Claude Code and Starship set text colors only, so they show neither the surfaces nor the edge. GNOME Terminal colors its surfaces but leaves the window frame to the GTK theme, so it shows no edge. Windows Terminal has no inner hairline either, but it can color its window frame, so it draws the window outline.
