#!/usr/bin/env bash
# Adds the {{variant.name}} profile to GNOME Terminal.
# Generated from {{meta.repository}} (Ports/gnome-terminal). Do not edit by hand.
#
# Usage: bash install.sh [--glass] [--default]
#   --glass    translucent background, for builds that have
#              "Use transparent background" (Ubuntu, Linux Mint)
#   --default  also make it the default profile
set -euo pipefail

glass=false
default=false
for arg in "$@"; do
  case "$arg" in
    --glass) glass=true ;;
    --default) default=true ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

uuid='{{port.uuid}}'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='{{variant.name}}'
use-theme-colors=false
foreground-color='{{text}}'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='{{accent}}'
cursor-foreground-color='{{on_accent}}'
highlight-colors-set=true
highlight-background-color='{{accent}}'
highlight-foreground-color='{{on_accent}}'
palette=['{{ansi.black}}', '{{ansi.red}}', '{{ansi.green}}', '{{ansi.yellow}}', '{{ansi.blue}}', '{{ansi.magenta}}', '{{ansi.cyan}}', '{{ansi.white}}', '{{ansi.bright_black}}', '{{ansi.bright_red}}', '{{ansi.bright_green}}', '{{ansi.bright_yellow}}', '{{ansi.bright_blue}}', '{{ansi.bright_magenta}}', '{{ansi.bright_cyan}}', '{{ansi.bright_white}}']
use-system-font=false
font='FiraCode Nerd Font Mono 12'
EOF

# Glass: the panel tint at the panel's opacity. Flat: the solid panel color.
# Builds without the transparency option ignore the transparency keys.
if [ "$glass" = true ]; then
  dconf load "$base/:$uuid/" <<EOF
[/]
background-color='{{panel}}'
use-theme-transparency=false
use-transparent-background=true
background-transparency-percent=$((100 - {{panel|percent}}))
EOF
else
  dconf load "$base/:$uuid/" <<'EOF'
[/]
background-color='{{panel_flat}}'
use-theme-transparency=false
use-transparent-background=false
EOF
fi

# Add the profile to the list GNOME Terminal shows, once.
list=$(gsettings get org.gnome.Terminal.ProfilesList list)
case "$list" in
  *"'$uuid'"*) ;;
  '@as []' | '[]') gsettings set org.gnome.Terminal.ProfilesList list "['$uuid']" ;;
  *) gsettings set org.gnome.Terminal.ProfilesList list "${list%]}, '$uuid']" ;;
esac

look='flat'
[ "$glass" = true ] && look='glass'
if [ "$default" = true ]; then
  gsettings set org.gnome.Terminal.ProfilesList default "$uuid"
  echo "{{variant.name}} ($look) is installed and is now the default profile."
else
  echo "{{variant.name}} ($look) is installed. Pick it in Preferences or run again with --default."
fi
