# A real desktop in a container, with glass

Research for [issue #37](https://github.com/mookeyj79/Hyaline/issues/37), part of the map in [issue #36](https://github.com/mookeyj79/Hyaline/issues/36). Read on 2026-11-15.

Every claim links to the project's own docs. Where the docs are silent, the project's own source file is linked instead and marked "(source)". Claims marked "(checked)" come from one quick container run, described in [What the quick check showed](#what-the-quick-check-showed). Anything neither covers is listed under [Not verified](#not-verified).

The constraint: Docker only, no GPU, no KVM. All rendering is on the CPU.

## Answer in brief

- **Try first: Xvfb plus picom with the `xrender` backend.** It needs no OpenGL at all. In a quick check it drew Ubuntu's GNOME Terminal with real ARGB transparency and a real blur over a wallpaper, and a plain root-window grab captured it.
- **Fallback: Xvfb plus the real Cinnamon desktop with the Blur Cinnamon extension**, on llvmpipe. This is the setup the GNOME Terminal install guide tells users to build, and it is needed anyway to shoot the Cinnamon port. It is heavier and not proven here.
- **Headless Wayland is the wrong first choice for this job.** Stock sway, labwc, and weston have no blur. The compositors that blur (SwayFX, Wayfire, KWin, GNOME Shell with Blur my Shell) all need OpenGL, so they run on llvmpipe or not at all, and the two apps the spike cares about tie us to X anyway: Blur Cinnamon is X11 only.
- **No session manager is needed.** `dbus-run-session` gives the D-Bus session bus that dconf writes and GNOME Terminal need.
- **No ready-made image fits well.** The closest in spirit is gnome-shell-pod (MIT). Webtop and Kasm are built for streaming a desktop to a browser, and neither ships Cinnamon or GNOME.

## Summary table

| Stack | Blur on CPU | Capture | Wallpaper | GNOME Terminal | Cinnamon |
|---|---|---|---|---|---|
| Xvfb + picom `xrender` | Yes, box, gaussian, or kernel (checked) | Root grab: `import -window root`, `xwd`, or the `-fbdir` file | Root pixmap setter such as `hsetroot` | Yes (checked) | No, Cinnamon is its own compositor |
| Xvfb + picom `glx` | Starts on llvmpipe, but the grab was unreliable (checked) | Same | Same | Yes | No |
| Xvfb + Cinnamon + Blur Cinnamon | Not verified. Cinnamon ships a software rendering launcher | Root grab | Cinnamon's own background setting | Yes, as on Linux Mint | Yes |
| Xvfb + KWin (X11) | Blur is off by default on a software renderer, and apps must ask for it | Root grab | Needs Plasma or a root pixmap | Would not blur without an extra window property | No |
| sway, labwc, weston (headless) | No blur option at all | `grim` (sway, labwc), `weston-screenshooter` (weston, debug mode) | sway: `output * bg` | Runs, but flat | No |
| SwayFX, Wayfire (headless) | Has blur, needs GLES2. Not verified on llvmpipe | `grim` | SwayFX: `output * bg` | Not verified | No |
| KWin `--virtual` (Wayland) | Same limits as KWin on X | KWin screenshot D-Bus interface | Needs Plasma | Would not blur | No |
| `gnome-shell --headless` + Blur my Shell | Not verified | Shell screenshot D-Bus is locked to two callers | `org.gnome.desktop.background` | Yes | No |

## X: Xvfb, Xephyr, or Xorg with the dummy driver

**Xvfb is the one to use.** It "can run on machines with no display hardware and no physical input devices" and "emulates a dumb framebuffer using virtual memory" ([Xvfb man page](https://gitlab.freedesktop.org/xorg/xserver/-/blob/master/hw/vfb/man/Xvfb.man)). With `-screen 0 1280x800x24` it offered a 32-bit depth and ARGB visuals, and GLX through llvmpipe with OpenGL 4.5 (checked, on Ubuntu 24.04).

Two things to know:

- **Pass `-noreset`.** Without it the server resets "when the last client connection is closed" ([Xserver man page](https://gitlab.freedesktop.org/xorg/xserver/-/blob/master/man/Xserver.man)). A wallpaper setter that connects, sets the root pixmap, and exits is the last client, so the wallpaper is wiped. This happened in the quick check until `-noreset` was added.
- **`-fbdir` gives a free screenshot.** The framebuffer is a memory-mapped file "in xwd format. Thus, taking a full-screen snapshot can be done with a file copy command" ([Xvfb man page](https://gitlab.freedesktop.org/xorg/xserver/-/blob/master/hw/vfb/man/Xvfb.man)).

**Xephyr does not help.** It "uses the host X server window as framebuffer" ([Xephyr man page](https://gitlab.freedesktop.org/xorg/xserver/-/blob/master/hw/kdrive/ephyr/man/Xephyr.man)), so it needs another X server underneath it.

**Xorg with the dummy driver** is a "virtual/offscreen frame buffer driver for the Xorg X server" ([xf86-video-dummy README](https://gitlab.freedesktop.org/xorg/driver/xf86-video-dummy/-/blob/master/README.md)). Its README documents nothing else. It needs a full Xorg install and a config file, and nothing found here says it renders anything Xvfb does not. Keep it in reserve for an app that refuses Xvfb.

### The compositor on X

**picom** is a standalone compositor, so it works with any window manager or none.

- It has two backends. `xrender` "performs all rendering operations with X Render extension". `glx` "requires proper OpenGL 3.3 support from your driver and hardware" ([picom man page](https://github.com/yshui/picom/blob/next/man/picom.1.adoc)).
- `blur-background` blurs the "background of semi-transparent / ARGB windows". The blur methods are `gaussian`, `box`, `kernel`, and `dual_kawase` ([picom man page](https://github.com/yshui/picom/blob/next/man/picom.1.adoc)).
- The `xrender` backend does blur, but rejects `dual_kawase`: "Blur method 'dual_kawase' is not compatible with the 'xrender' backend" ([xrender.c](https://github.com/yshui/picom/blob/next/src/backend/xrender/xrender.c), source). So on `xrender` the choice is box, gaussian, or kernel.
- picom's own tests run under `xvfb-run` with the `xrender` and `glx` backends ([run_one_test.sh](https://github.com/yshui/picom/blob/next/tests/run_one_test.sh), source). So Xvfb is a setup the project itself uses.
- picom reads the wallpaper from the root pixmap, which is how X wallpaper setters publish it. The man page does not say this. It was seen in the quick check.

**KWin on X** can blur, but two things stand in the way. The blur effect is not enabled by default when the OpenGL context is a software renderer, though it is still supported whenever KWin composites with OpenGL ([blur.cpp](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/blur/blur.cpp), source: `enabledByDefault` and `supported`). And KWin blurs only where a window asks, through the `_KDE_NET_WM_BLUR_BEHIND_REGION` property on X (same file). GNOME Terminal does not set it. Setting it by hand from outside is possible in principle and is not documented.

**Cinnamon** is its own compositor, so picom cannot run beside it. Cinnamon ships a `cinnamon2d` launcher that starts it with `LIBGL_ALWAYS_SOFTWARE=1` and `CINNAMON_2D=1` ([cinnamon2d](https://github.com/linuxmint/cinnamon/blob/master/files/usr/bin/cinnamon2d), source), so software rendering is a supported mode. Mesa documents `LIBGL_ALWAYS_SOFTWARE` as "always use software rendering" ([Mesa environment variables](https://gitlab.freedesktop.org/mesa/mesa/-/blob/main/docs/envvars.rst)). Blur comes from the Blur Cinnamon extension, which blurs "Application Windows", needs Cinnamon 6.0 or later, and "currently does not work under Wayland, it only works under X11" ([Blur Cinnamon README](https://github.com/klangman/BlurCinnamon/blob/main/README.md)). Whether its blur shaders work in the `cinnamon2d` mode is not documented.

### Capture on X

Grab the root window and crop to the window's geometry. Do not grab the window itself: with a compositor running, a window's own pixels do not include what is behind it. ImageMagick's `import` has `-window root` for the whole screen and `-screen` to "select image from root window" ([import man page](https://github.com/ImageMagick/ImageMagick/blob/main/utilities/import.1.in)). `xwininfo` gives the geometry to crop to.

## Headless Wayland

**wlroots compositors (sway, labwc).** `WLR_BACKENDS=headless` selects the headless backend, `WLR_RENDERER` picks `gles2`, `pixman`, or `vulkan`, and `WLR_RENDERER_ALLOW_SOFTWARE` "allows the gles2 renderer to use software rendering" ([wlroots environment variables](https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/master/docs/env_vars.md)). So they start in a container with no GPU, with either pixman or llvmpipe. ARGB windows are blended. But there is no blur: the word does not appear in the [sway man page](https://github.com/swaywm/sway/blob/master/sway/sway.5.scd) or the [labwc README](https://github.com/labwc/labwc/blob/master/README.md).

- Wallpaper on sway: `output <name> bg <file> <mode>` ([sway-output man page](https://github.com/swaywm/sway/blob/master/sway/sway-output.5.scd)).
- Capture: `grim` grabs the screen, a region with `-g`, or one window with `-T` ([grim man page](https://gitlab.freedesktop.org/emersion/grim/-/blob/master/doc/grim.1.scd)). It needs the compositor to support the screencopy protocol.

**SwayFX** is a sway fork that adds `blur enable`, `blur_passes`, `blur_radius`, and more, by replacing the wlroots renderer with its own ([SwayFX README](https://github.com/WillPower3309/swayfx/blob/master/README.md)). **Wayfire** has a blur plugin with box, gaussian, kawase, and bokeh methods ([blur.xml](https://github.com/WayfireWM/wayfire/blob/master/metadata/blur.xml), source) and lists the GLES2 renderer as required ([Wayfire README](https://github.com/WayfireWM/wayfire/blob/master/README.md)). Neither project documents running on llvmpipe or headless. Both are the Wayland options to spike if X fails.

**weston.** The headless backend "runs in memory. It can be used to capture Weston outputs or to test client applications", and `--renderer` selects the renderer, with pixman as the software one ([weston man page](https://gitlab.freedesktop.org/wayland/weston/-/blob/main/man/weston.man)). Screenshots through `weston-screenshooter` need `--debug`. The man page has no blur.

**KWin.** `kwin_wayland --virtual` will "Render to a virtual framebuffer", with `--width` and `--height` ([main_wayland.cpp](https://invent.kde.org/plasma/kwin/-/blob/master/src/main_wayland.cpp), source). The blur limits are the same as on X. Capture is the `org.kde.KWin.ScreenShot2` D-Bus interface, with `CaptureWindow` and `CaptureScreen` ([screenshotdbusinterface2.cpp](https://invent.kde.org/plasma/kwin/-/blob/master/src/plugins/screenshot/screenshotdbusinterface2.cpp), source). How it authorizes a caller was not read.

**GNOME Shell and Mutter.** Mutter has `--headless` ("Run as a headless display server") and `--virtual-monitor` ("Add persistent virtual monitor (WxH or WxH@R)") ([meta-context-main.c](https://gitlab.gnome.org/GNOME/mutter/-/blob/main/src/core/meta-context-main.c), source), and its docs show `gnome-shell --headless` inside a private D-Bus session ([Mutter: building and running](https://gitlab.gnome.org/GNOME/mutter/-/blob/main/doc/building-and-running.md)). Mutter's own image comparison tests force a software renderer with `MESA_LOADER_DRIVER_OVERRIDE=swrast` (same page). Blur would come from the Blur my Shell extension, which blurs "Applications, behind their windows" ([Blur my Shell README](https://github.com/aunetx/blur-my-shell/blob/master/README.md)). Capture is awkward: the shell's screenshot D-Bus service only answers `org.gnome.SettingsDaemon.MediaKeys` and `org.freedesktop.impl.portal.desktop.gnome` ([screenshot.js](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/screenshot.js), source). Mutter has a hidden `--unsafe-mode` option that is not documented.

**Cinnamon on Wayland** is ruled out by Blur Cinnamon, as above.

## Settings without a login session

**D-Bus.** `dbus-run-session` starts "a session bus instance of dbus-daemon from a shell script" and runs a program in it, to avoid "relying on there already being a D-Bus session active" ([dbus-run-session man page](https://gitlab.freedesktop.org/dbus/dbus/-/blob/main/doc/dbus-run-session.1.xml.in)). Run the whole recipe (settings, then the app, then the capture) inside one `dbus-run-session -- bash -c '...'`. No systemd and no logind were needed (checked).

**dconf and gsettings.** dconf "uses D-Bus. The server is only involved in writes", and the writer is started by D-Bus ([dconf overview](https://gitlab.gnome.org/GNOME/dconf/-/blob/main/docs/dconf-overview.xml)). So `dconf write`, `dconf load`, and `gsettings set` work inside `dbus-run-session` (checked). The database lands in `$XDG_CONFIG_HOME/dconf/`, so `HOME` must be set, and `XDG_RUNTIME_DIR` must exist. The same page warns that `XDG_CONFIG_HOME` must not differ between the writer and the readers.

**GTK settings.** On X, GTK 3 takes its settings from an Xsettings manager, and "in the absence of an Xsettings manager, GTK+ reads default values for settings from settings.ini files" in `$XDG_CONFIG_HOME/gtk-3.0` ([gtksettings.c](https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gtk/gtksettings.c), source docs). So on bare Xvfb there are two choices: write `settings.ini`, or run a settings daemon (the desktop's own, when a full desktop is running). GTK 3 decides whether to use an ARGB visual by looking for a compositing manager on the `_NET_WM_CM_S<n>` selection ([gdkscreen-x11.c](https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gdk/x11/gdkscreen-x11.c), source), so the compositor should be running before the app starts.

**Dark and Light.**

- The desktop-wide switch is `org.gnome.desktop.interface color-scheme`. Apps that use the settings portal read `org.freedesktop.appearance color-scheme`, where 1 is dark and 2 is light ([Settings portal](https://github.com/flatpak/xdg-desktop-portal/blob/main/data/org.freedesktop.portal.Settings.xml)). A bare container has no portal running.
- GNOME Terminal has its own switch: `theme-variant` in its settings schema, default `system` ([gnome-terminal schema](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/src/org.gnome.Terminal.gschema.xml), source). Setting it to `dark` or `light` avoids depending on the desktop. The port's install guide already tells users to set it.
- The terminal colors themselves come from the port's `install.sh`, which writes a dconf profile. That is the install test the pipeline wants.

## GNOME Terminal and Cinnamon

**GNOME Terminal** uses "a D-Bus activated server" ([GNOME Terminal README](https://gitlab.gnome.org/GNOME/gnome-terminal/-/blob/master/README.md)), so it must be started inside the D-Bus session, and `gnome-terminal --wait` keeps the launcher alive. Its transparency exists only in patched builds: Ubuntu carries `0001-Restore-transparency.patch` ([Ubuntu patch series](https://git.launchpad.net/ubuntu/+source/gnome-terminal/tree/debian/patches/series)). So the image must be Ubuntu or Linux Mint for the glass shot. It ran on Xvfb with no window manager and no desktop (checked). It refuses to start in a non UTF-8 locale, so set `LANG=C.UTF-8` (checked).

**Cinnamon** needs X and OpenGL, both of which Xvfb with llvmpipe provides, and it has the `cinnamon2d` software mode above. Nothing found documents Cinnamon running in a container. It likely wants more of a session than one app does (a settings daemon, maybe a session manager). That is for a later spike.

## Ready-made images

| Image | What it is | License | Fit |
|---|---|---|---|
| [gnome-shell-pod](https://github.com/Schneegans/gnome-shell-pod) | Fedora images that run GNOME Shell on Xvfb, for testing extensions on GitHub Actions. Screenshots by copying the Xvfb framebuffer file | MIT ([LICENSE](https://github.com/Schneegans/gnome-shell-pod/blob/main/LICENSE)) | Closest in purpose. But it is Fedora (no transparent GNOME Terminal), uses systemd in the container, is documented for Podman with extra capabilities, and its newest listed image is GNOME 47 |
| [linuxserver/webtop](https://github.com/linuxserver/docker-webtop) | Full desktops streamed to a browser through Selkies. Flavors are XFCE, KDE, i3, LXQt, MATE. No GNOME, no Cinnamon | GPL-3.0 ([LICENSE](https://github.com/linuxserver/docker-webtop/blob/master/LICENSE)) | Poor. The streaming stack is weight we do not need |
| [linuxserver/baseimage-selkies](https://github.com/linuxserver/docker-baseimage-selkies) | Base for single-app containers. Runs labwc, or Openbox on X | GPL-3.0 ([LICENSE](https://github.com/linuxserver/docker-baseimage-selkies/blob/master/LICENSE)) | Poor. labwc has no blur |
| [Kasm workspaces images](https://github.com/kasmtech/workspaces-images) | Desktop and app images streamed through KasmVNC | MIT terms for the repo's own code only ([LICENSE](https://github.com/kasmtech/workspaces-images/blob/develop/LICENSE.md)) | Poor, for the same reason. Which desktops it ships was not read |

The useful thing to take is gnome-shell-pod's method, not its image: Xvfb, a framebuffer file, and plain commands, all working on GitHub's hosted runners. A plain `ubuntu:24.04` or Linux Mint base with a dozen packages is smaller and is what the quick check used.

## What the quick check showed

One throwaway container, `ubuntu:24.04`, no GPU. Packages: `xvfb picom gnome-terminal dbus-x11 dconf-cli libglib2.0-bin imagemagick x11-utils hsetroot mesa-utils`. Versions: picom v10, GNOME Terminal 3.52.0, Mesa 25.2.8 (llvmpipe).

The steps:

1. `Xvfb :99 -screen 0 1280x800x24 -noreset`
2. `hsetroot -fill wallpaper.png`
3. `picom --config picom.conf`, with `backend = "xrender"`, `blur-background = true`, `use-damage = false`, and `blur: { method = "box"; size = 21; }`
4. Inside `dbus-run-session`: `dconf write` the profile keys `use-transparent-background` and `background-transparency-percent`, then `gnome-terminal --wait`
5. `import -window root shot.png`

What it showed:

- **Transparency works** with both picom backends. The wallpaper showed through the terminal background and the text stayed solid.
- **Blur works with the `xrender` backend** when set in a config file. The wallpaper behind the terminal was clearly blurred, on the CPU, with no OpenGL.
- **The same blur settings passed as command-line flags did not blur** in picom v10, with either backend. Use a config file.
- **The `glx` backend was unreliable to capture.** In several runs the grab showed only the wallpaper although the window was mapped. It worked once with damage tracking off. No blurred `glx` shot was obtained.
- **`feh --bg-fill` left the root black.** `hsetroot` worked once `-noreset` was in place. `feh` was not retried after that fix, so it may be fine too.
- **The first terminal start is slow.** A fixed 7 second wait missed it once. The spike should wait for the window to appear, not sleep.
- **There is no title bar**, because nothing was managing windows. A real shot needs a window manager, or the app's own client-side decorations.

The images and scripts were scratch files and are not kept.

## Recommendation

**First: Xvfb, picom on `xrender` with a config file, an Ubuntu base, and `dbus-run-session`.** Capture with `import -window root` and crop to the window. It is the smallest stack, it has no OpenGL in the path, and every piece of it was seen working together in the quick check. Add a small window manager if the shot needs a title bar. This counts as real compositor blur.

One honesty note for the design: picom's blur is not the blur a Linux Mint user gets. The install guide sends them to Blur Cinnamon. The picom shot is real glass, but it is our compositor's glass.

**Fallback: Xvfb with the real Cinnamon desktop and Blur Cinnamon, on a Linux Mint base, using the `cinnamon2d` environment.** Capture the same way. This is the faithful setup, and the Cinnamon port needs it in any case. It is heavier, slower, and unproven.

**If X fails entirely:** SwayFX on the wlroots headless backend with `WLR_RENDERER_ALLOW_SOFTWARE=1`, captured with `grim`.

## Not verified

- Blur Cinnamon under `cinnamon2d` or llvmpipe. Not documented, not tried.
- Cinnamon starting in a container at all. No doc found.
- SwayFX and Wayfire on llvmpipe with the headless backend. Not documented, not tried.
- `gnome-shell --headless` with Blur my Shell on llvmpipe, and a clean way to take a screenshot from it. The `--unsafe-mode` option is hidden and undocumented.
- How KWin's screenshot D-Bus interface authorizes callers, and whether setting `_KDE_NET_WM_BLUR_BEHIND_REGION` on another app's window works.
- picom's `glx` backend producing a blurred shot on Xvfb. It started and found llvmpipe, but capture was flaky.
- Why picom v10 ignored the blur flags on the command line. Newer picom versions were not tried.
- picom reading the wallpaper from the root pixmap is observed, not documented in its man page.
- The Linux Mint build of GNOME Terminal. Only Ubuntu's patch list was read, and only Ubuntu's build was run.
- GTK 4 and libadwaita apps. Only GTK 3 settings were read.
- Which desktops the Kasm images ship.
- GitHub Actions runners. Nothing here was run on one. The check ran in a local Docker sandbox with no GPU and no KVM.
- No host was blocked by the network policy during this research.
