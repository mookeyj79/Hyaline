"""WCAG 2 and APCA contrast for panel text on opacity-only glass.

Research script for issue #89. Reads palette/palette.json, composites each
variant's panel tint over pure black and pure white at a given alpha, then
measures each text row against the composite. The lower result of the two
backdrops counts (ADR 0011).

Compositing is per channel in gamma-encoded sRGB, as build/lib/Palette.psm1
Get-Blend does and as apca-w3's alphaBlend does. Get-Blend rounds each channel
to a whole 0..255 value. The table in issue #85 did not round: its numbers
come out exactly with the unrounded composite. Both are printed.

APCA follows apca-w3 0.1.9 (base algorithm 0.0.98G-4g), constants copied from
https://github.com/Myndex/apca-w3/blob/master/src/apca-w3.js and checked
against the expected values in that package's test/index.js.

Run: python3 docs/research/contrast-on-translucency.py
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
PALETTE = json.loads((ROOT / "palette" / "palette.json").read_text())

ROWS = ["text", "text_dim", "text_muted",
        "red", "green", "yellow", "blue", "magenta", "cyan", "orange"]
WCAG_NEED = {"text_muted": 3.0}  # every other panel row needs 4.5
BLACK, WHITE = "#000000", "#ffffff"


def rgb(hex_):
    return tuple(float(int(hex_[i:i + 2], 16)) for i in (1, 3, 5))


def blend(fg, bg, alpha, rounded):
    """fg at alpha over bg, channels 0..255. rounded=True is Get-Blend."""
    out = []
    for f, b in zip(rgb(fg), rgb(bg)):
        v = f * alpha + b * (1 - alpha)
        if rounded:
            # .NET Math.Round is banker's rounding; make sure no tie occurs.
            assert abs(v - int(v) - 0.5) > 1e-9, "tie: rounding mode matters"
            v = float(round(v))
        out.append(v)
    return tuple(out)


def show(c):
    return "#" + "".join(f"{round(v):02x}" for v in c) + (
        "" if all(v == int(v) for v in c) else "~")


# WCAG 2 relative luminance and contrast ratio, as Get-Contrast does.
def wcag_lum(c):
    def lin(v):
        s = v / 255
        return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(v) for v in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def wcag(a, b):
    la, lb = sorted((wcag_lum(a), wcag_lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# APCA, apca-w3 0.1.9 SA98G constants.
K = dict(
    mainTRC=2.4, sRco=0.2126729, sGco=0.7151522, sBco=0.0721750,
    normBG=0.56, normTXT=0.57, revTXT=0.62, revBG=0.65,
    blkThrs=0.022, blkClmp=1.414, scaleBoW=1.14, scaleWoB=1.14,
    loBoWoffset=0.027, loWoBoffset=0.027, deltaYmin=0.0005, loClip=0.1,
)


def apca_y(c):
    r, g, b = ((v / 255.0) ** K["mainTRC"] for v in c)
    return K["sRco"] * r + K["sGco"] * g + K["sBco"] * b


def apca(text, bg):
    """Lc of text on bg. Positive: dark text on light. Negative: light on dark."""
    t, b = apca_y(text), apca_y(bg)
    t = t if t > K["blkThrs"] else t + (K["blkThrs"] - t) ** K["blkClmp"]
    b = b if b > K["blkThrs"] else b + (K["blkThrs"] - b) ** K["blkClmp"]
    if abs(b - t) < K["deltaYmin"]:
        return 0.0
    if b > t:
        sapc = (b ** K["normBG"] - t ** K["normTXT"]) * K["scaleBoW"]
        out = 0.0 if sapc < K["loClip"] else sapc - K["loBoWoffset"]
    else:
        sapc = (b ** K["revBG"] - t ** K["revTXT"]) * K["scaleWoB"]
        out = 0.0 if sapc > -K["loClip"] else sapc + K["loWoBoffset"]
    return out * 100.0


def measure(variant, alpha, rounded):
    roles = PALETTE["variants"][variant]["roles"]
    tint = roles["panel"]["hex"]
    surf = {bg: blend(tint, bg, alpha, rounded) for bg in (BLACK, WHITE)}
    rows = {}
    for r in ROWS:
        fg = rgb(roles[r])
        rows[r] = dict(
            wcag=min(wcag(fg, s) for s in surf.values()),
            lc={bg: abs(apca(fg, s)) for bg, s in surf.items()},
        )
        rows[r]["lc_min"] = min(rows[r]["lc"].values())
    return surf, rows


def self_test():
    # Expected values from apca-w3 0.1.9's own test/index.js: (text, bg, Lc).
    cases = [
        ("#888888", "#ffffff", 63.056469930209424),
        ("#ffffff", "#888888", -68.54146436644962),
        ("#000000", "#aaaaaa", 58.146262578561334),
        ("#aaaaaa", "#000000", -56.24113336839742),
        ("#112233", "#ddeeff", 91.66830811481631),
        ("#ddeeff", "#112233", -93.06770049484275),
        ("#112233", "#444444", 8.32326136957393),
        ("#444444", "#112233", -7.526878460278154),
    ]
    for t, b, want in cases:
        got = apca(rgb(t), rgb(b))
        assert abs(got - want) < 1e-9, (t, b, got, want)
    # Issue #85's table, reproduced with the unrounded composite.
    issue85 = {
        "dark": [6.55, 4.90, 3.74, 3.88, 4.61, 4.95, 3.97, 3.84, 4.46, 4.23],
        "light": [8.76, 4.40, 2.71, 2.76, 2.76, 2.75, 2.74, 2.72, 2.80, 2.72],
    }
    for v, want in issue85.items():
        _, rows = measure(v, 0.75, rounded=False)
        got = [round(rows[r]["wcag"], 2) for r in ROWS]
        assert got == want, (v, got, want)


def main():
    self_test()
    print("apca-w3 0.1.9 test values and issue #85's table reproduced.")
    for variant in ("dark", "light"):
        today = PALETTE["variants"][variant]["roles"]["panel"]["alpha"]
        for alpha in (0.75, today):
            s_r, rr = measure(variant, alpha, rounded=True)
            s_u, ru = measure(variant, alpha, rounded=False)
            print(f"\n{variant} panel at {alpha}: over black {show(s_r[BLACK])}"
                  f" ({show(s_u[BLACK])} unrounded), over white {show(s_r[WHITE])}"
                  f" ({show(s_u[WHITE])} unrounded)")
            print(f"{'row':<11}{'need':>5}{'WCAG rnd':>9}{'WCAG raw':>9}"
                  f"{'Lc blk':>8}{'Lc wht':>8}{'Lc min':>8}{'Lc raw':>8}")
            for r in ROWS:
                need = WCAG_NEED.get(r, 4.5)
                a, b = rr[r], ru[r]
                flag = lambda x: "*" if x < need else " "
                print(f"{r:<11}{need:5.1f}{a['wcag']:8.2f}{flag(a['wcag'])}"
                      f"{b['wcag']:8.2f}{flag(b['wcag'])}"
                      f"{a['lc'][BLACK]:8.1f}{a['lc'][WHITE]:8.1f}"
                      f"{a['lc_min']:8.1f}{b['lc_min']:8.1f}")
    print("\nWCAG rnd: composite rounded per channel, as Get-Blend and check.ps1."
          "\nWCAG raw: unrounded composite, as issue #85. * = below the floor."
          "\nLc: |APCA Lc| over each backdrop (rounded composite); min is the worse;"
          "\nLc raw: worse |Lc| with the unrounded composite.")


if __name__ == "__main__":
    main()
