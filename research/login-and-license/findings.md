# Apps that need an account or license: findings

Throwaway research for the map ticket "Apps that need an account or license" (#44). Never merged.

## Claude Code (v2.1.328, `node:22-bookworm`, `--network none`)

- No login and no key: with `~/.claude.json` from `claude-code/claude.json` (`hasCompletedOnboarding`, `projects./work.hasTrustDialogAccepted`), the REPL draws. Footer: "Not logged in · run /login".
- `claude --resume <id>` run from `/work` renders the hand-written `claude-code/session.jsonl` (user message, assistant text, Edit tool use with `toolUseResult.structuredPatch`) with no API call. The diff is line-numbered and syntax-highlighted, and the custom theme (`settings.json` `"theme": "custom:hyaline-dark"`) colors it.
- Under tmux it drops to 256 colors. Launch with `env -u TMUX COLORTERM=truecolor`, or under `script`.
- A dummy `ANTHROPIC_API_KEY` adds a "Remote managed settings failed to load" warning. Only a localhost stub as `ANTHROPIC_BASE_URL` (`claude-code/stub.py`) removes it. The key also needs its last 20 chars in `customApiKeyResponses.approved`. Not used: the decision is no key.
- First launch shows a one-time "Auto mode is now the default" notice.
- Theme format: https://code.claude.com/docs/en/terminal-config#create-a-custom-theme. The config keys were found by testing.

## Typora (1.14.9, `ubuntu:24.04`, Xvfb)

- Install: apt repo `deb [signed-by=...] https://downloads.typora.io/linux ./` (https://support.typora.io/Typora-on-Linux/). `apt-get install -y typora` installs with no prompts. Add `libnss3 libgtk-3-0t64 libasound2t64 libgbm1 libxss1`. Run with `--no-sandbox`.
- A fresh install opens with no dialog or login. The trial shows only a closable "UNREGISTERED ×" badge in the status bar (`typora/shot2.png`).
- EULA (https://support.typora.io/License-Agreement/): the trial is "for the sole purpose of testing and evaluating the Software", for 15 days. 4.2 forbids using it "on any system where the Trial version was previously Used and expired". 4.5 counts each isolated environment as a device. Exceptions need "prior written approval".
- Free licenses go to contributors, themes included (https://support.typora.io/purchase). Activation is GUI or offline token only, 3 seats (https://support.typora.io/activation/).
