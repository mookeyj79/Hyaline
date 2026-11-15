#!/usr/bin/env bash
# Removes the Hyaline Dark profile from GNOME Terminal.
# Generated from https://github.com/mookeyj79/Hyaline (Ports/gnome-terminal). Do not edit by hand.
set -euo pipefail

uuid='1591d279-bd31-435e-9b0c-4e7c90c6f138'
base='/org/gnome/terminal/legacy/profiles:'

# If it is the default profile, hand the default back to the first other profile.
list=$(gsettings get org.gnome.Terminal.ProfilesList list)
rest=$(printf '%s' "$list" | sed -e "s/'$uuid'//" -e 's/\[, */[/' -e 's/, *,/,/' -e 's/, *\]/]/')
if [ "$(gsettings get org.gnome.Terminal.ProfilesList default)" = "'$uuid'" ]; then
  first=$(printf '%s' "$rest" | grep -o "'[^']*'" | head -n 1 || true)
  if [ -z "$first" ]; then
    echo 'Hyaline Dark is your only profile. Create another profile first, then run this again.' >&2
    exit 1
  fi
  gsettings set org.gnome.Terminal.ProfilesList default "$first"
fi

gsettings set org.gnome.Terminal.ProfilesList list "$rest"
dconf reset -f "$base/:$uuid/"
echo 'Hyaline Dark is removed.'
