#!/usr/bin/env bash
# Adds the Hyaline Dark profile to GNOME Terminal.
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

uuid='1591d279-bd31-435e-9b0c-4e7c90c6f138'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='Hyaline Dark'
use-theme-colors=false
foreground-color='#f2f5f9'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='#8dc7f6'
cursor-foreground-color='#1c2028'
highlight-colors-set=true
highlight-background-color='#8dc7f6'
highlight-foreground-color='#1c2028'
palette=['#565a62', '#f7aca4', '#88e1ba', '#e2da71', '#8dc7f6', '#eda7e5', '#84d9e9', '#d0d6e0', '#b4bcc9', '#f7aca4', '#88e1ba', '#e2da71', '#8dc7f6', '#eda7e5', '#84d9e9', '#f2f5f9']
use-system-font=false
font='FiraCode Nerd Font Mono 12'
EOF

# Glass: the panel tint at the panel's opacity. Flat: the solid panel color.
# Builds without the transparency option ignore the transparency keys.
if [ "$glass" = true ]; then
  dconf load "$base/:$uuid/" <<EOF
[/]
background-color='#1c2028'
use-theme-transparency=false
use-transparent-background=true
background-transparency-percent=$((100 - 80))
EOF
else
  dconf load "$base/:$uuid/" <<'EOF'
[/]
background-color='#434850'
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
  echo "Hyaline Dark ($look) is installed and is now the default profile."
else
  echo "Hyaline Dark ($look) is installed. Pick it in Preferences or run again with --default."
fi
