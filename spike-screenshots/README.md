# Spike: GNOME Terminal with glass, shot in a container

Throwaway. Answers [First spike: GNOME Terminal with glass, shot in a container](https://github.com/mookeyj79/Hyaline/issues/40), part of [Map: an automatic screenshot pipeline for ports](https://github.com/mookeyj79/Hyaline/issues/36). This is not the pipeline. It lives only on the `spike/gnome-terminal-in-container` branch.

## Run it

From the repo root:

```sh
docker build -t hyaline-spike-gt spike-screenshots
docker run --rm -v "$PWD":/hyaline:ro -v "$PWD/out":/out -e WM=metacity -e GTK_THEME=Adwaita:dark \
  hyaline-spike-gt dark forest-under-gray-sky.jpg          # add "flat" as a third argument for flat
docker run --rm -v "$PWD":/hyaline:ro -v "$PWD/out":/out -e WM=metacity -e GTK_THEME=Adwaita \
  hyaline-spike-gt light white-sands-dunes.jpg
```

## Answer

Yes. One container, built and run in the agent sandbox with no GPU and no KVM, installs Ubuntu's GNOME Terminal, applies the port by running `Ports/gnome-terminal/dist/<variant>/install.sh --glass --default` from the repo, shows it over a repo wallpaper with real transparency and real compositor blur, and captures Dark and Light. Flat works the same way.

- Glass: [dark.png](shots/dark.png), [light.png](shots/light.png). The whole desktop: [dark-desktop.png](shots/dark-desktop.png).
- Flat: [dark-flat.png](shots/dark-flat.png), [light-flat.png](shots/light-flat.png).
- Window frame switches tried: [frames.png](shots/frames.png).

Reliability and time, after the fixes below: 10 runs in a row (5 Dark, 5 Light), 10 shots, 6 to 7 seconds each from container start. Building the image takes about 1 minute 45 seconds and it is 843 MB.

## What the run needed

- **Base and packages:** `ubuntu:24.04`, plus `xvfb picom gnome-terminal dbus-x11 dconf-cli libglib2.0-bin imagemagick x11-utils xdotool hsetroot metacity`, and FiraCode Nerd Font v3.4.0 from the Nerd Fonts release. Versions: GNOME Terminal 3.52.0, picom 10.2, metacity 3.52.0, Xvfb 21.1.12, ImageMagick 6.9.12.
- **Display:** `Xvfb :99 -screen 0 1600x1000x24 -noreset`, wallpaper by `hsetroot -fill`.
- **Compositor:** picom, `xrender` backend, gaussian blur, from [picom.conf](picom.conf), started before the app. Ready when its window named `picom` exists. `xprop -root _NET_WM_CM_S0` never sees it, because that is a selection, not a property.
- **Window manager:** metacity with `--no-composite`, so picom keeps compositing. Without one there is no title bar and the window never gets focus, so the cursor does not show.
- **Session:** everything after the display inside one `dbus-run-session`. No systemd, no login.
- **Capture:** grab the root window, crop to the window manager's frame around the terminal.

## Traps hit, and the fix for each

1. **Slow and starved X.** With `use-damage = false`, picom repainted the whole blurred screen on every frame. Each screen grab took 4 to 5 seconds and a run took 10 to 34 seconds. With `use-damage = true` the blur is unchanged and a run takes 6 to 7 seconds.
2. **`xdotool search --sync` crashes.** It fails with `BadWindow` when a window disappears while it walks the window tree, which GNOME Terminal's startup windows sometimes do. About half the runs failed. Polling the search and ignoring its errors fixed it.
3. **Wait for pixels, not time.** The run grabs the screen until two grabs 300 ms apart are equal. That needs the cursor to stop blinking, so the run sets `cursor-blink-mode` to `off` on the profile after the install script. This changes no color, but it is a scene setting the port's install steps do not make.
4. **The window frame stayed light in Dark.** Ubuntu's `/etc/gtk-3.0/settings.ini` names the Yaru theme, which this image lacks, so GTK falls back to Adwaita with no dark variant. Naming Adwaita in `~/.config/gtk-3.0/settings.ini` fixes the fallback. Then, in [frames.png](shots/frames.png):
   - GNOME Terminal's `theme-variant` key, the step the port README gives, changed nothing.
   - `gtk-application-prefer-dark-theme=1` in `settings.ini` darkened the menu bar but not metacity's title bar (top strip).
   - `GTK_THEME=Adwaita:dark` darkened both (bottom strip). The spike uses this.

## What a recipe would have to hold

For GNOME Terminal, beyond what every recipe shares (display size, compositor, window manager, capture):

- The base image and the packages that bring the app.
- The install commands, taken from the port README: `install.sh --glass --default` for glass, without `--glass` for flat.
- The scene: what the terminal shows (here [demo.sh](demo.sh): a prompt, `ls --color`, the 16 colors, a line per role), the window size in cells, and staging settings such as the cursor not blinking.
- How to find the window: here, a visible window titled `Terminal`.
- The frame theme per variant: `GTK_THEME=Adwaita:dark` or `Adwaita`.
- The wallpaper per variant.

## Open points for later tickets

- **The README's Theme variant step may not work.** In the container `theme-variant` had no visible effect. It is unclear whether that is the container (no settings daemon) or the app. Check on a real Linux Mint or Ubuntu desktop.
- **The frame is Adwaita drawn by metacity**, not Mint-Y with Cinnamon's frame or Yaru with GNOME Shell's. It is honest GTK, but it is not what a Mint user sees. This is for [The framing look](https://github.com/mookeyj79/Hyaline/issues/41).
- **Light glass looks almost the same as flat**, because the Light profile is 93 percent opaque. That is the real look, not a capture problem.
- **picom's blur is ours, not Blur Cinnamon's**, as research found. Glass covers only the terminal area; the menu bar and title bar are solid, as GTK draws them.
- **Not run on a GitHub Actions runner.**
