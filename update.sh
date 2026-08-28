#!/bin/sh
set -eu

DOTFILES="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
HOME="${HOME:?}"

sync_dir() {
    SRC="$1"
    DEST="$2"

    [ -d "$SRC" ] || return 0

    mkdir -p "$(dirname "$DEST")"
    TEMP_DEST="$(mktemp -d "$(dirname "$DEST")/.sync.XXXXXX")"
    cp -a "$SRC"/. "$TEMP_DEST"
    rm -rf "$DEST"
    mv "$TEMP_DEST" "$DEST"
}

sync_dir "$HOME/.config/niri" \
         "$DOTFILES/niri/.config/niri"

sync_dir "$HOME/.config/noctalia" \
         "$DOTFILES/noctalia/.config/noctalia"

sync_dir "$HOME/.config/alacritty" \
         "$DOTFILES/alacritty/.config/alacritty"

sync_dir "$HOME/.config/nvim" \
         "$DOTFILES/nvim/.config/nvim"

sync_dir "$HOME/.config/gtk-3.0" \
         "$DOTFILES/gtk/.config/gtk-3.0"

sync_dir "$HOME/.config/gtk-4.0" \
         "$DOTFILES/gtk/.config/gtk-4.0"

sync_dir "$HOME/.config/fontconfig" \
         "$DOTFILES/fontconfig/.config/fontconfig"

sync_dir "$HOME/.config/pipewire" \
         "$DOTFILES/pipewire/.config/pipewire"

sync_dir "$HOME/.local/bin" \
         "$DOTFILES/scripts/.local/bin"

sync_dir "$HOME/.local/share/applications" \
         "$DOTFILES/applications/.local/share/applications"

if [ -f "$HOME/.profile" ]; then
    cp -a "$HOME/.profile" "$DOTFILES/shell/.profile"
fi

if [ -f "$HOME/.local/state/noctalia/settings.toml" ]; then
    mkdir -p "$DOTFILES/snapshots/noctalia-state"
    cp -a \
        "$HOME/.local/state/noctalia/settings.toml" \
        "$DOTFILES/snapshots/noctalia-state/settings.toml"
fi

if command -v dconf >/dev/null 2>&1; then
    dconf dump /org/gnome/desktop/interface/ \
        > "$DOTFILES/dconf/gnome-interface.ini"
fi

PACKAGE_LIST="$(mktemp)"
if command -v xbps-query >/dev/null 2>&1 &&
   xbps-query -m > "$PACKAGE_LIST" 2>/dev/null
then
    sort "$PACKAGE_LIST" > "$DOTFILES/packages/xbps-manual.txt"
else
    echo "AVISO: não foi possível atualizar a lista de pacotes XBPS." >&2
fi
rm -f "$PACKAGE_LIST"

if command -v flatpak >/dev/null 2>&1; then
    PACKAGE_LIST="$(mktemp)"
    if flatpak list --app --columns=application > "$PACKAGE_LIST" 2>/dev/null; then
        sort "$PACKAGE_LIST" > "$DOTFILES/packages/flatpak-apps.txt"
    else
        echo "AVISO: não foi possível atualizar a lista de aplicativos Flatpak." >&2
    fi
    rm -f "$PACKAGE_LIST"
fi

echo "Snapshot atualizado."
echo
git -C "$DOTFILES" status --short
