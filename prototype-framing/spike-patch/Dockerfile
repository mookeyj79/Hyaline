# SPIKE, throwaway. Answers Hyaline #40: can a container shoot GNOME Terminal
# with real glass? Not the pipeline. Lives only on spike/gnome-terminal-in-container.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      xvfb picom gnome-terminal dbus-x11 dconf-cli libglib2.0-bin \
      imagemagick x11-utils xdotool hsetroot metacity ca-certificates curl unzip fontconfig \
    && rm -rf /var/lib/apt/lists/*

# FiraCode Nerd Font, as the port README asks. Pinned release.
RUN mkdir -p /usr/share/fonts/nerd \
    && curl -fsSL -o /tmp/f.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip \
    && unzip -q /tmp/f.zip 'FiraCodeNerdFontMono-*.ttf' -d /usr/share/fonts/nerd \
    && rm /tmp/f.zip && fc-cache -f

RUN useradd -m shooter
USER shooter
WORKDIR /home/shooter
COPY --chown=shooter picom.conf run.sh demo.sh ./
ENTRYPOINT ["bash", "run.sh"]
