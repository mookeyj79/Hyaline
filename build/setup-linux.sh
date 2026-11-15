#!/usr/bin/env bash
# Installs the tools this repo needs on a Debian-based Linux box or sandbox:
#   pwsh      PowerShell 7, for build/*.ps1 (with libicu, which it needs to start)
#   chromium  headless browser, for the preview screenshots and checking the site
# Safe to run again: anything already installed is skipped.
#
# Usage: bash build/setup-linux.sh
#        PWSH_VERSION=7.7.0 bash build/setup-linux.sh
set -euo pipefail

PWSH_VERSION="${PWSH_VERSION:-7.7.0}"
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

need_apt=()
if ! ldconfig -p 2>/dev/null | grep -q 'libicuuc\.so'; then
  icu=$(apt-cache search '^libicu[0-9]+$' 2>/dev/null | awk '{print $1}' | sort -V | tail -1)
  [ -z "$icu" ] && { $SUDO apt-get update -qq; icu=$(apt-cache search '^libicu[0-9]+$' | awk '{print $1}' | sort -V | tail -1); }
  need_apt+=("$icu")
fi
command -v chromium >/dev/null 2>&1 || need_apt+=(chromium)

if [ ${#need_apt[@]} -gt 0 ]; then
  echo "Installing: ${need_apt[*]}"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq "${need_apt[@]}" >/dev/null
fi

if ! command -v pwsh >/dev/null 2>&1; then
  case "$(uname -m)" in
    x86_64) arch=x64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
  esac
  echo "Installing PowerShell $PWSH_VERSION ($arch)"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/pwsh.tar.gz" \
    "https://github.com/PowerShell/PowerShell/releases/download/v$PWSH_VERSION/powershell-$PWSH_VERSION-linux-$arch.tar.gz"
  $SUDO mkdir -p /opt/pwsh
  $SUDO tar -xzf "$tmp/pwsh.tar.gz" -C /opt/pwsh
  $SUDO chmod +x /opt/pwsh/pwsh
  $SUDO ln -sf /opt/pwsh/pwsh /usr/local/bin/pwsh
fi

echo "pwsh:     $(pwsh -NoProfile -c '$PSVersionTable.PSVersion.ToString()')"
echo "chromium: $(chromium --version 2>/dev/null || echo missing)"
