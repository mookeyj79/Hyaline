#!/usr/bin/env bash
# Adds the Hyaline Light profile to GNOME Terminal.
# Generated from https://github.com/mookeyj79/Hyaline (Ports/gnome-terminal). Do not edit by hand.
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

uuid='a3581f79-9bb1-48a7-8603-141adf8914cc'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='Hyaline Light'
use-theme-colors=false
foreground-color='#1b2130'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='#2773b1'
cursor-foreground-color='#ffffff'
highlight-colors-set=true
highlight-background-color='#2773b1'
highlight-foreground-color='#ffffff'
palette=['#1b2130', '#c14437', '#287d54', '#767124', '#2773b1', '#ae47a0', '#287788', '#c4ccd7', '#667085', '#c14437', '#287d54', '#767124', '#2773b1', '#ae47a0', '#287788', '#ffffff']
use-system-font=false
font='FiraCode Nerd Font Mono 12'
EOF

# Glass: the panel tint at the panel's opacity. Flat: the solid panel color.
# Builds without the transparency option ignore the transparency keys.
if [ "$glass" = true ]; then
  dconf load "$base/:$uuid/" <<EOF
[/]
background-color='#ffffff'
use-theme-transparency=false
use-transparent-background=true
background-transparency-percent=$((100 - 96))
EOF
else
  dconf load "$base/:$uuid/" <<'EOF'
[/]
background-color='#fafbfc'
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
  echo "Hyaline Light ($look) is installed and is now the default profile."
else
  echo "Hyaline Light ($look) is installed. Pick it in Preferences or run again with --default."
fi
