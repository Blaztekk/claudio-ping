# claudio-ping

**Hear when your agents need you !** 
*Even the one stuck on screen 2 since 9am...*

Run as many agents as you want. Game, browse, whatever.
A distinct sound when Claude is done, and another when it asks permission.

Zero deps. OS sounds. 1-line install. 2 hooks — the bare minimum.

Two distinct sounds:
- **Done responding** (`Stop`) → chime (30s debounce per session, prevents spam during long agentic runs)
- **Permission request** (`PermissionRequest`) → attention sound (Claude needs your approval)

Works with Claude Code CLI, VSCode extension, and desktop app.

> ℹ️ Only personally tested on Windows so far. The repo is small and straightforward enough that macOS and Linux should just work — but if you hit something off, PRs and issues are very welcome.

## Install

### Windows

```powershell
.\install.ps1
```

Uses built-in Windows Media sounds — no dependencies.

If PowerShell blocks the script with an execution policy error, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### macOS

```bash
chmod +x install.sh && ./install.sh
```

Uses built-in macOS system sounds (`afplay`).

### Linux

```bash
chmod +x install.sh && ./install.sh
```

Requires `paplay` (PulseAudio) or `aplay` (ALSA) + `freedesktop` sounds.

```bash
# Ubuntu/Debian
sudo apt install pulseaudio-utils sound-theme-freedesktop
```

## Manual install

Copy the relevant block from `snippets/<your-os>.json` into your `~/.claude/settings.json` under the `"hooks"` key.

## How it works

Claude Code supports [hooks](https://code.claude.com/docs/en/hooks) — shell commands triggered on lifecycle events. This repo wires two events to OS audio:

| Event | When |
|-------|------|
| `Stop` | Claude finishes generating a response |
| `PermissionRequest` | Claude asks to run a tool you haven't pre-approved |

The `Stop` hook uses a per-session debounce (30s) to avoid spam during long agentic runs where Claude makes many tool calls in sequence.

> Why not `Notification` too? Tested it — fires unpredictably (or not at all in many flows). `Stop` + `PermissionRequest` cover every case where you actually need to know. Less is more.

## Customize sounds

Edit `~/.claude/settings.json` and replace the sound file paths.

**Windows** — any `.wav` in `C:\Windows\Media\`  
**macOS** — any `.aiff` in `/System/Library/Sounds/`  
**Linux** — any `.oga` in `/usr/share/sounds/freedesktop/stereo/`

## Uninstall

There's no uninstall script — edit `~/.claude/settings.json` and remove the
`Stop` and `PermissionRequest` entries under `"hooks"`. The installer always
writes a timestamped backup next to `settings.json` (kept: last 5), so you
can also just restore one of those.

## Debounce tuning

The `Stop` hook won't fire more than once every 30 seconds per session. Adjust the `30` in the command to taste:
- `5` — near-instant, may spam during agentic runs
- `30` — safe for most MCP tool chains (default)
- `60` — very conservative

## License

MIT