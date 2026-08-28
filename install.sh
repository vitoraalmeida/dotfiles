#!/bin/sh
set -eu

DOTFILES="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
HOME="${HOME:?}"
BACKUP="$HOME/dotfiles-pre-stow-$(date +%Y%m%d-%H%M%S)"

command -v stow >/dev/null 2>&1 || {
    echo "ERRO: GNU Stow não está instalado."
    echo "Instale com:"
    echo "  sudo xbps-install -S stow"
    exit 1
}

mkdir -p "$BACKUP"

backup_target() {
    TARGET="$1"

    if [ ! -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        return 0
    fi

    # Se já aponta para este repositório, não há nada para substituir.
    if [ -L "$TARGET" ]; then
        RESOLVED="$(readlink -f "$TARGET" 2>/dev/null || true)"

        case "$RESOLVED" in
            "$DOTFILES"/*)
                return 0
                ;;
        esac
    fi

    REL="${TARGET#$HOME/}"
    DEST="$BACKUP/$REL"

    mkdir -p "$(dirname "$DEST")"

    echo "==> Backup: $REL"
    mv "$TARGET" "$DEST"
}

backup_package_files() {
    PACKAGE="$1"

    [ -d "$DOTFILES/$PACKAGE" ] || return 0

    find "$DOTFILES/$PACKAGE" \( -type f -o -type l \) |
    while IFS= read -r SRC; do
        REL="${SRC#"$DOTFILES/$PACKAGE/"}"
        TARGET="$HOME/$REL"

        backup_target "$TARGET"
    done
}

echo "============================================================"
echo " Preparando aplicação dos dotfiles"
echo "============================================================"
echo

# Diretórios que são integralmente nossos.
backup_target "$HOME/.config/niri"
backup_target "$HOME/.config/noctalia"
backup_target "$HOME/.config/alacritty"
backup_target "$HOME/.config/nvim"
backup_target "$HOME/.config/fontconfig"
backup_target "$HOME/.config/pipewire"

# GTK é dividido em dois diretórios.
backup_target "$HOME/.config/gtk-3.0"
backup_target "$HOME/.config/gtk-4.0"

# O estado da GUI do Noctalia (layout da barra etc.) sobrescreve o config.toml.
# Movemos o estado atual para o backup; o snapshot versionado é restaurado abaixo.
backup_target "$HOME/.local/state/noctalia/settings.toml"

# .profile é um arquivo individual.
backup_target "$HOME/.profile"

# ~/.local/bin e ~/.local/share/applications podem conter arquivos
# de outros programas. Portanto NÃO movemos os diretórios inteiros.
# Fazemos backup apenas dos arquivos que também existem nos dotfiles.
backup_package_files scripts
backup_package_files applications

echo
echo "==> Aplicando GNU Stow"

cd "$DOTFILES"

for PACKAGE in \
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
    [ -d "$PACKAGE" ] || continue

    if find "$PACKAGE" \( -type f -o -type l \) | grep -q .; then
        echo "    $PACKAGE"
        stow \
            --dir="$DOTFILES" \
            --target="$HOME" \
            --restow \
            "$PACKAGE"
    fi
done

echo
echo "==> Restaurando estado da barra do Noctalia"

# O layout da barra (widgets, tema, escala) vive no estado da GUI:
# ~/.local/state/noctalia/settings.toml. O update.sh o captura em
# snapshots/noctalia-state/, então aqui o devolvemos ao lugar.
if [ -s "$DOTFILES/snapshots/noctalia-state/settings.toml" ]; then
    mkdir -p "$HOME/.local/state/noctalia"
    cp "$DOTFILES/snapshots/noctalia-state/settings.toml" \
       "$HOME/.local/state/noctalia/settings.toml"
    echo "    ~/.local/state/noctalia/settings.toml"
fi

echo
echo "==> Restaurando preferências GTK/dconf"

if [ -s "$DOTFILES/dconf/gnome-interface.ini" ] &&
   command -v dconf >/dev/null 2>&1
then
    dconf load /org/gnome/desktop/interface/ \
        < "$DOTFILES/dconf/gnome-interface.ini"
fi

echo
echo "==> Atualizando cache de fontes"

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
fi

echo
echo "==> Validando"

if command -v niri >/dev/null 2>&1; then
    niri validate
fi

if command -v fc-match >/dev/null 2>&1; then
    printf 'Monospace: '
    fc-match monospace | head -n1
fi

echo
echo "==> Conferindo destinos"

for TARGET in \
    "$HOME/.config/niri" \
    "$HOME/.config/noctalia" \
    "$HOME/.local/state/noctalia/settings.toml" \
    "$HOME/.config/alacritty" \
    "$HOME/.config/nvim" \
    "$HOME/.config/gtk-3.0" \
    "$HOME/.config/gtk-4.0" \
    "$HOME/.config/fontconfig"
do
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        printf '%s\n' "$TARGET"
        printf '    -> %s\n' "$(readlink -f "$TARGET" 2>/dev/null || echo 'arquivo/diretório normal')"
    fi
done

echo
echo "============================================================"
echo " DOTFILES APLICADOS"
echo "============================================================"
echo
echo "Backup dos arquivos substituídos:"
echo "  $BACKUP"
echo
echo "Não apague esse backup até confirmar que a sessão está"
echo "funcionando como esperado."
exit 0
