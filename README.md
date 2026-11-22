# Parrot bspwm environment

A reproducible bspwm setup for Parrot / Debian / Ubuntu: three compact polybar
strips, wallpaper-driven colors, rounded window borders, transparent kitty,
fzf-powered zsh and per-language `bat` themes.

This is a full-fidelity snapshot: all 60 wallpapers, the exact kitty 0.43.1
bundle and the exact Neovim build are included, so a fresh install looks the
same as the machine this came from. The repository is about 322 MB and also
includes Python 2.7.18 and pwntools. VS Code is not bundled: install it from
the official Microsoft apt repository if you need it.

## Quick start

```sh
git clone <this-repo> parrot-bspwm
cd parrot-bspwm
chmod +x install.sh
./install.sh
```

Log out and back in, then select **bspwm** in the display manager. The installer
does not reboot or delete anything without copying it to
`~/.config-backup-<timestamp>` first.

### Options

| Flag | Effect |
| --- | --- |
| `--dry-run` | Print every action without executing it. Use this first. |
| `--no-packages` | Skip apt and source builds (config-only reinstall). |
| `--no-wallpapers` | Do not copy the bundled wallpapers. |
| `--skip-build` | Keep the existing polybar/picom instead of building them. |
| `--no-extra-tools` | Skip the Python 2 source build. |
| `--help` | Show the usage banner. |

## What it installs

- **Window manager**: bspwm + sxhkd, 2px borders colored from the active
  wallpaper, `top_padding 50` reserved for the top bar row.
- **Bars**: polybar with three strips — workspaces on the left, HTB IP and
  target on the right. Corners are rounded and the border follows the palette.
- **Compositor**: picom with the `xrender` backend and vsync off (the `glx`
  backend fails on virtual displays without a swap-control extension).
- **Terminal**: the bundled kitty 0.43.1 installed to `/opt/kitty` with
  `background_opacity 0.8`, neutral white foreground and softened ANSI colors.
- **Shell**: zsh with autosuggestions, syntax highlighting, sudo plugin, fzf
  bindings, powerlevel10k, and `lsd`/`bat` aliases.
- **Editor**: the bundled Neovim installed to `/opt/nvim`, plus the NvChad
  configuration under `Config/nvim`.

### Per-language syntax themes

`cat` is a small wrapper (`Config/bin/bat-lang.sh`) that picks a `bat` theme
from `-l`:

```sh
cat Archivo.java -l java   # Visual Studio Dark+
cat init.lua -l lua        # Nord
cat main.go -l go          # Monokai Extended Origin
cat query.sql -l sql       # Sublime Snazzy
```

Supported: java, lua, js/ts, rb, sh/bash/zsh, json/yaml/toml, c/cpp,
html/css, rust, go, sql/php. Anything else falls back to `BAT_THEME`
(`OneHalfDark` by default).

### Wallpaper-driven palette

`wallpaper-theme.sh` extracts an accent color from the current wallpaper and
writes `colors.ini` plus `palette.env`; `wallpaper-watch.sh` reapplies it when
the wallpaper changes. Green and cyan hues (70–200°) are skipped so the result
stays readable. All 60 wallpapers are bundled into `~/Desktop/Wallpapers`; press `Super+W`
for a random one. Edit `~/.config/bin/target` to set your own HTB IP and
machine name — the shipped value is only a placeholder.

## Requirements and notes

- Debian/Parrot/Ubuntu with `apt`, `sudo` and an X11 session.
- Iosevka Nerd Font (Regular + Bold) and Hack Nerd Font (Regular + Bold) are
  bundled, so the bars and status glyphs render the same on a fresh machine.
- Existing kitty windows keep their old palette/opacity until restarted.
- Source builds of polybar and picom are attempted only when the commands are
  missing. A failed build is reported, not hidden.
- Python 2.7.18 is built from `assets/Python-2.7.18.tgz` only when `python2` is
  missing (10-15 min). pwntools comes from the `python3-pwntools` apt package.
  Use `--no-extra-tools` to skip the Python 2 build in a config-only reinstall.

## Key bindings

| Binding | Action |
| --- | --- |
| `Super+Return` | kitty |
| `Super+d` | rofi launcher |
| `Super+w` | random wallpaper + palette refresh |
| `Super+Escape` | reload sxhkd |
