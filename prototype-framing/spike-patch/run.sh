# SPIKE. Usage: docker run --rm -v <repo>:/hyaline:ro -v <out>:/out <image> <dark|light> <wallpaper.jpg> [flat]
set -euo pipefail
variant=$1; wallpaper=$2; look=${3:-glass}
t0=$(date +%s%N)
lap() { local ms=$(( ($(date +%s%N) - t0) / 1000000 )); printf '%-28s %d.%03ds\n' "$1" $((ms/1000)) $((ms%1000)); }

export DISPLAY=:99 XDG_RUNTIME_DIR=/tmp/xdg-$UID
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

# -noreset, or the wallpaper is wiped when hsetroot exits (research #37).
Xvfb :99 -screen 0 1600x1000x24 -noreset >/tmp/xvfb.log 2>&1 &
until xdpyinfo >/dev/null 2>&1; do sleep 0.1; done
hsetroot -fill "/hyaline/wallpapers/$wallpaper" >/dev/null
# Compositor before the app, so GTK picks an ARGB visual.
picom --config picom.conf >/tmp/picom.log 2>&1 &
# picom owns the _NET_WM_CM_S0 selection through this window; xprop -root cannot see a selection.
until xwininfo -root -children | grep -q '"picom"'; do sleep 0.1; done
lap "display + compositor up"

# Optional title bar: a window manager that leaves compositing to picom.
if [ "${WM:-}" = metacity ]; then
  metacity --no-composite --replace >/tmp/wm.log 2>&1 &
  until xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q 'window id'; do sleep 0.1; done
fi
# Ubuntu's /etc/gtk-3.0/settings.ini names Yaru, which this image lacks; GTK then falls
# back to Adwaita with no dark variant, and theme-variant does nothing. Name a theme that exists.
mkdir -p ~/.config/gtk-3.0
printf "[Settings]\ngtk-theme-name=%s\n%s" "${GTK_THEME_NAME:-Adwaita}" "${GTK_INI_EXTRA:-}" > ~/.config/gtk-3.0/settings.ini

export GEOM_POS; dbus-run-session -- bash -c '
  set -euo pipefail; [ -n "${TRACE:-}" ] && { PS4="+ \$(date +%T.%3N) "; set -x; }
  # The port, by its own install steps.
  flag=--glass; [ "'"$look"'" = flat ] && flag=
  bash /hyaline/Ports/gnome-terminal/dist/'"$variant"'/install.sh $flag --default
  # The README: Preferences > General > Theme variant.
  gsettings set org.gnome.Terminal.Legacy.Settings theme-variant '"$variant"'
  # Scene staging, not theming: a blinking cursor never gives two equal frames.
  uuid=$(sed -n "/\"'"$variant"'\"/s/.*\"uuid\": *\"\([^\"]*\)\".*/\1/p" /hyaline/Ports/gnome-terminal/values.json)
  dconf write "/org/gnome/terminal/legacy/profiles:/:$uuid/cursor-blink-mode" "'"'"'off'"'"'"
  gnome-terminal --geometry=96x22${GEOM_POS:-+200+180} -- bash --norc -i /home/shooter/demo.sh &
  # Wait for the real window by its title; the first window GTK maps can be short-lived.
  # Poll: xdotool search dies with BadWindow if a window vanishes mid-walk.
  wid=; until [ -n "$wid" ]; do sleep 0.2; wid=$(xdotool search --onlyvisible --name "^Terminal$" 2>/dev/null | tail -1 || true); done
  # Wait until two grabs 300 ms apart match: the demo has finished drawing.
  import -window root /tmp/a.png; n=0
  while :; do
    sleep 0.3; import -window root /tmp/b.png; n=$((n+1))
    [ "$(compare -metric AE /tmp/a.png /tmp/b.png null: 2>&1 || true)" = 0 ] && break
    mv /tmp/b.png /tmp/a.png
    [ $n -ge 60 ] && { echo "never settled" >&2; exit 1; }
  done
  echo "settled after $n grabs"
  if [ -n "${WM:-}" ]; then
    frame=$(xwininfo -id "$wid" -children | sed -n "s/^  Parent window id: \(0x[0-9a-f]*\).*/\1/p")
    eval "$(xdotool getwindowgeometry --shell "$frame")"
  else
    eval "$(xdotool getwindowgeometry --shell "$wid")"
  fi
  mv /tmp/b.png /tmp/root.png
  # PROTOTYPE #41: keep the full desktop and both geometries for framing experiments.
  cp /tmp/root.png "/out/'"$variant${TAG:-}"'-root.png"
  xdotool getwindowgeometry --shell "$wid" | sed "s/^/CLIENT_/" > "/out/'"$variant${TAG:-}"'-geom.sh"
  convert /tmp/root.png -crop "${WIDTH}x${HEIGHT}+${X}+${Y}" +repage "/out/'"$variant${TAG:-}"'.png"
  convert /tmp/root.png -resize 50% "/out/'"$variant${TAG:-}"'-desktop.png"
  echo "window ${WIDTH}x${HEIGHT}+${X}+${Y}"
  printf "FRAME_X=%s\nFRAME_Y=%s\nFRAME_W=%s\nFRAME_H=%s\n" $X $Y $WIDTH $HEIGHT >> "/out/'"$variant${TAG:-}"'-geom.sh"
'
lap "shot taken"
