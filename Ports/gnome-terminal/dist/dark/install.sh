#!/usr/bin/env bash
# Adds the Hyaline Dark profile to GNOME Terminal.
# Generated from https://github.com/mookeyj79/Hyaline (Ports/gnome-terminal). Do not edit by hand.
#
# Usage: bash install.sh            add or update the profile
#        bash install.sh --default  also make it the default profile
set -euo pipefail

uuid='1591d279-bd31-435e-9b0c-4e7c90c6f138'
base='/org/gnome/terminal/legacy/profiles:'

# Write every profile key in one go. Running the script again overwrites them.
dconf load "$base/:$uuid/" <<'EOF'
[/]
visible-name='Hyaline Dark'
use-theme-colors=false
background-color='#434850'
foreground-color='#f2f5f9'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='#9cc6e8'
cursor-foreground-color='#1c2028'
highlight-colors-set=true
highlight-background-color='#9cc6e8'
highlight-foreground-color='#1c2028'
palette=['#565a62', '#f1afa7', '#a3d9c0', '#ddd99a', '#9cc6e8', '#dfb1d9', '#a6d2db', '#d0d6e0', '#b4bcc9', '#f1afa7', '#a3d9c0', '#ddd99a', '#9cc6e8', '#dfb1d9', '#a6d2db', '#f2f5f9']
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
  echo 'Hyaline Dark is installed and is now the default profile.'
else
  echo 'Hyaline Dark is installed. Pick it in Preferences or run again with --default.'
fi
