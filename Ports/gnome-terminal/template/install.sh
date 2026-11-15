#!/usr/bin/env bash
# Adds the {{variant.name}} profile to GNOME Terminal.
# Generated from {{meta.repository}} (Ports/gnome-terminal). Do not edit by hand.
#
# Usage: bash install.sh            add or update the profile
#        bash install.sh --default  also make it the default profile
set -euo pipefail

uuid='{{port.uuid}}'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key in one go. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='{{variant.name}}'
use-theme-colors=false
background-color='{{panel_flat}}'
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

# Add the profile to the list GNOME Terminal shows, once.
list=$(gsettings get org.gnome.Terminal.ProfilesList list)
case "$list" in
  *"'$uuid'"*) ;;
  '@as []' | '[]') gsettings set org.gnome.Terminal.ProfilesList list "['$uuid']" ;;
  *) gsettings set org.gnome.Terminal.ProfilesList list "${list%]}, '$uuid']" ;;
esac

if [ "${1:-}" = '--default' ]; then
  gsettings set org.gnome.Terminal.ProfilesList default "$uuid"
  echo '{{variant.name}} is installed and is now the default profile.'
else
  echo '{{variant.name}} is installed. Pick it in Preferences or run again with --default.'
fi
