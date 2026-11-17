# Opacity-only glass has its own floor rows

Amends ADR 0008 and ADR 0011.

Opacity-only glass (a tint and one opacity, no clamp) had to pass the full contrast floor over pure black and pure white. That forced Light's panel to 0.96, where it looks almost flat. An eye test found Hyaline glass at 75 percent readable over the wallpaper made for the other variant, though the measurement failed. Black and white are a stricter test than reading needs.

So opacity-only glass keeps the same test and gets its own rows of the contrast floor. It is still measured over pure black and pure white, blur still does not count, and the rows apply to both variants. Every threshold except primary text is two thirds of the solid row, so 4.5 becomes 3 and 3 becomes 2.

| On (opacity-only glass) | Primary text | Dim text | Muted text | Role colors |
|---|---|---|---|---|
| Panel | 4.5 | 3 | 2 | 3 |
| A wash | 4.5 | 2 | 2 | 2 |
| Chrome | 4.5 | n/a | n/a | n/a |

Primary text keeps 4.5 because it is the text being read. On the panel, 3 is WCAG 2's level for large text and non-text. Chrome keeps its row, and solid surfaces (the flat values, and raised on opacity-only glass) and the clamp glass keep the full floor.

Under these rows, the panel alpha is 0.82 in both variants. Dark is unchanged, and Light goes from 0.96 to 0.82. One value lets the terminal ports, which set one opacity per profile, ship one setting. At 0.82, every measurement passes. The tightest are Light's role colors on the panel over black (3.27 against 3) and Light's washes over black (2.45 against 2). The lowest alpha that passes is 0.74 in Dark and 0.79 in Light.

## Considered options

- **Keep the full floor.** Light's panel stays at 0.96 and looks flat, though it reads fine thinner.
- **Measure over the variant's own kind of backdrop.** The backdrop can be anything. A Light terminal often sits over a dark window, and any "realistic" limit gets picked to make a number pass.
- **A perceptual measure such as APCA.** Not ready to adopt (dropped from the WCAG 3 draft, still beta, web-only licence), and stricter than WCAG 2 for Dark.
- **Darker role colors for opacity-only glass.** Every role splits in two, which breaks "sameness beats perfection".
- **Lower only the rows that fail at 0.82.** That picks the rule to fit an alpha.

## Consequences

- It is still one contrast floor, with rows for opacity-only glass the way raised and wash have rows. There is no second term.
- Windows Terminal and GNOME Terminal stay Tier 1. Tier 1 promises translucent surfaces that pass the contrast floor over any backdrop, and these rows are part of the floor.
- The check script measures opacity-only glass (the panel at its dense alpha, and washes over it) against these rows.
- No wash alpha, flat value, raised value, or chrome alpha moves.
