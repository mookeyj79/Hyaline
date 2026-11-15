#!/usr/bin/env bash
# Adds the Hyaline Light profile to GNOME Terminal.
# Generated from https://github.com/mookeyj79/Hyaline (Ports/gnome-terminal). Do not edit by hand.
#
# Usage: bash install.sh            add or update the profile
#        bash install.sh --default  also make it the default profile
set -euo pipefail

uuid='a3581f79-9bb1-48a7-8603-141adf8914cc'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key in one go. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='Hyaline Light'
use-theme-colors=false
background-color='#f3f6f9'
foreground-color='#1b2130'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='#2973b0'
cursor-foreground-color='#ffffff'
highlight-colors-set=true
highlight-background-color='#2973b0'
highlight-foreground-color='#ffffff'
palette=['#1b2130', '#c04538', '#207e52', '#78710a', '#2973b0', '#ae47a0', '#18788b', '#d3dae3', '#667085', '#c04538', '#207e52', '#78710a', '#2973b0', '#ae47a0', '#18788b', '#f9fafc']
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
  echo 'Hyaline Light is installed and is now the default profile.'
else
  echo 'Hyaline Light is installed. Pick it in Preferences or run again with --default.'
fi
