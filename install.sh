#!/bin/sh
# Portable installer for the Parrot bspwm hacking environment.
# Run as a normal user with sudo privileges. Nothing is deleted without a backup.
#
# Usage: ./install.sh [options]
#   --dry-run          Print every action without executing it.
#   --no-packages      Skip apt installation and source builds.
#   --no-wallpapers    Skip copying the bundled wallpapers.
#   --skip-build       Reuse existing polybar/picom instead of building them.
#   --no-extra-tools   Skip the Python 2 source build.
#   --help             Show this help.

set -u

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DRY_RUN=0
NO_PACKAGES=0
NO_WALLPAPERS=0
SKIP_BUILD=0
EXTRA_TOOLS=1

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then printf '    (dry-run) %s\n' "$*"
    else "$@"; fi
}
sudo_run() {
    if [ "$DRY_RUN" -eq 1 ]; then printf '    (dry-run) sudo %s\n' "$*"
    else sudo "$@"; fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)       DRY_RUN=1 ;;
        --no-packages)   NO_PACKAGES=1 ;;
        --no-wallpapers) NO_WALLPAPERS=1 ;;
        --skip-build)    SKIP_BUILD=1 ;;
        --no-extra-tools) EXTRA_TOOLS=0 ;;
        -h|--help)
            cat <<'HELP'
Portable installer for the Parrot bspwm hacking environment.
Run as a normal user with sudo privileges. Nothing is deleted without a backup.

Usage: ./install.sh [options]
  --dry-run          Print every action without executing it.
  --no-packages      Skip apt installation and source builds.
  --no-wallpapers    Skip copying the bundled wallpapers.
  --skip-build       Reuse existing polybar/picom instead of building them.
  --no-extra-tools   Skip the Python 2 source build.
  --help             Show this help.
HELP
            exit 0 ;;
        *) die "Unknown option: $1 (use --help)" ;;
    esac
    shift
done

# ---------------------------------------------------------------- preflight
[ -d "$SRC/Config" ] || die "Config/ not found next to install.sh"
[ "$(id -u)" -ne 0 ] || die "Run this as your normal user, not root. The script uses sudo."
command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v apt-get >/dev/null 2>&1 || die "This installer targets Debian/Parrot/Ubuntu (apt)."

if [ "$DRY_RUN" -eq 0 ]; then
    sudo -v || die "sudo authentication failed."
fi

BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
log "Config backup directory: $BACKUP"

# ---------------------------------------------------------------- backup
backup_existing() {
    [ "$DRY_RUN" -eq 1 ] && { printf '    (dry-run) backup existing configs\n'; return 0; }
    mkdir -p "$BACKUP"
    for item in polybar rofi bin bspwm kitty sxhkd picom nvim; do
        if [ -e "$HOME/.config/$item" ]; then
            cp -a "$HOME/.config/$item" "$BACKUP/config-$item"
        fi
    done
    for file in .zshrc .p10k.zsh .dmrc .fzf.zsh; do
        [ -e "$HOME/$file" ] && cp -a "$HOME/$file" "$BACKUP/$file"
    done
    ok "Existing configuration backed up"
}

# ---------------------------------------------------------------- packages
REQUIRED='bspwm sxhkd polybar rofi picom feh scrot flameshot xclip bat lsd fzf zsh imagemagick git curl python3-pwntools zsh-syntax-highlighting zsh-autosuggestions'
OPTIONAL='scrub locate fastfetch acpi ranger seclists numlockx zsh-autocomplete'

install_packages() {
    [ "$NO_PACKAGES" -eq 1 ] && { log "Skipping package installation (--no-packages)"; return 0; }
    log "Updating package index"
    run sudo apt-get update -qq || warn "apt-get update failed; continuing with installed index"
    log "Installing required packages"
    if ! run sudo apt-get install -y --no-install-recommends $REQUIRED; then
        warn "apt reported an error; attempting repair pass"
        run sudo apt --fix-broken install -y || warn "Repair pass failed; check apt manually"
    fi
    log "Installing optional packages (failures are ignored)"
    for pkg in $OPTIONAL; do
        run sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1 || warn "Optional package unavailable: $pkg"
    done
    ok "Package phase finished"
}

# ---------------------------------------------------------------- builds
build_from_source() {
    [ "$NO_PACKAGES" -eq 1 ] && return 0
    [ "$SKIP_BUILD" -eq 1 ] && { log "Skipping source builds (--skip-build)"; return 0; }

    # polybar and picom from apt are often too old for the rounded-bar config.
    if ! command -v polybar >/dev/null 2>&1; then
        log "Building polybar from source"
        run mkdir -p "$HOME/github"
        if [ "$DRY_RUN" -eq 0 ]; then
            ( cd "$HOME/github" && \
              git clone --recursive --depth=1 https://github.com/polybar/polybar 2>/dev/null && \
              mkdir -p polybar/build && cd polybar/build && \
              cmake .. -DCMAKE_BUILD_TYPE=Release && \
              make -j"$(nproc)" && sudo make install ) \
              || warn "polybar build failed; install it manually"
        fi
    else
        log "polybar already present: $(command -v polybar)"
    fi

    if ! command -v picom >/dev/null 2>&1; then
        log "Building picom from source"
        run mkdir -p "$HOME/github"
        if [ "$DRY_RUN" -eq 0 ]; then
            ( cd "$HOME/github" && \
              git clone --depth=1 https://github.com/ibhagwan/picom.git 2>/dev/null && \
              cd picom && git submodule update --init --recursive && \
              meson --buildtype=release . build && ninja -C build && \
              sudo ninja -C build install ) \
              || warn "picom build failed; install it manually"
        fi
    else
        log "picom already present: $(command -v picom)"
    fi
}

# ---------------------------------------------------------------- files
install_files() {
    log "Installing configuration files"
    run cp -a "$SRC/Config/." "$HOME/.config/"
    sudo_run cp -a "$SRC/Config/." /root/.config/

    run cp "$SRC/zsh/.zshrc" "$HOME/.zshrc"
    run cp "$SRC/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    sudo_run cp "$SRC/zsh/.p10k.zsh-root" /root/.p10k.zsh
    sudo_run ln -sf "$HOME/.zshrc" /root/.zshrc

    sudo_run cp "$SRC/scripts/whichSystem.py" "$SRC/scripts/screenshot" /usr/local/bin/

    sudo_run mkdir -p /usr/local/share/fonts/parrot-bspwm
    sudo_run cp "$SRC"/fonts/*.ttf /usr/local/share/fonts/parrot-bspwm/
    if [ "$DRY_RUN" -eq 0 ]; then sudo fc-cache -f >/dev/null 2>&1; fi

    sudo_run mkdir -p /usr/share/xsessions
    sudo_run cp "$SRC/Config/xsessions/bspwm.desktop" /usr/share/xsessions/bspwm.desktop

    run chmod +x "$HOME/.config/bin/"*.sh
    run chmod +x "$HOME/.config/bspwm/bspwmrc" "$HOME/.config/bspwm/scripts/"*
    run chmod +x "$HOME/.config/polybar/"*.sh
    run chmod +x "$HOME/.config/rofi/bin/"*

    # Bundled binaries reproduce the exact terminal and editor of the source setup.
    if [ -d "$SRC/opt/kitty" ]; then
        log "Installing bundled kitty to /opt/kitty"
        sudo_run mkdir -p /opt/kitty
        sudo_run cp -a "$SRC/opt/kitty/." /opt/kitty/
        sudo_run ln -sf /opt/kitty/bin/kitty /usr/local/bin/kitty
    fi
    if [ -d "$SRC/opt/nvim" ]; then
        log "Installing bundled Neovim to /opt/nvim"
        sudo_run mkdir -p /opt/nvim
        sudo_run cp -a "$SRC/opt/nvim/." /opt/nvim/
    fi

    # zsh-sudo is distributed as a plain plugin file, not an apt package here.
    sudo_run mkdir -p /usr/share/zsh-sudo
    sudo_run wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -O /usr/share/zsh-sudo/sudo.plugin.zsh

    if command -v fzf >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 0 ]; then
            fzf --zsh > "$HOME/.fzf.zsh"
            sudo sh -c 'fzf --zsh > /root/.fzf.zsh'
        else
            printf '    (dry-run) generate fzf zsh bindings\n'
        fi
    fi

    if [ "$DRY_RUN" -eq 0 ]; then
        if [ -f "$HOME/.dmrc" ] && grep -q '^Session=' "$HOME/.dmrc"; then
            sed -i 's/^Session=.*/Session=bspwm/' "$HOME/.dmrc"
        elif [ -f "$HOME/.dmrc" ]; then
            printf 'Session=bspwm\n' >> "$HOME/.dmrc"
        else
            printf '[Session]\nSession=bspwm\n' > "$HOME/.dmrc"
        fi
    else
        printf '    (dry-run) set ~/.dmrc Session=bspwm\n'
    fi

    log "Setting zsh as default shell"
    sudo_run chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
    sudo_run usermod -s /usr/bin/zsh root 2>/dev/null || true
    ok "Configuration installed"
}

# ---------------------------------------------------------------- extras
install_extras() {
    if [ "$NO_WALLPAPERS" -eq 0 ]; then
        log "Installing bundled wallpapers"
        run mkdir -p "$HOME/Desktop/Wallpapers"
        run cp -a "$SRC/Wallpapers/." "$HOME/Desktop/Wallpapers/"
    else
        log "Skipping wallpapers (--no-wallpapers)"
    fi

    if ! [ -d "$HOME/.powerlevel10k" ]; then
        log "Installing powerlevel10k"
        if [ "$DRY_RUN" -eq 0 ]; then
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k" 2>/dev/null || warn "powerlevel10k clone failed"
        fi
    else
        log "powerlevel10k already present"
    fi
}

# ---------------------------------------------------------------- extra tool
install_extra_tools() {
    [ "$EXTRA_TOOLS" -eq 1 ] || { log "Skipping Python 2 build (--no-extra-tools)"; return 0; }

    if [ -f "$SRC/assets/Python-2.7.18.tgz" ]; then
        if command -v python2 >/dev/null 2>&1; then
            log "python2 already present: $(command -v python2)"
        else
            log "Building Python 2.7.18 (this takes 10-15 minutes)"
            if [ "$DRY_RUN" -eq 1 ]; then
                printf '    (dry-run) build Python 2.7.18 from assets\n'
            else
                tmp=$(mktemp -d)
                if tar -xzf "$SRC/assets/Python-2.7.18.tgz" -C "$tmp" &&
                   ( cd "$tmp/Python-2.7.18" && ./configure --enable-optimizations >/dev/null 2>&1 &&
                     make -j"$(nproc)" >/dev/null 2>&1 && sudo make install >/dev/null 2>&1 ); then
                    ok "Python 2.7.18 installed"
                else
                    warn "Python 2 build failed; install it manually"
                fi
                rm -rf "$tmp"
            fi
        fi
    fi
}

# ---------------------------------------------------------------- verify
verify() {
    log "Verification summary"
    missing=''
    for cmd in bspwm sxhkd polybar picom rofi feh flameshot bat lsd fzf zsh; do
        if [ "$DRY_RUN" -eq 1 ]; then printf '    (dry-run) check %s\n' "$cmd"
        elif command -v "$cmd" >/dev/null 2>&1; then printf '    ok   %s\n' "$cmd"
        else printf '    MISS %s\n' "$cmd"; missing="$missing $cmd"; fi
    done
    if [ -n "$missing" ]; then warn "Missing commands:$missing"; else ok "All key commands available"; fi
    ok "Backup kept at $BACKUP"
    log "Log out and back in to start the bspwm session. No reboot is forced."
}

backup_existing
install_packages
build_from_source
install_files
install_extras
install_extra_tools
verify
