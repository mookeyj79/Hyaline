#!/usr/bin/env bash
# PROTOTYPE, throwaway. Answers Hyaline #41 (The framing look). Not the pipeline.
# Builds candidate treatments from the real captures in $1 (from the patched spike container).
set -euo pipefail
cap=$1; out=$(dirname "$0")/shots; mkdir -p "$out"
pal=${PALETTE:-$(dirname "$0")/../palette/palette.json}
bg_dark=$(python3 -c "import json;print(json.load(open('$pal'))['variants']['dark']['roles']['backdrop'])")
bg_light=$(python3 -c "import json;print(json.load(open('$pal'))['variants']['light']['roles']['backdrop'])")
FX=200 FY=180 FW=986 FH=514          # metacity frame in the 1600x1000 root grab
CX=205 CY=222 CW=976 CH=467          # client area: 5 px border, 37 px title bar
for t in dark light; do
  bg=bg_$t; bg=${!bg}
  for look in glass flat; do
    sfx=; [ $look = flat ] && sfx=-flat
    root=$cap/$t$sfx-root.png; sroot=$cap/$t$sfx-shadow-root.png
    for chrome in title none; do
      if [ $chrome = title ]; then X=$FX Y=$FY W=$FW H=$FH; else X=$CX Y=$CY W=$CW H=$CH; fi
      k=$t-$look-$chrome
      # A: bare window, exactly the capture.
      magick $root -crop ${W}x${H}+$X+$Y +repage $out/A-$k.png
      # C: card on the palette backdrop fill: rounded corners, soft shadow, padding.
      P=56 R=10 S=16
      magick $out/A-$k.png \( -size ${W}x${H} xc:black -fill white -draw "roundrectangle 0,0,$((W-1)),$((H-1)),$R,$R" \) \
        -alpha off -compose CopyOpacity -composite /tmp/rounded.png
      magick /tmp/rounded.png -background black -shadow 45x${S}+0+10 /tmp/shadow.png
      magick -size $((W+2*P))x$((H+2*P)) xc:"$bg" \
        /tmp/shadow.png -geometry +$((P-2*S))+$((P-2*S+10)) -compose over -composite \
        /tmp/rounded.png -geometry +$P+$P -compose over -composite $out/C-$k.png
    done
    # B: a margin of the real desktop around the window, real compositor shadow. Always has the title bar.
    M=64
    magick $sroot -crop $((FW+2*M))x$((FH+2*M))+$((FX-M))+$((FY-M)) +repage $out/B-$t-$look.png
    # D: the whole scene, window in place on the desktop.
    magick $sroot -crop 1600x1000+0+0 +repage $out/D-$t-$look.png
  done
done
# Check: pixels inside the window must match the bare capture (corners excepted in C).
for f in $out/C-*.png; do k=${f##*/C-}; W=$(magick identify -format %w $out/A-$k); H=$(magick identify -format %h $out/A-$k)
  d=$(magick $f -crop ${W}x${H}+56+56 +repage $out/A-$k -compose difference -composite -alpha off -crop $((W-40))x$((H-40))+20+20 -format '%[fx:maxima*255]' info:)
  echo "C ${k%.png}: max diff inside window (corners excluded) = $d"; done
