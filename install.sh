#!/bin/sh
set -eu

DOTFILES="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$DOTFILES"

command -v stow >/dev/null 2>&1 || {
    echo "GNU Stow não está instalado."
    echo "No Void: sudo xbps-install -S stow"
    exit 1
}

for package in \
    niri \
    noctalia \
    alacritty \
    nvim \
    gtk \
    fontconfig \
    pipewire \
    scripts \
    applications \
    shell
do
    [ -d "$package" ] || continue

    if find "$package" \( -type f -o -type l \) | grep -q .; then
        echo "==> Aplicando $package"
        stow --restow "$package"
    fi
done

if [ -s "$DOTFILES/dconf/gnome-interface.ini" ] &&
   command -v dconf >/dev/null 2>&1
then
    echo "==> Restaurando preferências GTK"
    dconf load /org/gnome/desktop/interface/ \
        < "$DOTFILES/dconf/gnome-interface.ini"
fi

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
fi

echo "==> Dotfiles aplicados."
