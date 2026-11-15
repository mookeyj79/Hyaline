# What hosted Windows and macOS runners can show

Research for [issue #39](https://github.com/mookeyj79/Hyaline/issues/39), part of the map in [issue #36](https://github.com/mookeyj79/Hyaline/issues/36). Read on 2026-11-15.

Sources are GitHub Docs, the `actions/runner-images` repo (image READMEs, build scripts, issues), Microsoft Learn, the Windows Terminal repo and docs, and Apple's docs. Build scripts are marked "(source)". Claims that rest only on issue reports or on other projects' workflows are marked "(issue report)" or "(example)". Nothing here was tested on a runner: no workflow was run for this research. What that leaves open is listed under [Not verified](#not-verified).

## Answer in brief

- **A real screenshot of a GUI app is possible on both.** Hosted Windows and macOS runners have a logged-in desktop, and other projects capture it today. GitHub does not document this for Windows. It is known from the preinstalled tools and from projects that depend on it.
- **Flat Windows Terminal shots look safe. Glass shots are the open risk.** Windows Terminal says acrylic "likely doesn't work" in a virtual machine, and no source says whether acrylic or Mica render on a hosted runner. A spike has to answer that.
- **`windows-2022` can never show Mica.** It is build 20348 and Windows Terminal needs 22621. Only `windows-2025` and `windows-11-arm` pass the version check.
- **Windows Terminal is not in any image's software list.** The portable ZIP is the install path with the fewest unknowns. winget is not on the Server 2022 or Windows 11 Arm images.
- **macOS: `screencapture` is pre-approved, but the image turns transparency off.** The image build sets "Reduce transparency" and a solid black wallpaper. Both have to be undone in the job before vibrancy can show.
- **Cost for this repo is zero.** Standard runners are free and unlimited in public repositories. Limits are 6 hours per job, 20 concurrent jobs, and 5 concurrent macOS jobs on the Free plan.

## Runner images today

From the [runner-images README](https://github.com/actions/runner-images/blob/main/README.md) and each image's README.

| Label | OS | Build | Notes |
|---|---|---|---|
| `windows-2022` | Windows Server 2022 | 10.0.20348 | x64 |
| `windows-latest`, `windows-2025`, `windows-2025-vs2026` | Windows Server 2025 | 10.0.26100 | x64 |
| `windows-11-arm`, `windows-11-vs2026-arm` | Windows 11 Enterprise | 10.0.26200 | arm64. The only client Windows image |
| `macos-latest`, `macos-26`, `macos-15` | macOS 26, macOS 15 | | arm64 |
| `macos-26-intel`, `macos-15-intel` | macOS 26, macOS 15 | | x64 |

There is no x64 Windows 11 image. macOS 14 was retired on 2026-11-02.

Hardware for public repositories, from [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners): Windows has 4 CPUs and 16 GB RAM, macOS arm64 has 3 CPUs (M1) and 7 GB RAM. The page lists no GPU for any standard runner. GPUs appear only under [larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners), which are paid and need a Team or Enterprise plan.

## Windows

### Is there a desktop to draw to?

Yes in practice. GitHub's docs do not say so.

- The docs only say Windows runners "run as administrators with User Account Control (UAC) disabled" ([reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)). They say nothing about a desktop session.
- All three Windows images preinstall WinAppDriver 1.2, a tool that drives real windows ([Windows2022-Readme](https://github.com/actions/runner-images/blob/main/images/windows/Windows2022-Readme.md), [Windows2025-VS2026-Readme](https://github.com/actions/runner-images/blob/main/images/windows/Windows2025-VS2026-Readme.md), [Windows11-VS2026-Arm64-Readme](https://github.com/actions/runner-images/blob/main/images/windows/Windows11-VS2026-Arm64-Readme.md)).
- Pillow's test suite grabs the screen on `windows-latest`, `windows-2022`, and `windows-11-arm` ([test-windows.yml](https://github.com/python-pillow/Pillow/blob/main/.github/workflows/test-windows.yml), [test_imagegrab.py](https://github.com/python-pillow/Pillow/blob/main/Tests/test_imagegrab.py)) (example).
- A screenshot of the runner desktop is attached to [runner-images #14069](https://github.com/actions/runner-images/issues/14069) (issue report).

Two warnings:

- **`windows-11-arm` does not start on a clean desktop.** A full-screen privacy settings window, an open Start menu, and a System Properties dialog sit on top. The issue is open since August 2025. Electron's CI reports that none of these appear on `windows-latest` x64 ([#14069](https://github.com/actions/runner-images/issues/14069)) (issue report).
- **Azure Pipelines says the opposite for its own service.** Its docs state that visible UI testing is not supported on Microsoft-hosted agents ([UI testing considerations](https://learn.microsoft.com/en-us/azure/devops/pipelines/test/ui-testing-considerations?view=azure-devops)). The images are the same, the hosting service is not. That page does not describe GitHub Actions.

The image build scripts set up no desktop, theme, or visual effect settings for Windows (source: [images/windows/scripts/build](https://github.com/actions/runner-images/tree/main/images/windows/scripts/build)). Whatever the session looks like comes from Windows defaults and the hosting service.

### Screen resolution

- The default is 1024x768. This is from a 2021 question ([#2935](https://github.com/actions/runner-images/issues/2935)) and the 1024x768 screenshot in [#14069](https://github.com/actions/runner-images/issues/14069) (issue reports). It is not documented.
- A maintainer's answer in #2935 is `Set-DisplayResolution -Width 1920 -Height 1080 -Force`. The asker confirmed it worked. Not every size is accepted (1440x1080 failed), and the maintainer believed 1920x1080 was the maximum but "haven't investigated it".
- [`Set-DisplayResolution`](https://learn.microsoft.com/en-us/powershell/module/servercore/set-displayresolution?view=windowsserver2025-ps) is in the ServerCore module, which is a Windows Server module. That answer was given for Server 2016 and 2019.

### Is Windows Terminal there, and how to install it

It is not listed in any of the three image READMEs. Neither is winget.

| Path | Status | Source |
|---|---|---|
| Already on `windows-2025` | Unknown. Microsoft says Windows Terminal "is available in Windows Server 2025" and that WinGet "is installed by default" there. Whether the hosted image keeps them is not stated | [What's new in Windows Server 2025](https://learn.microsoft.com/en-us/windows-server/get-started/whats-new-windows-server-2025) |
| winget | Not on `windows-2022`: maintainers declined to add it, citing no Windows Server support (2023). Not on `windows-11-arm`: closed as won't fix, because winget "doesn't bootstrap reliably in the non-interactive CI context". The workaround is the `Microsoft.WinGet.Client` module and `Repair-WinGetPackageManager` | [#8584](https://github.com/actions/runner-images/issues/8584), [#14083](https://github.com/actions/runner-images/issues/14083) |
| MSIX bundle | `Add-AppxPackage` on the `.msixbundle` from GitHub releases. It "might need network access to download dependency packages from the Store", and may need the VC++ v14 Desktop Framework Package | [Distribution types](https://learn.microsoft.com/en-us/windows/terminal/distributions), [terminal README](https://github.com/microsoft/terminal/blob/main/README.md) |
| Portable ZIP | Unzip and run `WindowsTerminal.exe`. Officially supported since 1.17. Needs Windows 10 build 19041 or later, which all three images meet. No Store, no installer, and the version is pinned by the file name | [Distribution types](https://learn.microsoft.com/en-us/windows/terminal/distributions) |
| Chocolatey | `choco install microsoft-windows-terminal`. Unofficial. Chocolatey is on the images | [terminal README](https://github.com/microsoft/terminal/blob/main/README.md) |

The latest release, [v1.25.3131.0](https://github.com/microsoft/terminal/releases/latest), ships `x64`, `arm64`, and `x86` ZIPs next to the MSIX bundle.

Where settings live changes with the install path, and the port's install guide depends on it ([Windows Terminal installation](https://learn.microsoft.com/en-us/windows/terminal/install), [Distribution types](https://learn.microsoft.com/en-us/windows/terminal/distributions)):

- Packaged: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- Unpackaged ZIP: `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json`
- Portable mode (a `.portable` file next to the exe): a `settings` folder next to `WindowsTerminal.exe`

The ZIP cannot be set as the default terminal and has no "Open in Terminal" menu. Neither matters for a screenshot.

### Do acrylic, Mica, and opacity render?

Not documented for hosted runners, and no issue report was found either way. What the primary sources say:

- **Acrylic in a virtual machine.** Windows Terminal's troubleshooting page: "Acrylic doesn't work if your GPU hardware doesn't support it. If you're running an app in a virtual machine (VM) or over remote desktop, acrylic likely doesn't work." ([Troubleshooting](https://learn.microsoft.com/en-us/windows/terminal/troubleshooting))
- **Acrylic needs focus.** "Acrylic is only enabled for the foreground window." `compatibility.enableUnfocusedAcrylic` lifts this, but "will only work if acrylic is enabled in the OS" ([Troubleshooting](https://learn.microsoft.com/en-us/windows/terminal/troubleshooting), [Rendering settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/rendering)).
- **Fallback to solid.** Acrylic and Mica both turn into a solid color when "Transparency effects" is off, when Battery Saver is on, and when "the app runs on low-end hardware". Neither page defines low-end hardware ([Acrylic](https://learn.microsoft.com/en-us/windows/apps/design/style/acrylic), [Mica](https://learn.microsoft.com/en-us/windows/apps/design/style/mica)).
- **Mica needs a recent build.** Mica falls back below build 22000, and Windows Terminal's `useMica` needs build 22621 or later ([Themes](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/themes)). Mica samples the desktop wallpaper, so the wallpaper has to be set before the app starts.
- **Unblurred opacity** (`"useAcrylic": false`) "only works on Windows 11" ([Appearance](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)). The page does not say whether Windows Server 2025 counts.
- **Server 2025 has the Windows 11 shell.** Its desktop "conforms to the style and appearance of Windows 11" and its Task Manager uses Mica ([What's new in Windows Server 2025](https://learn.microsoft.com/en-us/windows-server/get-started/whats-new-windows-server-2025)). That shows Mica exists on the OS, not that it renders on a hosted runner.
- **No GPU is listed** for standard runners, so rendering is most likely the software renderer. Windows Terminal has its own setting for it, `experimental.rendering.software` ([Rendering settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/rendering)).

What follows for each image:

| Image | Mica by build number | Acrylic and opacity |
|---|---|---|
| `windows-2022` (20348) | Impossible: below 22621 | Unknown. Server on a VM with no GPU |
| `windows-2025` (26100) | Passes the version check. Rendering unknown | Unknown. Same doubts |
| `windows-11-arm` (26200) | Passes the version check. Rendering unknown | Unknown. Client Windows, so the best chance, but the desktop is blocked by first-run windows |

The state of "Transparency effects" on a fresh runner profile is not documented. Microsoft Learn names the switch only as a Settings page (Personalization, then Colors). The registry value people use to flip it from a script is not on any Learn page read for this research.

### Capturing the screen or a window

The runner needs nothing extra for a full-screen capture.

- .NET's [`Graphics.CopyFromScreen`](https://learn.microsoft.com/en-us/dotnet/api/system.drawing.graphics.copyfromscreen) copies screen pixels into a bitmap and can be called from a PowerShell step. It copies what is on screen, so it captures the window together with whatever shows through it.
- Pillow's `ImageGrab.grab()` runs on the Windows images in Pillow's own CI (example, linked above).
- [guidepup/setup](https://github.com/guidepup/setup/blob/main/.github/workflows/test.yml) records the screen on `windows-2022`, `windows-2025`, and `windows-11-arm` and uploads the recordings (example).
- For one window, capture the full screen and crop to the window's rectangle. That keeps the wallpaper behind the glass in the shot, which is what the map asks for.

### Setting a wallpaper

[`SystemParametersInfo`](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) with `SPI_SETDESKWALLPAPER` sets the desktop wallpaper from a file path. It is a Win32 call, reachable from PowerShell through `Add-Type`. No report was found of it being used on a hosted runner.

## macOS

### Does `screencapture` work without a prompt?

Yes, by design of the image.

- The image build writes screen capture grants into the permissions database for `/bin/bash`, `/usr/bin/osascript`, Terminal, and the runner agent (source: [configure-tccdb-macos.sh](https://github.com/actions/runner-images/blob/main/images/macos/scripts/build/configure-tccdb-macos.sh)).
- On macOS 15 and later that was not enough: a "requesting to bypass the system private window picker" alert appeared on the first capture of every job ([#14474](https://github.com/actions/runner-images/issues/14474), closed 2026-08-03). The same script now pre-approves the agent in `ScreenCaptureApprovals.plist`, and an image test checks it (source: [System.Tests.ps1](https://github.com/actions/runner-images/blob/main/images/macos/scripts/tests/System.Tests.ps1)).
- Maintainers tell users to run `screencapture` and upload the file ([#8606](https://github.com/actions/runner-images/issues/8606), [#9345](https://github.com/actions/runner-images/issues/9345)).
- The image logs a user in to the GUI automatically (source: [configure-autologin.sh](https://github.com/actions/runner-images/blob/main/images/macos/scripts/build/configure-autologin.sh)).
- Pillow grabs the screen on `macos-latest` and `macos-26-intel` in CI ([test.yml](https://github.com/python-pillow/Pillow/blob/main/.github/workflows/test.yml)) (example).

### Does vibrancy render?

Not as the image ships. It may after two settings are undone.

- The image build runs `defaults write com.apple.universalaccess reduceTransparency -bool true` under the heading "Disable graphic effects in System" (source: [configure-system.sh](https://github.com/actions/runner-images/blob/main/images/macos/scripts/build/configure-system.sh)). Apple describes that setting as: "Replace the transparent effect used on some backgrounds in macOS with a solid background" ([Change Display settings for accessibility](https://support.apple.com/guide/mac-help/change-display-settings-for-accessibility-unac089/mac)). Apps are told not to use semitransparent backgrounds while it is on ([accessibilityDisplayShouldReduceTransparency](https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducetransparency)).
- The same script sets the wallpaper to solid black with `osascript -e 'tell application "Finder" to set desktop picture to POSIX file ...'`. That line is also the recipe for setting a wallpaper in a job.
- It also sets `reduceMotion` and unloads the notification center agent.
- GPU: GitHub lists "GPU hardware acceleration" only for the paid `xlarge` macOS runners ([larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners)). Nothing is stated for the standard arm64 runner.

So a job has to write `reduceTransparency` back to false and set a wallpaper before it launches the app. Whether blur then draws on a standard runner is not documented.

### Screen resolution

Not documented for the current arm64 images. The known answers are old and tied to the virtual machine software of the time: a VMware tool with a 2560x1600 maximum ([#393](https://github.com/actions/runner-images/issues/393), 2020) and an Anka tool ([#9345](https://github.com/actions/runner-images/issues/9345), 2024), where a maintainer wrote "we don't have much control over the screen resolution on virtual machines". A screenshot in #14474 is 1922x1075, which suggests about 1920x1080 on macOS 15 (issue report).

## Cost and limits

**Public repositories.** "Use of the standard GitHub-hosted runners is free and unlimited on public repositories." ([reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)) Hyaline is public, so Windows and macOS runs cost nothing. Larger runners are billed even in public repositories.

**Limits** ([Actions limits](https://docs.github.com/en/actions/reference/limits)):

| Limit | Value |
|---|---|
| Job run time | 6 hours |
| Concurrent jobs, Free plan | 20 total, 5 macOS |
| Concurrent jobs, Pro plan | 40 total, 5 macOS |
| Jobs in one matrix | 256 |

The reference page adds that macOS jobs "may take longer to start" during high demand.

**Private repositories.** GitHub's billing pages no longer describe minute multipliers. They give a price per minute and a monthly allowance in dollars ([Actions runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing), [billing for GitHub Actions](https://docs.github.com/en/billing/concepts/product-billing/github-actions)):

| Runner | Per minute | Against Linux 2-core |
|---|---|---|
| Linux 2-core x64 | $0.006 | 1x |
| Windows 2-core, x64 or arm64 | $0.010 | about 1.7x |
| macOS 3-core or 4-core | $0.062 | about 10x |

Included each month: $12 on Free, $18 on Pro and Team. Each job is rounded up to a whole minute. The ratio column is arithmetic on the listed prices, not a GitHub figure.

## Projects that capture GUI apps on hosted runners

All read from the linked workflow files. None of them is known to capture acrylic, Mica, or vibrancy.

| Project | What it does | Runners |
|---|---|---|
| [Pillow](https://github.com/python-pillow/Pillow/blob/main/Tests/test_imagegrab.py) | Grabs the screen in its test suite | `windows-latest`, `windows-2022`, `windows-11-arm`, `macos-latest`, `macos-26-intel` |
| [python-mss](https://github.com/BoboTiG/python-mss/blob/main/.github/workflows/tests.yml) | A screenshot library, tested on real screens | `windows-latest`, `macos-latest` |
| [guidepup/setup](https://github.com/guidepup/setup/blob/main/.github/workflows/test.yml) | Records the screen while it sets up screen readers | `windows-2022`, `windows-2025`, `windows-11-arm`, `macos-15`, `macos-26`, Intel variants |
| [NVDA](https://github.com/nvaccess/nvda/blob/master/.github/workflows/testAndPublish.yml) | System tests that drive real windows | Windows runners, named in [#14069](https://github.com/actions/runner-images/issues/14069) |
| Electron | UI tests with real input | `windows-latest` and `windows-11-arm`, per its comment in [#14069](https://github.com/actions/runner-images/issues/14069) |

## Not verified

No workflow was run, so these stay open. The first four are what a spike on a hosted Windows runner should settle.

1. Whether acrylic, Mica, or unblurred opacity draw in Windows Terminal on `windows-2025` or `windows-11-arm`, or fall back to solid. No source covers it. The only direct statement is Windows Terminal's "likely doesn't work" for virtual machines.
2. Whether "Transparency effects" is on in a fresh runner profile, and how to turn it on from a script. No Microsoft Learn page was found for the registry value.
3. Whether Windows Terminal and winget are present on the hosted `windows-2025` image. Microsoft says the OS ships both. The image README lists neither, and no issue settles it.
4. Whether the portable ZIP reads JSON fragments from `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments`, which the port's install guide uses. The fragments page gives that path but does not mention the unpackaged or portable builds.
5. The resolution facts for Windows: 1024x768 by default and 1920x1080 as the maximum come from a 2021 issue about Server 2016 and 2019. Not rechecked on `windows-2022` or `windows-2025`. `Set-DisplayResolution` is a Server module, so `windows-11-arm` probably needs another method.
6. Whether `SystemParametersInfo` changes the wallpaper on a hosted runner, and whether Mica picks it up.
7. Whether the `windows-11-arm` first-run windows can be closed reliably from a job. The issue is still open.
8. Whether a standard macOS runner draws blur once `reduceTransparency` is set back to false, and whether running apps need a restart to see the change.
9. Resolution, and how to change it, on current arm64 macOS images.
10. Which GPU or display adapter a standard Windows runner reports. GitHub's docs list none.

No host was blocked by the network policy. `docs.github.com`, `raw.githubusercontent.com`, `learn.microsoft.com`, `developer.apple.com`, and `support.apple.com` all answered.
