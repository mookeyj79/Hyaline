# Prototype: the framing look

Throwaway. Answers [The framing look](https://github.com/mookeyj79/Hyaline/issues/41), part of [Map: an automatic screenshot pipeline for ports](https://github.com/mookeyj79/Hyaline/issues/36). Not the pipeline. Lives only on the `prototype/framing-look` branch.

## Verdict

**B, real desktop margin, glass, in the README Dark and Light table.** The finished screenshot is a crop of the real desktop grab: the window plus a 64 px margin of the wallpaper it sat on, with the compositor's own shadow. Nothing is composited after capture, so the glass and the wallpaper around it always agree. A glass-capable port shows its glass look.

## What is here

- `index.html`: the viewer. Four treatments (A bare window, B real desktop margin, C card on the palette backdrop, D whole scene), glass or flat, title bar or none, in a mock port README. Open it next to `shots/`.
- `frame.sh`: builds `shots/` from the captures. `bash frame.sh <capture dir>`. Needs ImageMagick 7.
- `spike-patch/`: the spike container from `spike/gnome-terminal-in-container`, changed to keep the full 1600 x 1000 root grab and the window geometry, to take the window position from `GEOM_POS`, and (in `picom.conf`) to draw a real shadow. Build it twice, once without the shadow line, to get both capture sets.

Captures: Dark on `forest-under-gray-sky.jpg`, Light on `white-sands-dunes.jpg`, window frame at 986 x 514 +200+180.

## Findings

- **Light glass looks flat in every treatment.** The port is 93 percent opaque. Moving the window over the horizon (`GEOM_POS=+300+440`) shows only a faint ghost. That is the port's opacity, not framing.
- **picom's real shadow is safe.** Flat windows were pixel-identical with and without it. Glass windows changed by at most 2 of 255 levels across the body, which cannot be seen.
- **A pasted backdrop disagrees with glass.** In C, Dark glass shows the blurred forest inside a flat slate card.
- **The title bar stays with B.** A margin of real desktop needs the whole window, so cropping to the client area is not an option. The frame is Adwaita drawn by metacity.
- **Size in the table.** With a 64 px margin the window is about 88 percent of the image width, so text is slightly smaller than a bare crop at README size.
