
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq curl ca-certificates gnupg xvfb imagemagick x11-utils xdotool libnss3 libgtk-3-0t64 libasound2t64 libgbm1 libxss1 libxshmfence1 fonts-dejavu >/dev/null
mkdir -p /etc/apt/keyrings
curl -fsSL https://downloads.typora.io/typora.gpg > /etc/apt/keyrings/typora.gpg
echo "deb [signed-by=/etc/apt/keyrings/typora.gpg] https://downloads.typora.io/linux ./" > /etc/apt/sources.list.d/typora.list
apt-get update -qq
apt-get install -y typora > /out/apt.log 2>&1; echo "apt exit $?"
dpkg -s typora | grep -E 'Version|Depends'
printf '# Hello\n\nSome *text* and `code`.\n' > /tmp/a.md
Xvfb :99 -screen 0 1400x900x24 2>/dev/null & sleep 2
export DISPLAY=:99
typora --no-sandbox /tmp/a.md > /out/typora.log 2>&1 &
sleep 20
xwininfo -root -tree | grep -i -E '"[^"]+"' | head -20
import -window root /out/shot1.png
sleep 5; xdotool search --name . getwindowname %@ 2>/dev/null | sort -u
import -window root /out/shot2.png
ls -la ~/.config/Typora 2>/dev/null; find ~/.config/Typora -maxdepth 2 | head -40
cat ~/.config/Typora/profile.data 2>/dev/null | head -c 600; echo
